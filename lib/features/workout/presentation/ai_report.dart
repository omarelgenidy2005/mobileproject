import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/active_workout_provider.dart';
import '../providers/exercise_provider.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout_exercise.dart';

/// A very simple AI‑generated report that suggests the next workout.
///
/// It looks at the current active workout, picks the last set weight
/// (if any) and proposes a slight increase for the next session.
/// It also suggests an exercise that hasn't been marked as completed
/// yet, falling back to the first available exercise.
class AiReportWidget extends StatelessWidget {
  const AiReportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final activeProvider = context.watch<ActiveWorkoutProvider>();
    final exerciseProvider = context.watch<ExerciseProvider>();

    // Determine the exercise to suggest.
    final activeExercises = activeProvider.exercises;
    final activeExerciseIds = activeExercises.map((e) => e.exerciseId).toSet();
    
    Exercise? suggestedExercise;
    final unaddedExercises = exerciseProvider.exercises
        .where((e) => !activeExerciseIds.contains(e.id))
        .toList();
        
    if (unaddedExercises.isNotEmpty) {
      suggestedExercise = unaddedExercises.first;
    } else if (exerciseProvider.exercises.isNotEmpty) {
      suggestedExercise = exerciseProvider.exercises.first;
    }

    // Determine weight suggestion based on the last set of that exercise.
    double suggestedWeight = 20.0; // default weight in kg
    if (suggestedExercise != null) {
      final sessionExercise = activeExercises.cast<WorkoutExercise?>().firstWhere(
            (e) => e?.exerciseId == suggestedExercise?.id,
            orElse: () => null,
          );
      if (sessionExercise != null && sessionExercise.sets.isNotEmpty) {
        final lastSet = sessionExercise.sets.last;
        if (lastSet.weightKg > 0) {
          suggestedWeight = double.parse((lastSet.weightKg + 2.5).toStringAsFixed(1));
        }
      }
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Workout Suggestion',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (suggestedExercise != null) ...[
              Text('Exercise: ${suggestedExercise.name}'),
              Text('Suggested Weight: ${suggestedWeight.toStringAsFixed(1)} kg'),
            ] else
              const Text('No exercises available to suggest.'),
          ],
        ),
      ),
    );
  }
}
