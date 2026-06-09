import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Opens Hive boxes used for offline-first workout and sync-queue caching.
abstract final class HiveService {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<Map>(AppConstants.hiveBoxWorkouts),
      Hive.openBox<Map>(AppConstants.hiveBoxExercises),
      Hive.openBox<Map>(AppConstants.hiveBoxSyncQueue),
      Hive.openBox(AppConstants.hiveBoxUserPrefs),
    ]);
  }

  static Box<Map> get workoutsBox => Hive.box<Map>(AppConstants.hiveBoxWorkouts);
  static Box<Map> get exercisesBox => Hive.box<Map>(AppConstants.hiveBoxExercises);
  static Box<Map> get syncQueueBox => Hive.box<Map>(AppConstants.hiveBoxSyncQueue);
  static Box get userPrefsBox => Hive.box(AppConstants.hiveBoxUserPrefs);
}
