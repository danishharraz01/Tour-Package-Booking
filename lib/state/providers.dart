import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../data/models.dart';
import '../data/repositories.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

/// Overridden in `main()` once SharedPreferences has loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

const _tokenKey = 'auth.token';
const _userKey = 'auth.user';
const _welcomeSeenKey = 'onboarding.seen';

final apiClientProvider = Provider<ApiClient>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final client = ApiClient(baseUrl: AppConfig.apiBaseUrl, readToken: () => prefs.getString(_tokenKey));
  client.onUnauthorized = () => ref.read(authControllerProvider.notifier).signOut();
  return client;
});

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider)));
final packageRepositoryProvider = Provider((ref) => PackageRepository(ref.watch(apiClientProvider)));
final bookingRepositoryProvider = Provider((ref) => BookingRepository(ref.watch(apiClientProvider)));

final welcomeSeenProvider = Provider<bool>(
  (ref) => ref.watch(sharedPreferencesProvider).getBool(_welcomeSeenKey) ?? false,
);

Future<void> markWelcomeSeen(SharedPreferences prefs) => prefs.setBool(_welcomeSeenKey, true);

// ---------------------------------------------------------------------------
// Authentication
// ---------------------------------------------------------------------------

/// Holds the signed-in user (or `null`). The session is persisted so the app
/// opens instantly signed-in, then refreshed from the API in the background.
class AuthController extends Notifier<User?> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  User? build() {
    final cached = _prefs.getString(_userKey);
    if (cached == null || _prefs.getString(_tokenKey) == null) return null;
    Future.microtask(_refresh);
    return User.fromJson(jsonDecode(cached) as Map<String, dynamic>);
  }

  Future<void> _refresh() async {
    try {
      _setUser(await _repo.me());
    } on ApiException catch (e) {
      if (e.isUnauthorized) await signOut();
    }
  }

  Future<void> login(String email, String password) async {
    await _persist(await _repo.login(email: email, password: password));
  }

  Future<void> register({required String name, required String email, required String password, String? phone}) async {
    await _persist(await _repo.register(name: name, email: email, password: password, phone: phone));
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    _setUser(await _repo.updateProfile(name: name, phone: phone));
  }

  Future<void> signOut() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
    state = null;
  }

  Future<void> _persist(AuthSession session) async {
    await _prefs.setString(_tokenKey, session.token);
    _setUser(session.user);
  }

  void _setUser(User user) {
    _prefs.setString(_userKey, jsonEncode(user.toJson()));
    state = user;
  }
}

final authControllerProvider = NotifierProvider<AuthController, User?>(AuthController.new);

// ---------------------------------------------------------------------------
// Catalogue
// ---------------------------------------------------------------------------

final catalogOptionsProvider = FutureProvider<CatalogOptions>((ref) => ref.watch(packageRepositoryProvider).options());

class PackageQueryController extends Notifier<PackageQuery> {
  @override
  PackageQuery build() => const PackageQuery();

  void setSearch(String value) => state = state.copyWith(search: value.trim());
  void setRegion(String? value) => state = state.copyWith(region: () => value);
  void setCategory(String? value) => state = state.copyWith(category: () => value);
  void setSort(String value) => state = state.copyWith(sort: value);
  void reset() => state = const PackageQuery();
}

final packageQueryProvider = NotifierProvider<PackageQueryController, PackageQuery>(PackageQueryController.new);

final packagesProvider = FutureProvider<List<TourPackage>>(
  (ref) => ref.watch(packageRepositoryProvider).list(ref.watch(packageQueryProvider)),
);

final featuredPackagesProvider = FutureProvider<List<TourPackage>>((ref) async {
  final all = await ref.watch(packageRepositoryProvider).list();
  return all.where((p) => p.isFeatured).toList();
});

final packageDetailProvider = FutureProvider.family<PackageDetail, String>(
  (ref, slug) => ref.watch(packageRepositoryProvider).detail(slug),
);

final packageReviewsProvider = FutureProvider.family<List<Review>, String>(
  (ref, slug) => ref.watch(packageRepositoryProvider).reviews(slug),
);

// ---------------------------------------------------------------------------
// Bookings
// ---------------------------------------------------------------------------

final myBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final userId = ref.watch(authControllerProvider.select((u) => u?.id));
  if (userId == null) return const [];
  return ref.watch(bookingRepositoryProvider).mine();
});

final bookingProvider = FutureProvider.family<Booking, String>(
  (ref, reference) => ref.watch(bookingRepositoryProvider).byReference(reference),
);

/// Refreshes every view that shows booking or review data after a mutation.
void refreshBookingData(WidgetRef ref, {String? reference, String? packageSlug}) {
  ref.invalidate(myBookingsProvider);
  if (reference != null) ref.invalidate(bookingProvider(reference));
  if (packageSlug != null) {
    ref.invalidate(packageDetailProvider(packageSlug));
    ref.invalidate(packageReviewsProvider(packageSlug));
    ref.invalidate(packagesProvider);
    ref.invalidate(featuredPackagesProvider);
  }
}
