import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class PackageDetailScreen extends ConsumerWidget {
  const PackageDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(packageDetailProvider(slug));
    return detail.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: e, onRetry: () => ref.invalidate(packageDetailProvider(slug))),
      ),
      data: (d) => _PackageDetailView(detail: d),
    );
  }
}

class _PackageDetailView extends ConsumerWidget {
  const _PackageDetailView({required this.detail});
  final PackageDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pkg = detail.summary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.surface,
            leading: const Padding(padding: EdgeInsets.all(8), child: _CircleBackButton()),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(
                tag: 'package-image-${pkg.slug}',
                child: PackageImage(pkg.imageAsset, fit: BoxFit.cover),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList.list(
              children: [
                Text(
                  '${pkg.country.toUpperCase()} · ${pkg.region.toUpperCase()}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(pkg.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.place_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pkg.location,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    RatingBadge(rating: pkg.rating, count: pkg.reviewCount),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoPill(icon: Icons.schedule_rounded, label: pkg.durationLabel),
                    InfoPill(icon: Icons.groups_2_outlined, label: 'Up to ${pkg.maxGroupSize}'),
                    InfoPill(icon: Icons.landscape_outlined, label: pkg.category),
                  ],
                ),
                const SizedBox(height: 28),
                const SectionHeader('About this trip'),
                const SizedBox(height: 8),
                Text(detail.description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
                const SizedBox(height: 28),
                const SectionHeader('Highlights'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final h in detail.highlights)
                      Chip(
                        avatar: Icon(Icons.check_circle_outline_rounded, size: 16, color: theme.colorScheme.tertiary),
                        label: Text(h),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                const SectionHeader('Itinerary'),
                const SizedBox(height: 12),
                for (final (i, day) in detail.itinerary.indexed)
                  _ItineraryStep(day: day, isLast: i == detail.itinerary.length - 1),
                const SizedBox(height: 20),
                const SectionHeader("What's included"),
                const SizedBox(height: 10),
                for (final item in detail.inclusions)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.success),
                        const SizedBox(width: 10),
                        Expanded(child: Text(item, style: theme.textTheme.bodyLarge)),
                      ],
                    ),
                  ),
                const SizedBox(height: 28),
                _ReviewsSection(slug: pkg.slug),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BookingBar(package: pkg),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
        onPressed: () => context.canPop() ? context.pop() : context.go('/'),
      ),
    );
  }
}

class _ItineraryStep extends StatelessWidget {
  const _ItineraryStep({required this.day, required this.isLast});
  final ItineraryDay day;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
                  child: Text(
                    '${day.day}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: scheme.outlineVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 5, bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Day ${day.day} · ${day.title}', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    day.description,
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(packageReviewsProvider(slug));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Traveller reviews'),
        const SizedBox(height: 12),
        reviews.when(
          loading: () => const SkeletonBox(height: 90),
          error: (e, _) =>
              ErrorView(error: e, compact: true, onRetry: () => ref.invalidate(packageReviewsProvider(slug))),
          data: (items) => items.isEmpty
              ? Text(
                  'No reviews yet — be the first to travel and share your experience!',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : Column(
                  children: [
                    for (final r in items.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReviewCard(review: r),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Text(review.author[0], style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.author, style: theme.textTheme.titleSmall),
                      Text(formatShortDate(review.createdAt.toLocal()), style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                RatingBarIndicator(
                  rating: review.rating.toDouble(),
                  itemSize: 16,
                  itemBuilder: (_, _) => const Icon(Icons.star_rounded, color: AppColors.star),
                ),
              ],
            ),
            if (review.comment != null) ...[
              const SizedBox(height: 10),
              Text(review.comment!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.package});
  final TourPackage package;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerLowest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('From', style: theme.textTheme.bodySmall),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formatMoney(package.pricePerPaxCents),
                          style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
                        ),
                        TextSpan(text: ' /pax', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: FilledButton(
                  onPressed: () => context.push('/packages/${package.slug}/book'),
                  child: const Text('Book this trip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
