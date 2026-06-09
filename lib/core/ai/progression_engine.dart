/// Lightweight Smart Progression Engine: suggests next-session weight/reps
/// from historical volume and estimated 1RM trends (Epley formula).
class ProgressionSuggestion {
  const ProgressionSuggestion({
    required this.exerciseId,
    required this.exerciseName,
    required this.suggestedWeightKg,
    required this.suggestedReps,
    required this.estimatedOneRepMaxKg,
    required this.rationale,
  });

  final String exerciseId;
  final String exerciseName;
  final double suggestedWeightKg;
  final int suggestedReps;
  final double estimatedOneRepMaxKg;
  final String rationale;
}

/// Input point from workout history for trend analysis.
class HistorySetPoint {
  const HistorySetPoint({
    required this.date,
    required this.weightKg,
    required this.reps,
  });

  final DateTime date;
  final double weightKg;
  final int reps;

  double get estimated1Rm => ProgressionEngine.estimateOneRepMax(weightKg, reps);
}

abstract final class ProgressionEngine {
  /// Epley: 1RM ≈ weight × (1 + reps/30)
  static double estimateOneRepMax(double weightKg, int reps) {
    if (reps <= 0) return weightKg;
    if (reps == 1) return weightKg;
    return weightKg * (1 + reps / 30);
  }

  /// Analyzes recent history and returns a safe progressive-overload target.
  static ProgressionSuggestion suggest({
    required String exerciseId,
    required String exerciseName,
    required List<HistorySetPoint> history,
    int targetReps = 8,
    double overloadIncrementKg = 2.5,
  }) {
    if (history.isEmpty) {
      return ProgressionSuggestion(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        suggestedWeightKg: 20,
        suggestedReps: targetReps,
        estimatedOneRepMaxKg: 20 * (1 + targetReps / 30),
        rationale: 'No history yet — start with a comfortable working weight.',
      );
    }

    final sorted = List<HistorySetPoint>.from(history)
      ..sort((a, b) => a.date.compareTo(b.date));

    final recent = sorted.length >= 3 ? sorted.sublist(sorted.length - 3) : sorted;
    final latest = sorted.last;

    final avg1Rm = recent.map((p) => p.estimated1Rm).reduce((a, b) => a + b) / recent.length;
    final trend = recent.last.estimated1Rm - recent.first.estimated1Rm;

  // Target ~75% of estimated 1RM for hypertrophy-style working sets
    var workingWeight = (avg1Rm * 0.75 / 2.5).round() * 2.5;
    if (trend > 0) {
      workingWeight += overloadIncrementKg;
    }

    final lastCompletedReps = latest.reps;
    var reps = targetReps;
    if (lastCompletedReps >= targetReps + 2) {
      reps = targetReps;
    } else if (lastCompletedReps < targetReps - 1) {
      workingWeight = (workingWeight - overloadIncrementKg).clamp(0, double.infinity);
      reps = targetReps;
    }

    return ProgressionSuggestion(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      suggestedWeightKg: workingWeight,
      suggestedReps: reps,
      estimatedOneRepMaxKg: avg1Rm,
      rationale: trend > 0
          ? '1RM trend is up ${trend.toStringAsFixed(1)} kg — small overload applied.'
          : 'Hold or slightly reduce load until reps recover at target.',
    );
  }
}
