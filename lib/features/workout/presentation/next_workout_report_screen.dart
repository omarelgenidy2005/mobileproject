import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_tracker_3ash/core/navigation/constants/route_paths.dart';
import 'next_workout_report.dart';

class NextWorkoutReportScreen extends StatelessWidget {
  const NextWorkoutReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Next Workout Suggestion'),
      ),
      body: Column(
        children: [
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: NextWorkoutReport(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => context.go(RoutePaths.dashboard),
              child: const Text('Back to Dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}
