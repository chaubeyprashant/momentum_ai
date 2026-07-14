import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/route_paths.dart';
import '../../features/accountability/accountability_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/coach/coach_screen.dart';
import '../../features/focus/focus_screen.dart';
import '../../features/habits/habits_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/journal/journal_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/roadmap/roadmap_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/vision_board/vision_board_screen.dart';
import '../../providers/app_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingComplete = ref.watch(userProfileProvider).when(
        data: (profile) => profile?.onboardingComplete ?? false,
        loading: () => null,
        error: (_, __) => false,
      );

  return GoRouter(
    initialLocation: RoutePaths.splash,
    redirect: (context, state) {
      final isSplash = state.matchedLocation == RoutePaths.splash;
      final isOnboarding = state.matchedLocation == RoutePaths.onboarding;

      if (isSplash) return null;

      if (onboardingComplete == null) return RoutePaths.splash;

      if (!onboardingComplete && !isOnboarding) {
        return RoutePaths.onboarding;
      }

      if (onboardingComplete && isOnboarding) {
        return RoutePaths.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.coach,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CoachScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.analytics,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),
          GoRoute(
            path: RoutePaths.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.chat,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: RoutePaths.accountability,
        builder: (context, state) => const AccountabilityScreen(),
      ),
      GoRoute(
        path: RoutePaths.focus,
        builder: (context, state) => const FocusScreen(),
      ),
      GoRoute(
        path: RoutePaths.habits,
        builder: (context, state) => const HabitsScreen(),
      ),
      GoRoute(
        path: RoutePaths.journal,
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: RoutePaths.visionBoard,
        builder: (context, state) => const VisionBoardScreen(),
      ),
      GoRoute(
        path: RoutePaths.roadmap,
        builder: (context, state) => const RoadmapScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

/// Bottom navigation shell for main tabs.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RoutePaths.coach)) return 1;
    if (location.startsWith(RoutePaths.analytics)) return 2;
    if (location.startsWith(RoutePaths.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go(RoutePaths.home);
            case 1:
              context.go(RoutePaths.coach);
            case 2:
              context.go(RoutePaths.analytics);
            case 3:
              context.go(RoutePaths.profile);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
