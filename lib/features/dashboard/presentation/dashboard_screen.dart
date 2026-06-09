import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../features/workout/providers/active_workout_provider.dart';
import '../../../core/navigation/constants/route_paths.dart';
import '../../../features/workout/presentation/next_workout_report_screen.dart';
import '../../../features/history/providers/history_provider.dart';
import '../../../features/workout/services/ai_prediction_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workout = context.watch<ActiveWorkoutProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  workout.hasActiveSession
                      ? 'Active: ${workout.session!.title} · ${workout.session!.completedSetCount} sets logged'
                      : 'No workout in progress. Head to Workout to start.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Smart Progression', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                if (!workout.hasActiveSession || workout.exercises.isEmpty)
                  Text(
                    'Start a workout and add exercises to see AI load suggestions based on your history.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  Builder(
                    builder: (context) {
                      final historyProvider = context.read<HistoryProvider>();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: workout.exercises.map((ex) {
                          final prediction = AiPredictionService.predictNextSet(ex.exerciseId, historyProvider);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(ex.name, overflow: TextOverflow.ellipsis)),
                                Text(
                                  '${prediction.weightKg}kg x ${prediction.reps}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
