import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssb_tour/core/format.dart';
import 'package:ssb_tour/core/theme.dart';
import 'package:ssb_tour/data/models.dart';
import 'package:ssb_tour/features/booking/booking_screen.dart';
import 'package:ssb_tour/features/package/package_detail_screen.dart';
import 'package:ssb_tour/features/trips/booking_detail_screen.dart';
import 'package:ssb_tour/main.dart';
import 'package:ssb_tour/state/providers.dart';
import 'package:ssb_tour/widgets/price_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('formatMoney', () {
    test('formats sen as ringgit', () {
      expect(formatMoney(150000), 'RM 1,500');
      expect(formatMoney(37550), 'RM 375.50');
      expect(formatMoney(30000, forceDecimals: true), 'RM 300.00');
    });
  });

  group('models', () {
    test('parses a booking from API JSON', () {
      final booking = _booking();
      expect(booking.isUpcoming, isTrue);
      expect(booking.canCancel, isTrue);
      expect(booking.canReview, isFalse); // reviews open once the trip starts
      expect(booking.returnDate.difference(booking.tourDate).inDays, 3);
      expect(booking.imageAsset, 'assets/kedah.jpg');
    });

    test('tour type adjustment labels', () {
      const escorted = TourTypeOption(key: 'escorted', label: 'Escorted', description: '', multiplier: 1.2);
      const freedom = TourTypeOption(key: 'freedom', label: 'Freedom', description: '', multiplier: 0.9);
      const base = TourTypeOption(key: 'independent', label: 'Independent', description: '', multiplier: 1);
      expect(escorted.adjustmentLabel, '+20%');
      expect(freedom.adjustmentLabel, '−10%');
      expect(base.adjustmentLabel, 'Base price');
    });
  });

  testWidgets('PriceSummary shows each line item and the total', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: PriceSummary(
            tourTypeLabel: 'Escorted Tour',
            price: PriceBreakdown(
              unitPriceCents: 10000,
              travellers: 2,
              baseCents: 20000,
              tourTypeCents: 4000,
              insuranceCents: 9000,
              discountCents: 1200,
              totalCents: 31800,
              promoCode: 'WELCOME5',
            ),
          ),
        ),
      ),
    );
    expect(find.text('RM 100 × 2 travellers'), findsOneWidget);
    expect(find.text('Escorted Tour'), findsOneWidget);
    expect(find.text('Travel insurance'), findsOneWidget);
    expect(find.text('Promo WELCOME5'), findsOneWidget);
    expect(find.text('RM 318.00'), findsOneWidget);
  });

  group('screens render with stubbed data', () {
    const options = CatalogOptions(
      regions: ['Malaysia'],
      categories: ['Beach'],
      insurancePerPaxCents: 4500,
      tourTypes: [
        TourTypeOption(key: 'independent', label: 'Independent Tour', description: 'Own pace', multiplier: 1),
        TourTypeOption(key: 'escorted', label: 'Escorted Tour', description: 'With a leader', multiplier: 1.2),
      ],
    );
    final detail = PackageDetail.fromJson({
      ..._packageJson,
      'description': 'A relaxed getaway.',
      'highlights': ['SkyCab'],
      'inclusions': ['Hotel'],
      'itinerary': [
        {'day': 1, 'title': 'Arrival', 'description': 'Check in.'},
        {'day': 2, 'title': 'Departure', 'description': 'Fly home.'},
      ],
    });

    Future<void> pump(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            catalogOptionsProvider.overrideWith((ref) async => options),
            packageDetailProvider.overrideWith((ref, slug) async => detail),
            packageReviewsProvider.overrideWith((ref, slug) async => const <Review>[]),
            bookingProvider.overrideWith((ref, reference) async => _booking()),
          ],
          child: MaterialApp(theme: AppTheme.light(), home: child),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('package details', (tester) async {
      await pump(tester, const PackageDetailScreen(slug: 'langkawi-island-escape'));
      expect(find.text('Langkawi Island Escape'), findsOneWidget);
      expect(find.text('Book this trip'), findsOneWidget);
    });

    testWidgets('booking wizard', (tester) async {
      await pump(tester, const BookingScreen(slug: 'langkawi-island-escape'));
      expect(find.text('Step 1 of 3 · Trip details'), findsOneWidget);
      expect(find.text('Escorted Tour'), findsOneWidget);
      expect(find.text('+20%'), findsOneWidget);
      // Continue without a date is blocked with a message.
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text('Please choose a departure date.'), findsOneWidget);
    });

    testWidgets('booking receipt', (tester) async {
      await pump(tester, const BookingDetailScreen(reference: 'SSB-ABC234', justConfirmed: true));
      expect(find.text("You're going!"), findsOneWidget);
      expect(find.text('SSB-ABC234'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Cancel booking'),
        300,
        scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
      );
      expect(find.text('Cancel booking'), findsOneWidget);
    });
  });

  testWidgets('first launch shows the welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)], child: const SsbTourApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Get started'), findsOneWidget);
    expect(find.textContaining('Discover your'), findsOneWidget);
  });
}

const _packageJson = <String, dynamic>{
  'id': 1,
  'slug': 'langkawi-island-escape',
  'title': 'Langkawi Island Escape',
  'location': 'Langkawi, Kedah',
  'country': 'Malaysia',
  'region': 'Malaysia',
  'category': 'Beach',
  'summary': 'Island hopping.',
  'image': 'kedah.jpg',
  'durationDays': 4,
  'pricePerPaxCents': 15000,
  'maxGroupSize': 15,
  'isFeatured': true,
  'rating': 4.5,
  'reviewCount': 2,
};

Booking _booking() => Booking.fromJson({
  'reference': 'SSB-ABC234',
  'status': 'confirmed',
  'tourDate': toApiDate(todayDate().add(const Duration(days: 120))),
  'travellers': 2,
  'tourType': 'independent',
  'insurance': true,
  'contact': {'name': 'Aina Rahman', 'email': 'aina@example.com', 'phone': '+60123456789'},
  'specialRequests': null,
  'price': {
    'unitPriceCents': 15000,
    'travellers': 2,
    'baseCents': 30000,
    'tourTypeCents': 0,
    'insuranceCents': 9000,
    'discountCents': 0,
    'totalCents': 39000,
    'promoCode': null,
  },
  'package': {
    'slug': 'langkawi-island-escape',
    'title': 'Langkawi Island Escape',
    'location': 'Langkawi',
    'image': 'kedah.jpg',
    'durationDays': 4,
  },
  'hasReview': false,
  'createdAt': '2026-01-01T00:00:00.000Z',
});
