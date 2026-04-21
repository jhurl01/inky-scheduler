import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'providers/ui_state_provider.dart';
import 'providers/user_provider.dart';
import 'screens/canvas/canvas_screen.dart';
import 'screens/month/month_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/today/add_event_sheet.dart';
import 'screens/today/event_detail_screen.dart';
import 'screens/today/today_screen.dart';
import 'screens/you/you_screen.dart';
import 'widgets/bottom_nav.dart';
import 'widgets/ink_fab.dart';

// ── Router provider ────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  return GoRouter(
    initialLocation: '/today',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final userAsync = ref.read(currentUserProvider);

      // Don't redirect while loading
      if (authAsync.isLoading || userAsync.isLoading) return null;

      final firebaseUser = authAsync.valueOrNull;
      final userModel = userAsync.valueOrNull;
      final onOnboarding =
          state.matchedLocation.startsWith('/onboarding');

      // Not signed in → onboarding
      if (firebaseUser == null) {
        return onOnboarding ? null : '/onboarding';
      }

      // Signed in but Firestore doc still loading
      if (userModel == null) return null;

      // Signed in but not paired → onboarding (pairing step)
      if (userModel.coupleId == null) {
        return onOnboarding ? null : '/onboarding';
      }

      // Paired and somehow on onboarding → main app
      if (onOnboarding) return '/today';

      return null; // no redirect
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _MainShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/today',
            builder: (_, __) => const TodayScreen(),
          ),
          GoRoute(
            path: '/day/:date',
            builder: (_, state) {
              final date =
                  DateTime.parse(state.pathParameters['date']!);
              return TodayScreen(initialDate: date);
            },
          ),
          GoRoute(
            path: '/event/:eventId',
            builder: (_, state) =>
                EventDetailScreen(eventId: state.pathParameters['eventId']!),
          ),
          GoRoute(
            path: '/month',
            builder: (_, __) => const MonthScreen(),
          ),
          GoRoute(
            path: '/canvas',
            builder: (_, __) => const CanvasScreen(),
          ),
          GoRoute(
            path: '/you',
            builder: (_, __) => const YouScreen(),
          ),
        ],
      ),
    ],
  );
});

// ── Shell widget ───────────────────────────────────────────────────────────────

class _MainShell extends ConsumerWidget {
  final String location;
  final Widget child;
  const _MainShell({required this.location, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewedDate = ref.watch(viewedDateProvider);

    return Scaffold(
      body: child,
      floatingActionButton: InkFab(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => Padding(
            // Respect keyboard insets so the sheet slides above the keyboard
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: AddEventSheet(initialDate: viewedDate),
          ),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(currentLocation: location),
    );
  }
}

// ── Router refresh notifier ────────────────────────────────────────────────────

/// Listens to Riverpod auth + user providers and notifies go_router to
/// re-evaluate its redirect guard whenever either changes.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
}
