import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

import 'workout_set.dart';

/// An exercise block inside an active workout session.
class WorkoutExercise extends Equatable {
  WorkoutExercise({
    String? id,
    required this.exerciseId,
    required this.name,
    List<WorkoutSet>? sets,
    this.muscleGroup,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        sets = sets ?? [];

  final String id;
  final String exerciseId;
  final String name;
  final String? muscleGroup;
  final String? notes;
  final List<WorkoutSet> sets;

  double get totalVolumeKg => sets
      .where((s) => s.isCompleted)
      .fold(0.0, (sum, s) => sum + (s.weightKg * s.reps));

  WorkoutExercise copyWith({
    String? name,
    String? muscleGroup,
    String? notes,
    List<WorkoutSet>? sets,
  }) {
    return WorkoutExercise(
      id: id,
      exerciseId: exerciseId,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      notes: notes ?? this.notes,
      sets: sets ?? List<WorkoutSet>.from(this.sets),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseId': exerciseId,
        'name': name,
        'muscleGroup': muscleGroup,
        'notes': notes,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      id: json['id'] as String?,
      exerciseId: json['exerciseId'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      muscleGroup: json['muscleGroup'] as String?,
      notes: json['notes'] as String?,
      sets: (json['sets'] as List<dynamic>?)
              ?.map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [id, exerciseId, name, muscleGroup, notes, sets];
}
