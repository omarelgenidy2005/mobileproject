import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import 'workout_exercise.dart';

/// In‑progress workout session persisted locally for offline‑first logging.
class ActiveWorkoutSession extends Equatable {
  ActiveWorkoutSession({
    String? id,
    this.title = 'Workout',
    List<WorkoutExercise>? exercises,
    DateTime? startedAt,
    this.notes,
    this.userId,
    this.photoPath,
  })  : id = id ?? const Uuid().v4(),
        exercises = exercises ?? [],
        startedAt = startedAt ?? DateTime.now();

  final String id;
  final String title;
  final List<WorkoutExercise> exercises;
  final DateTime startedAt;
  final String? userId;
  final String? notes;
  final String? photoPath;

  bool get isEmpty => exercises.isEmpty;

  double get totalVolumeKg =>
      exercises.fold(0.0, (sum, e) => sum + e.totalVolumeKg);

  int get completedSetCount => exercises
      .expand((e) => e.sets)
      .where((s) => s.isCompleted)
      .length;

  ActiveWorkoutSession copyWith({
    String? title,
    List<WorkoutExercise>? exercises,
    String? notes,
    DateTime? startedAt,
    String? userId,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return ActiveWorkoutSession(
      id: id,
      title: title ?? this.title,
      exercises: exercises ?? List<WorkoutExercise>.from(this.exercises),
      startedAt: startedAt ?? this.startedAt,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'startedAt': startedAt.toIso8601String(),
        'userId': userId,
        'notes': notes,
        'photoPath': photoPath,
      };

  factory ActiveWorkoutSession.fromJson(Map<String, dynamic> json) {
    return ActiveWorkoutSession(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'Workout',
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
      userId: json['userId'] as String?,
      notes: json['notes'] as String?,
      photoPath: json['photoPath'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, title, exercises, startedAt, userId, notes, photoPath];
}
