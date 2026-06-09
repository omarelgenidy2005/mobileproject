import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// A single logged set within an active workout exercise.
class WorkoutSet extends Equatable {
  WorkoutSet({
    String? id,
    this.weightKg = 0,
    this.reps = 0,
    this.isCompleted = false,
    this.rpe,
    this.notes,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final double weightKg;
  final int reps;
  final bool isCompleted;
  final double? rpe;
  final String? notes;

  WorkoutSet copyWith({
    double? weightKg,
    int? reps,
    bool? isCompleted,
    double? rpe,
    String? notes,
  }) {
    return WorkoutSet(
      id: id,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
      rpe: rpe ?? this.rpe,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'weightKg': weightKg,
        'reps': reps,
        'isCompleted': isCompleted,
        'rpe': rpe,
        'notes': notes,
      };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      id: json['id'] as String?,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      rpe: (json['rpe'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, weightKg, reps, isCompleted, rpe, notes];
}
