/// Global application constants for the 3ash workout tracker.
abstract final class AppConstants {
  static const String appName = '3ash';

  /// Hive box names for offline-first caching.
  static const String hiveBoxWorkouts = 'workouts_cache';
  static const String hiveBoxExercises = 'exercises_cache';
  static const String hiveBoxSyncQueue = 'sync_queue';
  static const String hiveBoxUserPrefs = 'user_prefs';

  /// Firestore collection paths.
  static const String usersCollection = 'users';
  static const String workoutsCollection = 'workouts';
  static const String exercisesCollection = 'exercises';

  /// Biometric lock: seconds in background before re-auth is required.
  static const int biometricLockTimeoutSeconds = 30;

  /// Rest timer notification channel.
  static const String restTimerChannelId = '3ash_rest_timer';
  static const String restTimerChannelName = 'Rest Interval Timer';
}
