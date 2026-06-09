import 'dart:math';

import '../../../data/models/workout_exercise.dart';
import '../../history/providers/history_provider.dart';

class AiPrediction {
  final double weightKg;
  final int reps;
  final String reasoning;

  const AiPrediction({
    required this.weightKg,
    required this.reps,
    required this.reasoning,
  });
}

class AiPredictionService {
  /// Predicts the next optimal set for an exercise using linear regression 
  /// on the user's past maximum weights over time.
  static AiPrediction predictNextSet(String exerciseId, HistoryProvider historyProvider) {
    final sessions = historyProvider.sessions.reversed.toList();
    
    // Extract max weights per day
    final List<_DataPoint> points = [];
    
    for (final session in sessions) {
      final ex = session.exercises.cast<WorkoutExercise?>().firstWhere(
            (e) => e?.exerciseId == exerciseId,
            orElse: () => null,
          );
      
      if (ex != null) {
        final completedSets = ex.sets.where((s) => s.isCompleted);
        if (completedSets.isNotEmpty) {
          double maxW = 0.0;
          int bestReps = 0;
          for (final s in completedSets) {
            if (s.weightKg > maxW) {
              maxW = s.weightKg;
              bestReps = s.reps;
            } else if (s.weightKg == maxW && s.reps > bestReps) {
              bestReps = s.reps;
            }
          }
          points.add(_DataPoint(date: session.startedAt, weight: maxW, reps: bestReps));
        }
      }
    }

    if (points.isEmpty) {
      return const AiPrediction(
        weightKg: 20.0,
        reps: 8,
        reasoning: 'First time doing this exercise. Let\'s start light to establish a baseline.',
      );
    }

    // Sort chronologically
    points.sort((a, b) => a.date.compareTo(b.date));
    
    final lastPoint = points.last;
    
    if (points.length == 1) {
      return AiPrediction(
        weightKg: _roundToNearest2_5(lastPoint.weight + 2.5),
        reps: lastPoint.reps,
        reasoning: 'Only 1 session logged. Try adding a little weight from last time.',
      );
    }

    // Perform linear regression: y = mx + b
    // x = days since first session, y = max weight
    final firstDate = points.first.date;
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumXX = 0;
    final int n = points.length;

    for (final p in points) {
      final x = p.date.difference(firstDate).inDays.toDouble();
      final y = p.weight;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }

    double denominator = (n * sumXX) - (sumX * sumX);
    double slope = 0.0;
    if (denominator != 0) {
      slope = ((n * sumXY) - (sumX * sumY)) / denominator;
    }

    final todayX = DateTime.now().difference(firstDate).inDays.toDouble();
    
    if (slope > 0) {
      // Y-intercept
      final b = (sumY - slope * sumX) / n;
      double expectedToday = slope * todayX + b;
      
      // We don't want the model to predict less than the last weight if slope is slightly off,
      // but if the trend is super steep, we cap the jump at +5kg max per session.
      double predictedW = expectedToday;
      if (predictedW < lastPoint.weight) {
        predictedW = lastPoint.weight;
      } else if (predictedW > lastPoint.weight + 5.0) {
        predictedW = lastPoint.weight + 5.0;
      }
      
      // Ensure we always suggest at least an improvement if slope > 0
      if (predictedW <= lastPoint.weight) {
        predictedW = lastPoint.weight + 2.5;
      }

      return AiPrediction(
        weightKg: _roundToNearest2_5(predictedW),
        reps: lastPoint.reps,
        reasoning: 'Based on your positive trend of +${slope.toStringAsFixed(2)}kg/day, you are ready for a heavier lift.',
      );
    } else {
      // Flat or negative slope (plateau)
      return AiPrediction(
        weightKg: lastPoint.weight,
        reps: lastPoint.reps + 1,
        reasoning: 'Your strength trend has plateaued. Keep the same weight and try to push for 1 extra rep!',
      );
    }
  }

  static double _roundToNearest2_5(double value) {
    return (value / 2.5).round() * 2.5;
  }
}

class _DataPoint {
  final DateTime date;
  final double weight;
  final int reps;

  _DataPoint({required this.date, required this.weight, required this.reps});
}
