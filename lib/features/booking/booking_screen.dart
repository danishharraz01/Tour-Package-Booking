import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/price_summary.dart';

/// Loads the package and catalogue options, then shows the booking wizard.
class BookingScreen extends ConsumerWidget {
  const BookingScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(packageDetailProvider(slug));
    final options = ref.watch(catalogOptionsProvider);

    if (detail.hasError || options.hasError) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          error: (detail.error ?? options.error)!,
          onRetry: () {
            ref.invalidate(packageDetailProvider(slug));
            ref.invalidate(catalogOptionsProvider);
          },
        ),
      );
    }
    final (d, o) = (detail.value, options.value);
    if (d == null || o == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return _BookingWizard(package: d.summary, options: o);
  }
}

class _BookingWizard extends ConsumerStatefulWidget {
  const _BookingWizard({required this.package, required this.options});
  final TourPackage package;
  final CatalogOptions options;

  @override
  ConsumerState<_BookingWizard> createState() => _BookingWizardState();
}

class _BookingWizardState extends ConsumerState<_BookingWizard> {
  static const _steps = ['Trip details', 'Traveller info', 'Review & confirm'];
  static const _minDaysAhead = 3;

  int _step = 0;

  // Step 1
  DateTime? _tourDate;
  int _travellers = 2;
  late String _tourType = widget.options.tourTypes.first.key;
  bool _insurance = true;

  // Step 2
  final _contactForm = GlobalKey<FormState>();
  late final _name = TextEditingController();
  late final _email = TextEditingController();
  late final _phone = TextEditingController();
  final _requests = TextEditingController();

  // Step 3
  final _promoInput = TextEditingController();
  String? _appliedPromo;
  String? _promoError;
  bool _applyingPromo = false;
  bool _submitting = false;
  bool _acceptedPolicy = false;

  // Live, server-computed quote.
  PriceBreakdown? _quote;
  String? _quoteError;
  bool _quoting = false;
  Timer? _quoteDebounce;
  int _quoteSeq = 0;

  @override
  void initState() {
    super.initState();
    _travellers = _travellers.clamp(1, widget.package.maxGroupSize);
    final user = ref.read(authControllerProvider);
    if (user != null) {
      _name.text = user.name;
      _email.text = user.email;
      _phone.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _quoteDebounce?.cancel();
    for (final c in [_name, _email, _phone, _requests, _promoInput]) {
      c.dispose();
    }
    super.dispose();
  }

  BookingRequest _request({String? promo}) => BookingRequest(
    packageSlug: widget.package.slug,
    tourDate: toApiDate(_tourDate!),
    travellers: _travellers,
    tourType: _tourType,
    insurance: _insurance,
    promoCode: promo ?? _appliedPromo,
  );

  /// Re-prices the trip whenever a selection changes (debounced).
  void _scheduleQuote() {
    if (_tourDate == null) return;
    _quoteDebounce?.cancel();
    setState(() => _quoting = true);
    _quoteDebounce = Timer(const Duration(milliseconds: 250), _fetchQuote);
  }

  Future<void> _fetchQuote() async {
    final seq = ++_quoteSeq;
    try {
      final quote = await ref.read(bookingRepositoryProvider).quote(_request());
      if (!mounted || seq != _quoteSeq) return;
      setState(() {
        _quote = quote;
        _quoteError = null;
        _quoting = false;
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _quoteSeq) return;
      // A previously valid promo can become invalid (e.g. fewer travellers).
      if (_appliedPromo != null && (e.code?.startsWith('promo_') ?? false)) {
        setState(() {
          _promoError = e.message;
          _appliedPromo = null;
        });
        return _fetchQuote();
      }
      setState(() {
        _quoteError = e.message;
        _quoting = false;
      });
    }
  }

  Future<void> _applyPromo() async {
    final code = _promoInput.text.trim().toUpperCase();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _applyingPromo = true;
      _promoError = null;
    });
    try {
      final quote = await ref.read(bookingRepositoryProvider).quote(_request(promo: code));
      setState(() {
        _appliedPromo = code;
        _quote = quote;
      });
    } on ApiException catch (e) {
      setState(() => _promoError = e.message);
    } finally {
      if (mounted) setState(() => _applyingPromo = false);
    }
  }

  void _removePromo() {
    setState(() {
      _appliedPromo = null;
      _promoError = null;
      _promoInput.clear();
    });
    _scheduleQuote();
  }

