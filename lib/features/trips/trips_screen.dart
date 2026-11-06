import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My trips')),
        body: EmptyState(
          icon: Icons.luggage_rounded,
          title: 'Your trips live here',
          message: 'Sign in to view your bookings, download receipts and leave reviews.',
          action: FilledButton(
            onPressed: () => context.push('/login?from=/trips'),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Sign in')),
          ),
        ),
      );
    }

    final bookings = ref.watch(myBookingsProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My trips'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past & cancelled'),
            ],
          ),
        ),
        body: bookings.when(
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(myBookingsProvider)),
          data: (items) {
            final upcoming = items.where((b) => b.isUpcoming).toList()
              ..sort((a, b) => a.tourDate.compareTo(b.tourDate));
            final past = items.where((b) => !b.isUpcoming).toList();
            Future<void> refresh() => ref.refresh(myBookingsProvider.future);
            return TabBarView(
              children: [
                _BookingList(
                  bookings: upcoming,
                  onRefresh: refresh,
                  empty: EmptyState(
                    icon: Icons.flight_takeoff_rounded,
                    title: 'No upcoming trips',
                    message: 'Your next adventure is just a few taps away.',
                    action: FilledButton(
                      onPressed: () => context.go('/'),
                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Explore trips')),
                    ),
                  ),
                ),
                _BookingList(
                  bookings: past,
                  onRefresh: refresh,
                  empty: const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'Nothing here yet',
                    message: 'Completed and cancelled trips will appear here.',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({required this.bookings, required this.onRefresh, required this.empty});
  final List<Booking> bookings;
  final Future<void> Function() onRefresh;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: bookings.isEmpty
          ? LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(height: c.maxHeight, child: empty),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: bookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, i) => BookingCard(booking: bookings[i]),
            ),
    );
  }
}

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysAway = booking.tourDate.difference(todayDate()).inDays;
    return Card(
      child: InkWell(
        onTap: () => context.push('/booking/${booking.reference}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                PackageImage(booking.imageAsset, height: 130, width: double.infinity, fit: BoxFit.cover),
                Positioned(top: 12, right: 12, child: StatusChip(status: booking.status)),
                if (booking.isUpcoming)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(99)),
                      child: Text(
                        daysAway == 0 ? 'Departs today' : 'In $daysAway ${daysAway == 1 ? 'day' : 'days'}',
                        style: theme.textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.packageTitle, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          '${formatShortDate(booking.tourDate)} – ${formatShortDate(booking.returnDate)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          '${booking.reference} · ${booking.travellers} pax',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatMoney(booking.price.totalCents),
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (status) {
      BookingStatus.confirmed => (const Color(0xFFDDF6E8), const Color(0xFF0B6B3A), Icons.check_circle_rounded),
      BookingStatus.completed => (const Color(0xFFE3ECFF), const Color(0xFF1F4BB8), Icons.flag_rounded),
      BookingStatus.cancelled => (const Color(0xFFFDE2E1), const Color(0xFFB3261E), Icons.cancel_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
