import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/active_workout_provider.dart';
import '../../../data/models/workout_exercise.dart';

/// A very simple widget that "predicts" the next workout suggestion.
/// It looks at the most recent exercise in the active workout session
/// and recommends a set with a slightly higher weight.
class NextWorkoutReport extends StatelessWidget {
  const NextWorkoutReport({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActiveWorkoutProvider>();
    final exercises = provider.exercises;

    if (exercises.isEmpty) {
      return const Center(
        child: Text('Start a workout to get a suggestion'),
      );
    }

    // Take the last exercise and its last set (if any).
    final lastExercise = exercises.last;
    final lastSet = lastExercise.sets.isNotEmpty ? lastExercise.sets.last : null;

    final suggestedWeight = (lastSet?.weightKg ?? 0) + 2.5; // simple increment
    final suggestedReps = lastSet?.reps ?? 8;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next Workout Suggestion',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Exercise: ${lastExercise.name}'),
            Text('Weight: ${suggestedWeight.toStringAsFixed(1)} kg'),
            Text('Reps: $suggestedReps'),
            const SizedBox(height: 8),
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