  Future<void> _pickDate() async {
    final today = todayDate();
    final first = today.add(const Duration(days: _minDaysAhead));
    final picked = await showDatePicker(
      context: context,
      initialDate: _tourDate ?? first,
      firstDate: first,
      lastDate: today.add(const Duration(days: 720)),
      helpText: 'Select departure date',
    );
    if (picked != null) {
      setState(() => _tourDate = picked);
      _scheduleQuote();
    }
  }

  void _next() {
    if (_step == 0) {
      if (_tourDate == null) return showMessage(context, 'Please choose a departure date.', error: true);
      if (_quoteError != null) return showMessage(context, _quoteError!, error: true);
    }
    if (_step == 1 && !_contactForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final booking = await ref
          .read(bookingRepositoryProvider)
          .create(
            _request(),
            contact: BookingContact(name: _name.text.trim(), email: _email.text.trim(), phone: _phone.text.trim()),
            specialRequests: _requests.text.trim(),
          );
      if (!mounted) return;
      refreshBookingData(ref, packageSlug: widget.package.slug);
      context.go('/booking/${booking.reference}?confirmed=1');
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: _back, tooltip: 'Back'),
          title: Text(widget.package.title),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${_step + 1} of ${_steps.length} · ${_steps[_step]}',
                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < _steps.length; i++)
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 5,
                            margin: EdgeInsets.only(right: i == _steps.length - 1 ? 0 : 6),
                            decoration: BoxDecoration(
                              color: i <= _step ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: switch (_step) {
              0 => _buildTripStep(theme),
              1 => _buildContactStep(),
              _ => _buildReviewStep(theme),
            },
          ),
        ),
        bottomNavigationBar: _buildBottomBar(theme),
      ),
    );
  }

  Widget _buildTripStep(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('When are you going?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary),
            title: Text(_tourDate == null ? 'Choose departure date' : formatDate(_tourDate!)),
            subtitle: Text(
              _tourDate == null
                  ? 'Book at least $_minDaysAhead days in advance'
                  : 'Return ${formatDate(_tourDate!.add(Duration(days: widget.package.durationDays - 1)))}',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _pickDate,
          ),
        ),
        const SizedBox(height: 24),
        Text('Who is travelling?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.groups_2_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Travellers', style: theme.textTheme.bodyLarge),
                      Text('Max ${widget.package.maxGroupSize} per booking', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Remove traveller',
                  onPressed: _travellers > 1
                      ? () {
                          setState(() => _travellers--);
                          _scheduleQuote();
                        }
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                SizedBox(
                  width: 40,
                  child: Text('$_travellers', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
                ),
                IconButton.filledTonal(
                  tooltip: 'Add traveller',
                  onPressed: _travellers < widget.package.maxGroupSize
                      ? () {
                          setState(() => _travellers++);
                          _scheduleQuote();
                        }
                      : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Tour style', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        RadioGroup<String>(
          groupValue: _tourType,
          onChanged: (v) {
            if (v == null) return;
            setState(() => _tourType = v);
            _scheduleQuote();
          },
          child: Column(
            children: [
              for (final t in widget.options.tourTypes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SelectableCard(
                    selected: _tourType == t.key,
                    onTap: () {
                      setState(() => _tourType = t.key);
                      _scheduleQuote();
                    },
                    child: Row(
                      children: [
                        Radio<String>(value: t.key),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.label, style: theme.textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Text(t.description, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(t.adjustmentLabel, style: theme.textTheme.labelLarge),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            secondary: Icon(Icons.health_and_safety_outlined, color: theme.colorScheme.primary),
            title: const Text('Travel insurance'),
            subtitle: Text(
              '${formatMoney(widget.options.insurancePerPaxCents)} per traveller · medical & cancellation cover',
            ),
            value: _insurance,
            onChanged: (v) {
              setState(() => _insurance = v);
              _scheduleQuote();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactStep() {
    return Form(
      key: _contactForm,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Lead traveller', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            "We'll send your confirmation and travel documents here.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
            validator: (v) => (v == null || v.trim().length < 2) ? 'Please enter your full name' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
            validator: (v) =>
                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '') ? null : 'Enter a valid email address',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: const InputDecoration(
              labelText: 'Phone number',
              hintText: '+60 12-345 6789',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (v) =>
                RegExp(r'^\+?[0-9\s-]{8,16}$').hasMatch(v?.trim() ?? '') ? null : 'Enter a valid phone number',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _requests,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Special requests (optional)',
              hintText: 'Dietary needs, accessibility, celebrations…',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(ThemeData theme) {
    final quote = _quote;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Row(
            children: [
              PackageImage(widget.package.imageAsset, width: 96, height: 96, fit: BoxFit.cover),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.package.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(formatDate(_tourDate!), style: theme.textTheme.bodyMedium),
                    Text(
                      '$_travellers ${_travellers == 1 ? 'traveller' : 'travellers'} · '
                      '${widget.options.tourTypeLabel(_tourType)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contact', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(_name.text),
                Text(_email.text, style: theme.textTheme.bodySmall),
                Text(_phone.text, style: theme.textTheme.bodySmall),
                if (_requests.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '“${_requests.text.trim()}”',
                    style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Promo code', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        if (_appliedPromo != null)
          Card(
            color: theme.colorScheme.primaryContainer,
            child: ListTile(
              leading: Icon(Icons.local_offer_rounded, color: theme.colorScheme.onPrimaryContainer),
              title: Text('$_appliedPromo applied'),
              subtitle: quote == null
                  ? null
                  : Text('You save ${formatMoney(quote.discountCents, forceDecimals: true)}'),
              trailing: TextButton(onPressed: _removePromo, child: const Text('Remove')),
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _promoInput,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _applyPromo(),
                  decoration: InputDecoration(
                    hintText: 'e.g. WELCOME5',
                    prefixIcon: const Icon(Icons.local_offer_outlined),
                    errorText: _promoError,
                    errorMaxLines: 2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: _applyingPromo ? null : _applyPromo,
                  child: _applyingPromo
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Apply'),
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: quote == null
                ? const Center(child: CircularProgressIndicator())
                : PriceSummary(price: quote, tourTypeLabel: widget.options.tourTypeLabel(_tourType)),
          ),
        ),
        const SizedBox(height: 16),
        _CancellationPolicyCard(
          tourDate: _tourDate,
          accepted: _acceptedPolicy,
          onChanged: (v) => setState(() => _acceptedPolicy = v),
        ),
        const SizedBox(height: 10),
        Text(
          'This is a demo — no payment will be taken.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final isLast = _step == _steps.length - 1;
    final total = _quote?.totalCents;
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerLowest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total price', style: theme.textTheme.bodySmall),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _quoting && total == null
                          ? const SizedBox(
                              height: 28,
                              child: Align(alignment: Alignment.centerLeft, child: SkeletonBox(width: 90, height: 20)),
                            )
                          : Text(
                              _quoteError != null && _step == 0
                                  ? '—'
                                  : total == null
                                  ? 'Pick a date'
                                  : formatMoney(total, forceDecimals: true),
                              key: ValueKey(total),
                              style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
                            ),
                    ),
                    if (_quoteError != null && _step == 0)
                      Text(_quoteError!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 180,
                child: FilledButton(
                  onPressed: _submitting || (isLast && (_quote == null || _quoting || !_acceptedPolicy))
                      ? null
                      : (isLast ? _submit : _next),
                  child: _submitting
                      ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : Text(isLast ? 'Confirm booking' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({required this.selected, required this.onTap, required this.child});
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer.withValues(alpha: 0.45) : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 1.6 : 1),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.fromLTRB(4, 12, 16, 12), child: child),
        ),
      ),
    );
  }
}

/// Cancellation disclaimer the customer must accept before confirming.
class _CancellationPolicyCard extends StatelessWidget {
  const _CancellationPolicyCard({required this.tourDate, required this.accepted, required this.onChanged});

  final DateTime? tourDate;
  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = tourDate;
    final deadline = date == null ? null : cancellationDeadline(date);
    final cancellable = deadline != null && !deadline.isBefore(todayDate());

    Widget point(String text, {bool strong = false}) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall?.copyWith(fontWeight: strong ? FontWeight.w700 : null)),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.policy_outlined, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Cancellation policy', style: theme.textTheme.titleSmall),
            ],
          ),
          if (deadline != null)
            point(
              cancellable
                  ? 'You can cancel this booking until ${formatShortDate(deadline)} (3 months before departure).'
                  : 'Your departure is less than 3 months away, so this booking cannot be cancelled once confirmed.',
              strong: true,
            ),
          point('Cancellations are accepted up to 3 months (90 days) before the departure date.'),
          point('Within 3 months of departure, bookings cannot be cancelled and payments are non-refundable.'),
          point('Itineraries may change due to weather, safety or local conditions.'),
          const SizedBox(height: 4),
          CheckboxListTile(
            value: accepted,
            onChanged: (v) => onChanged(v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            visualDensity: VisualDensity.compact,
            title: Text('I have read and agree to the cancellation policy', style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
