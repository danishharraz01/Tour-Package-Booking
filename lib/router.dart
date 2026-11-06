import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_screen.dart';
import 'features/booking/booking_screen.dart';
import 'features/home/home_screen.dart';
import 'features/package/package_detail_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/trips/booking_detail_screen.dart';
import 'features/trips/trips_screen.dart';
import 'features/welcome/welcome_screen.dart';
import 'state/providers.dart';

/// Routes that need a signed-in user. Guests are sent to sign in and then
/// returned to where they were going.
bool _requiresAuth(String path) => path.endsWith('/book') || path.startsWith('/booking/');

final routerProvider = Provider<GoRouter>((ref) {
  final signedIn = ValueNotifier<bool>(ref.read(authControllerProvider) != null);
  ref.listen(authControllerProvider, (_, user) => signedIn.value = user != null);
  ref.onDispose(signedIn.dispose);

  return GoRouter(
    initialLocation: ref.read(welcomeSeenProvider) ? '/' : '/welcome',
    refreshListenable: signedIn,
    redirect: (context, state) {
      final path = state.uri.path;
      if (!signedIn.value && _requiresAuth(path)) {
        return Uri(path: '/login', queryParameters: {'from': state.uri.toString()}).toString();
      }
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/trips', builder: (_, _) => const TripsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/packages/:slug',
        builder: (_, s) => PackageDetailScreen(slug: s.pathParameters['slug']!),
        routes: [
          GoRoute(
            path: 'book',
            builder: (_, s) => BookingScreen(slug: s.pathParameters['slug']!),
          ),
        ],
      ),
      GoRoute(
        path: '/booking/:reference',
        builder: (_, s) => BookingDetailScreen(
          reference: s.pathParameters['reference']!,
          justConfirmed: s.uri.queryParameters['confirmed'] == '1',
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (_, s) => AuthScreen(mode: AuthMode.login, redirectTo: s.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/register',
        builder: (_, s) => AuthScreen(mode: AuthMode.register, redirectTo: s.uri.queryParameters['from']),
      ),
    ],
  );
});

class _AppShell extends StatelessWidget {
  const _AppShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(icon: Icon(Icons.luggage_outlined), selectedIcon: Icon(Icons.luggage), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
