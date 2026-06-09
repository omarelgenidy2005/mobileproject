/// Named route path constants used by [AppRouter].
abstract final class RoutePaths {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';

  /// Main shell with bottom navigation (child routes use relative paths).
  static const String shell = '/';

  static const String dashboard = '/dashboard';
  static const String activeWorkout = '/active-workout';
  static const String history = '/history';
  static const String analytics = '/analytics';

  static const String settings = '/settings';
  static const String adminPanel = '/admin';
  static const String customExercises = '/custom-exercises';
  // Route for AI‑generated next‑workout report
  static const String nextWorkoutReport = '/next-workout-report';
}
