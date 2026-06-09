import 'dart:async';
import 'dart:convert';
import '../../../core/services/notification_service.dart';
import '../../history/providers/history_provider.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/models/active_workout_session.dart';
import '../../../data/models/workout_exercise.dart';
import '../../../data/models/workout_set.dart';

/// ChangeNotifier-backed state for the active workout tab.
///
/// Manages exercises, sets, reps, and weights with automatic local persistence
/// so users can log fully offline; sync to Firestore is handled separately.
class ActiveWorkoutProvider extends ChangeNotifier {
  ActiveWorkoutProvider({SharedPreferences? prefs, HistoryProvider? historyProvider}) : _prefs = prefs, _historyProvider = historyProvider;

  static const String _prefsKey = 'active_workout_session';

  SharedPreferences? _prefs;
  final HistoryProvider? _historyProvider;
  ActiveWorkoutSession? _session;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _reminderTimer;

  ActiveWorkoutSession? get session => _session;
  bool get hasActiveSession => _session != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<WorkoutExercise> get exercises => _session?.exercises ?? const [];

  /// Hydrates any in-progress workout from SharedPreferences on app launch.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_prefsKey);
      if (raw != null) {
        _session = ActiveWorkoutSession.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
        _startReminderTimer();
      }
    } catch (e) {
      _errorMessage = 'Could not restore active workout.';
      debugPrint('ActiveWorkoutProvider.initialize: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Starts a new workout session, optionally discarding the current one.
  Future<void> startWorkout({required String title, required DateTime startedAt}) async {
    _session = ActiveWorkoutSession(title: title, startedAt: startedAt);
    await _persist();
    _startReminderTimer();
    notifyListeners();
  }

  /// Updates details of the active workout session (title, date).
  Future<void> updateWorkoutDetails({required String title, required DateTime startedAt}) async {
    _ensureSession();
    _session = _session!.copyWith(title: title, startedAt: startedAt);
    await _persist();
    notifyListeners();
  }

  Future<void> setPhoto(String? path) async {
    if (_session == null) return;
    _session = _session!.copyWith(photoPath: path, clearPhoto: path == null);
    await _persist();
    notifyListeners();
  }

  Future<void> endWorkout() async {
    _cancelReminderTimer();
    if (_session != null) {
      await _historyProvider?.addSession(_session!);
    }
    _session = null;
    await _prefs?.remove(_prefsKey);
    notifyListeners();
  }

  Future<void> addExercise({
    required String exerciseId,
    required String name,
    String? muscleGroup,
  }) async {
    _ensureSession();
    final updated = List<WorkoutExercise>.from(_session!.exercises)
      ..add(WorkoutExercise(exerciseId: exerciseId, name: name, muscleGroup: muscleGroup));
    _session = _session!.copyWith(exercises: updated);
    await _persist();
    _startReminderTimer();
    notifyListeners();
  }

  Future<void> removeExercise(String exerciseId) async {
    if (_session == null) return;
    final updated = _session!.exercises.where((e) => e.id != exerciseId).toList();
    _session = _session!.copyWith(exercises: updated);
    await _persist();
    notifyListeners();
  }

  Future<void> addSet(String exerciseId, {double weightKg = 0, int reps = 0}) async {
    _ensureSession();
    if (weightKg < 0) {
      throw const ValidationException('Weight must be a positive number.');
    }
    if (reps < 0) {
      throw const ValidationException('Reps must be a positive integer.');
    }
    final updated = _session!.exercises.map((exercise) {
      if (exercise.id != exerciseId) return exercise;
      final sets = List<WorkoutSet>.from(exercise.sets)
        ..add(WorkoutSet(weightKg: weightKg, reps: reps));
      return exercise.copyWith(sets: sets);
    }).toList();
    _session = _session!.copyWith(exercises: updated);
    await _persist();
    _startReminderTimer();
    notifyListeners();
  }



  Future<void> updateSet({
    required String exerciseId,
    required String setId,
    double? weightKg,
    int? reps,
    bool? isCompleted,
    double? rpe,
  }) async {
    _ensureSession();

    final updated = _session!.exercises.map((exercise) {
      if (exercise.id != exerciseId) return exercise;
      final sets = exercise.sets.map((set) {
        if (set.id != setId) return set;
        return set.copyWith(
          weightKg: weightKg,
          reps: reps,
          isCompleted: isCompleted,
          rpe: rpe,
        );
      }).toList();
      return exercise.copyWith(sets: sets);
    }).toList();

    _session = _session!.copyWith(exercises: updated);
    await _persist();
    _startReminderTimer();
    notifyListeners();
  }

  Future<void> removeSet({required String exerciseId, required String setId}) async {
    if (_session == null) return;
    final updated = _session!.exercises.map((exercise) {
      if (exercise.id != exerciseId) return exercise;
      final sets = exercise.sets.where((s) => s.id != setId).toList();
      return exercise.copyWith(sets: sets);
    }).toList();
    _session = _session!.copyWith(exercises: updated);
    await _persist();
    notifyListeners();
  }

  /// Parses voice/text input like "100 kilos for 8 reps" into the active set fields.
  void applyVoiceParsedSet({
    required String exerciseId,
    required double weightKg,
    required int reps,
  }) {
    final exercise = _session?.exercises.cast<WorkoutExercise?>().firstWhere(
          (e) => e?.id == exerciseId,
          orElse: () => null,
        );
    if (exercise == null) return;

    if (exercise.sets.isEmpty) {
      addSet(exerciseId, weightKg: weightKg, reps: reps);
    } else {
      final lastSet = exercise.sets.last;
      updateSet(
        exerciseId: exerciseId,
        setId: lastSet.id,
        weightKg: weightKg,
        reps: reps,
      );
    }
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (_session == null) return;
    await _prefs!.setString(_prefsKey, jsonEncode(_session!.toJson()));
  }

  void _ensureSession() {
    if (_session == null) {
      throw const ValidationException('Start a workout before adding exercises.');
    }
  }

  void _startReminderTimer() {
    _reminderTimer?.cancel();
    _reminderTimer = Timer(const Duration(seconds: 30), () {
      NotificationService.showWorkoutReminder();
    });
  }

  void _cancelReminderTimer() {
    _reminderTimer?.cancel();
  }
}
