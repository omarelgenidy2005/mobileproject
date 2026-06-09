import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/services/sync_queue_service.dart';
import '../../../data/models/exercise.dart';

/// Manages predefined (admin) and custom (user) exercise definitions
/// with automatic local caching (Hive) and background syncing (Firestore).
class ExerciseProvider extends ChangeNotifier {
  ExerciseProvider({
    FirebaseFirestore? firestore,
    SyncQueueService? syncQueue,
    bool firebaseEnabled = true,
  })  : _firestore = firebaseEnabled ? (firestore ?? FirebaseFirestore.instance) : null,
        _syncQueue = syncQueue;

  final FirebaseFirestore? _firestore;
  final SyncQueueService? _syncQueue;

  List<Exercise> _exercises = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Exercise> get exercises => _exercises;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static const List<Map<String, String>> _defaultExercises = [
    {'id': 'bench_press', 'name': 'Bench Press', 'muscleGroup': 'Chest'},
    {'id': 'incline_bench_press', 'name': 'Incline Bench Press', 'muscleGroup': 'Chest'},
    {'id': 'chest_fly', 'name': 'Chest Fly', 'muscleGroup': 'Chest'},
    {'id': 'squat', 'name': 'Squat', 'muscleGroup': 'Legs'},
    {'id': 'leg_press', 'name': 'Leg Press', 'muscleGroup': 'Legs'},
    {'id': 'deadlift', 'name': 'Deadlift', 'muscleGroup': 'Back'},
    {'id': 'pull_up', 'name': 'Pull-up', 'muscleGroup': 'Back'},
    {'id': 'barbell_row', 'name': 'Barbell Row', 'muscleGroup': 'Back'},
    {'id': 'overhead_press', 'name': 'Overhead Press', 'muscleGroup': 'Shoulders'},
    {'id': 'lateral_raise', 'name': 'Lateral Raise', 'muscleGroup': 'Shoulders'},
    {'id': 'bicep_curl', 'name': 'Bicep Curl', 'muscleGroup': 'Arms'},
    {'id': 'tricep_pushdown', 'name': 'Tricep Pushdown', 'muscleGroup': 'Arms'},
    {'id': 'plank', 'name': 'Plank', 'muscleGroup': 'Core'},
  ];

  /// Initialize state: load from cache, seed defaults if empty, fetch from remote.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final box = HiveService.exercisesBox;
      if (box.isEmpty) {
        // Seed default exercises into Hive cache
        for (final item in _defaultExercises) {
          final exercise = Exercise(
            id: item['id']!,
            name: item['name']!,
            muscleGroup: item['muscleGroup']!,
            isCustom: false,
          );
          await box.put(exercise.id, exercise.toJson());
        }
      }

      _loadFromCache();

      // Fetch latest from Firestore if online
      if (_firestore != null) {
        await fetchRemoteExercises();
      }
    } catch (e) {
      _errorMessage = 'Could not load exercises database.';
      debugPrint('ExerciseProvider.initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadFromCache() {
    final box = HiveService.exercisesBox;
    _exercises = box.values
        .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    // Sort alphabetically by name
    _exercises.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Refreshes exercise list from Firestore.
  Future<void> fetchRemoteExercises() async {
    if (_firestore == null) return;
    try {
      final snapshot = await _firestore!.collection(AppConstants.exercisesCollection).get();
      final box = HiveService.exercisesBox;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        await box.put(doc.id, data);
      }
      _loadFromCache();
      notifyListeners();
    } catch (e) {
      debugPrint('ExerciseProvider.fetchRemoteExercises failed (offline or missing permission): $e');
    }
  }

  /// Adds a global exercise definition (Admin feature).
  Future<void> addPredefinedExercise({
    required String name,
    required String muscleGroup,
  }) async {
    final newExercise = Exercise.create(
      name: name,
      muscleGroup: muscleGroup,
      isCustom: false,
    );

    // Save to cache
    await HiveService.exercisesBox.put(newExercise.id, newExercise.toJson());
    _loadFromCache();
    notifyListeners();

    // Queue / upload to Firestore
    if (_syncQueue != null) {
      await _syncQueue!.enqueue(
        collection: AppConstants.exercisesCollection,
        documentId: newExercise.id,
        data: newExercise.toJson(),
      );
    } else if (_firestore != null) {
      await _firestore!
          .collection(AppConstants.exercisesCollection)
          .doc(newExercise.id)
          .set(newExercise.toJson());
    }
  }

  /// Adds a custom user-defined exercise definition.
  Future<void> addCustomExercise({
    required String name,
    required String muscleGroup,
    String? userId,
  }) async {
    final newExercise = Exercise.create(
      name: name,
      muscleGroup: muscleGroup,
      isCustom: true,
      userId: userId,
    );

    // Save to cache
    await HiveService.exercisesBox.put(newExercise.id, newExercise.toJson());
    _loadFromCache();
    notifyListeners();

    // Queue / upload to Firestore
    if (_syncQueue != null) {
      await _syncQueue!.enqueue(
        collection: AppConstants.exercisesCollection,
        documentId: newExercise.id,
        data: newExercise.toJson(),
      );
    } else if (_firestore != null) {
      await _firestore!
          .collection(AppConstants.exercisesCollection)
          .doc(newExercise.id)
          .set(newExercise.toJson());
    }
  }

  /// Deletes an exercise definition globally and locally.
  Future<void> deleteExercise(String id) async {
    await HiveService.exercisesBox.delete(id);
    _loadFromCache();
    notifyListeners();

    if (_firestore != null) {
      try {
        await _firestore!.collection(AppConstants.exercisesCollection).doc(id).delete();
      } catch (e) {
        debugPrint('ExerciseProvider.deleteExercise remote delete failed: $e');
      }
    }
  }
}
