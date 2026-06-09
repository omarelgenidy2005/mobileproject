import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/app_user.dart';
import '../../features/admin/presentation/admin_panel_screen.dart';
import '../../features/auth/guards/admin_guard.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/workout/presentation/next_workout_report_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/settings/presentation/custom_exercises_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/workout/presentation/active_workout_screen.dart';
import '../constants/route_paths.dart';
import 'main_shell.dart';

/// Central routing configuration with auth redirect and shell routes.
class AppRouter {
  AppRouter({required Listenable authListenable, required AppUser? Function() getUser})
      : router = GoRouter(
          initialLocation: RoutePaths.dashboard,
          refreshListenable: authListenable,
          redirect: (context, state) {
            final user = getUser();
            final isAuthRoute = state.matchedLocation == RoutePaths.login ||
                state.matchedLocation == RoutePaths.register;

            if (user == null && !isAuthRoute) return RoutePaths.login;
            if (user != null && isAuthRoute) return RoutePaths.dashboard;
            return null;
          },
          routes: [
            GoRoute(
              path: RoutePaths.login,
              builder: (context, state) => const LoginScreen(),
            ),
            GoRoute(
              path: RoutePaths.register,
              builder: (context, state) => const LoginScreen(isRegister: true),
            ),
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) =>
                  MainShell(navigationShell: navigationShell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: RoutePaths.dashboard,
                      builder: (context, state) => const DashboardScreen(),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: RoutePaths.activeWorkout,
                      builder: (context, state) => const ActiveWorkoutScreen(),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: RoutePaths.history,
                      builder: (context, state) => const HistoryScreen(),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: RoutePaths.analytics,
                      builder: (context, state) => const AnalyticsScreen(),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: RoutePaths.nextWorkoutReport,
              builder: (context, state) => const NextWorkoutReportScreen(),
            ),
            GoRoute(
              path: RoutePaths.adminPanel,
              builder: (context, state) => const AdminGuard(
                child: AdminPanelScreen(),
              ),
            ),
            GoRoute(
              path: RoutePaths.customExercises,
              builder: (context, state) => const CustomExercisesScreen(),
            ),
          ],
        );

  final GoRouter router;
}
