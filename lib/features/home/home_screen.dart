import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/common.dart';
import '../../widgets/package_card.dart';

const _sortLabels = {
  'popular': 'Most popular',
  'rating': 'Top rated',
  'price_asc': 'Price: low to high',
  'price_desc': 'Price: high to low',
  'duration': 'Shortest first',
};

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search.text = ref.read(packageQueryProvider).search;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {}); // toggles the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(packageQueryProvider.notifier).setSearch(value);
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(packagesProvider);
    ref.invalidate(featuredPackagesProvider);
    await ref.read(packagesProvider.future).catchError((_) => <TourPackage>[]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider);
    final query = ref.watch(packageQueryProvider);
    final packages = ref.watch(packagesProvider);
    final categories = ref.watch(catalogOptionsProvider).value?.categories ?? const [];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user == null ? 'Hello, traveller 👋' : 'Hello, ${user.firstName} 👋',
                                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 4),
                                Text('Where to next?', style: theme.textTheme.headlineMedium),
                              ],
                            ),
                          ),
                          const BrandLogo(size: 52),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _search,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search destinations, countries…',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _search.clear();
                                    _onSearchChanged('');
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 64,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                    children: [
                      for (final c in [null, ...categories])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c ?? 'All'),
                            selected: query.category == c,
                            onSelected: (_) => ref.read(packageQueryProvider.notifier).setCategory(c),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (!query.hasFilters) const SliverToBoxAdapter(child: _FeaturedCarousel()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    query.hasFilters ? 'Results' : 'All destinations',
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Sort',
                      initialValue: query.sort,
                      onSelected: ref.read(packageQueryProvider.notifier).setSort,
                      itemBuilder: (_) => [
                        for (final e in _sortLabels.entries) PopupMenuItem(value: e.key, child: Text(e.value)),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Text(_sortLabels[query.sort]!, style: theme.textTheme.labelLarge),
                            const Icon(Icons.expand_more_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ...packages.when(
                skipLoadingOnRefresh: true,
                data: (items) => [
                  if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.travel_explore_rounded,
                        title: 'No trips found',
                        message: 'Try a different search or category.',
                        action: TextButton(
                          onPressed: () {
                            _search.clear();
                            ref.read(packageQueryProvider.notifier).reset();
                          },
                          child: const Text('Clear filters'),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => PackageListTile(package: items[i]),
                      ),
                    ),
                ],
                loading: () => [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: 4,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, _) => const SkeletonBox(height: 124, radius: 16),
                    ),
                  ),
                ],
                error: (e, _) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(error: e, onRetry: () => ref.invalidate(packagesProvider)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedCarousel extends ConsumerWidget {
  const _FeaturedCarousel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredPackagesProvider);
    return featured.maybeWhen(
      orElse: () =>
          const Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, 16), child: SkeletonBox(height: 280, radius: 16)),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(padding: EdgeInsets.fromLTRB(20, 8, 20, 12), child: SectionHeader('Featured trips')),
                SizedBox(
                  height: 280,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - 56).clamp(240.0, 420.0);
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (_, i) => SizedBox(
                          width: cardWidth,
                          child: FeaturedPackageCard(package: items[i]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}
