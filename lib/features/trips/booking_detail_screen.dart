import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/price_summary.dart';
import 'trips_screen.dart';

/// Booking receipt. Shown after checkout (with [justConfirmed]) and from My trips.
class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.reference, this.justConfirmed = false});

  final String reference;
  final bool justConfirmed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingProvider(reference));
    final options = ref.watch(catalogOptionsProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(justConfirmed ? 'Booking confirmed' : 'Booking details'),
        leading: justConfirmed
            ? IconButton(icon: const Icon(Icons.close_rounded), tooltip: 'Done', onPressed: () => context.go('/trips'))
            : null,
      ),
      body: booking.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(bookingProvider(reference))),
        data: (b) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            if (justConfirmed) const _SuccessBanner(),
            _TicketCard(booking: b),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trip details', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _Row('Departure', formatDate(b.tourDate)),
                    _Row('Return', formatDate(b.returnDate)),
                    _Row('Travellers', '${b.travellers}'),
                    _Row('Tour style', options?.tourTypeLabel(b.tourType) ?? b.tourType),
                    _Row('Insurance', b.insurance ? 'Included' : 'Not included'),
                    if (b.specialRequests != null) _Row('Requests', b.specialRequests!),
                    const Divider(height: 24),
                    Text('Lead traveller', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _Row('Name', b.contact.name),
                    _Row('Email', b.contact.email),
                    _Row('Phone', b.contact.phone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment summary', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    PriceSummary(price: b.price, tourTypeLabel: options?.tourTypeLabel(b.tourType) ?? 'Tour style'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (b.canReview)
              FilledButton.icon(
                onPressed: () => _showReviewSheet(context, b),
                icon: const Icon(Icons.star_rounded),
                label: const Text('Rate this trip'),
              ),
            if (b.hasReview)
              const ListTile(
                leading: Icon(Icons.favorite_rounded, color: AppColors.accent),
                title: Text('Thanks for reviewing this trip!'),
              ),
            if (b.canReview) const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push('/packages/${b.packageSlug}'),
              icon: const Icon(Icons.map_outlined),
              label: const Text('View itinerary'),
            ),
            if (b.status == BookingStatus.confirmed) ...[
              const SizedBox(height: 10),
              if (b.canCancel) ...[
                OutlinedButton.icon(
                  onPressed: () => _confirmCancel(context, ref, b),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                  ),
                  icon: const Icon(Icons.event_busy_outlined),
                  label: const Text('Cancel booking'),
                ),
                const SizedBox(height: 6),
                Text(
                  'You can cancel until ${formatShortDate(b.freeCancellationUntil)} (3 months before departure)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else
                _CancellationClosedNote(),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref, Booking b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(
          'Your trip to ${b.packageTitle} on ${formatShortDate(b.tourDate)} will be cancelled. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep booking')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(bookingRepositoryProvider).cancel(b.reference);
      refreshBookingData(ref, reference: b.reference);
      if (context.mounted) showMessage(context, 'Booking ${b.reference} cancelled.');
    } on ApiException catch (e) {
      if (context.mounted) showMessage(context, e.message, error: true);
    }
  }

  void _showReviewSheet(BuildContext context, Booking booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReviewSheet(booking: booking),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 8),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
            ),
          ),
          const SizedBox(height: 16),
          Text("You're going!", style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Your booking is confirmed. A copy of this receipt is always available under My trips.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.packageTitle,
                    style: theme.textTheme.titleLarge?.copyWith(color: scheme.onPrimary),
                  ),
                ),
                StatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(booking.packageLocation, style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.8))),
            const SizedBox(height: 18),
            Text(
              'BOOKING REFERENCE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onPrimary.withValues(alpha: 0.7),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Flexible(
                  child: SelectableText(
                    booking.reference,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy reference',
                  icon: Icon(Icons.copy_rounded, size: 18, color: scheme.onPrimary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: booking.reference));
                    showMessage(context, 'Reference copied');
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Booked on ${formatShortDate(booking.createdAt.toLocal())}',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.75)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.booking});
  final Booking booking;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  int _rating = 0;
  final _comment = TextEditingController();
  bool _submitting = false;

  static const _labels = ['', 'Poor', 'Fair', 'Good', 'Great', 'Amazing!'];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref
          .read(bookingRepositoryProvider)
          .review(widget.booking.reference, rating: _rating, comment: _comment.text.trim());
      refreshBookingData(ref, reference: widget.booking.reference, packageSlug: widget.booking.packageSlug);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Thank you for choosing SSB Tour! Your review has been posted.')),
      );
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How was ${widget.booking.packageTitle}?',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          RatingBar.builder(
            minRating: 1,
            itemSize: 44,
            glow: false,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4),
            itemBuilder: (_, _) => const Icon(Icons.star_rounded, color: AppColors.star),
            onRatingUpdate: (r) => setState(() => _rating = r.round()),
          ),
          const SizedBox(height: 8),
          Text(_labels[_rating], style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 16),
          TextField(
            controller: _comment,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(hintText: 'Tell other travellers about your experience (optional)'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _rating == 0 || _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Submit review'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancellationClosedNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This trip departs in less than 3 months, so it can no longer be cancelled and the payment '
              'is non-refundable. For any changes, please contact SSB Tour support.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
