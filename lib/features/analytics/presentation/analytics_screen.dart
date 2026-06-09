import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/models/workout_exercise.dart';
import '../../history/providers/history_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? _selectedExerciseId;

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final sessions = historyProvider.sessions;

    // 1. Gather all unique exercises that have been performed with completed sets
    final performedExercises = <String, String>{}; // exerciseId -> name
    for (final session in sessions) {
      for (final ex in session.exercises) {
        final completedSets = ex.sets.where((s) => s.isCompleted);
        if (completedSets.isNotEmpty) {
          performedExercises[ex.exerciseId] = ex.name;
        }
      }
    }

    final exerciseList = performedExercises.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Fallback or auto-selection logic
    String? selectedId = _selectedExerciseId;
    if (selectedId == null || !performedExercises.containsKey(selectedId)) {
      if (exerciseList.isNotEmpty) {
        selectedId = exerciseList.first.key;
      }
    }

    final selectedExerciseName = selectedId != null ? performedExercises[selectedId] : null;

    // 2. Empty State View
    if (sessions.isEmpty || exerciseList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Analytics Yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Once you start logging and saving workout sessions with completed sets, your strength curves and progression charts will appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Process chronological sessions to build spots for the selected exercise
    final sortedSessions = List.of(sessions)..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final List<FlSpot> spots = [];
    final List<String> dates = [];
    double maxWeightOverall = 0.0;
    int sessionsCount = 0;
    double? lastWeight;
    double? previousWeight;

    for (final session in sortedSessions) {
      final ex = session.exercises.cast<WorkoutExercise?>().firstWhere(
            (e) => e?.exerciseId == selectedId,
            orElse: () => null,
          );
      if (ex != null) {
        final completedSets = ex.sets.where((s) => s.isCompleted);
        if (completedSets.isNotEmpty) {
          final maxWeightInSession = completedSets
              .map((s) => s.weightKg)
              .reduce((a, b) => a > b ? a : b);

          spots.add(FlSpot(sessionsCount.toDouble(), maxWeightInSession));
          dates.add(DateFormat('MM/dd').format(session.startedAt));

          if (maxWeightInSession > maxWeightOverall) {
            maxWeightOverall = maxWeightInSession;
          }

          previousWeight = lastWeight;
          lastWeight = maxWeightInSession;
          sessionsCount++;
        }
      }
    }

    // Determine strength trend (comparing last session to the second to last)
    String trendText = 'Stable';
    IconData trendIcon = Icons.trending_flat;
    Color trendColor = Colors.grey;
    if (lastWeight != null && previousWeight != null) {
      final difference = lastWeight - previousWeight;
      if (difference > 0) {
        trendText = '+${difference.toStringAsFixed(1)} kg';
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
      } else if (difference < 0) {
        trendText = '${difference.toStringAsFixed(1)} kg';
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
      }
    }

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Text(
            'Workout Analytics',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track your progression and strength curves over time.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),

          // Dropdown Selector
          DropdownButtonFormField<String>(
            value: selectedId,
            decoration: InputDecoration(
              labelText: 'Select Exercise',
              prefixIcon: const Icon(Icons.fitness_center_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: exerciseList.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedExerciseId = val;
              });
            },
          ),
          const SizedBox(height: 24),

          // Chart Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          selectedExerciseName ?? '',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Max Weight (kg)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (spots.isEmpty)
                    const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text('Not enough data points to plot yet.'),
                      ),
                    )
                  else
                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < dates.length) {
                                    return SideTitleWidget(
                                      meta: meta,
                                      space: 8,
                                      child: Text(
                                        dates[index],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return SideTitleWidget(
                                    meta: meta,
                                    child: Text(
                                      value.toStringAsFixed(0),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.surfaceContainerHigh,
                              tooltipBorder: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant,
                                width: 1,
                              ),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final index = spot.x.toInt();
                                  final dateStr = (index >= 0 && index < dates.length) ? dates[index] : '';
                                  return LineTooltipItem(
                                    '$dateStr\n${spot.y.toStringAsFixed(1)} kg',
                                    TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: primaryColor,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: primaryColor.withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Statistics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard(
                title: 'Personal Record',
                value: '${maxWeightOverall.toStringAsFixed(1)} kg',
                subtitle: 'All-time max',
                icon: Icons.star_rounded,
                iconColor: Colors.amber,
              ),
              _buildStatCard(
                title: 'Sessions Trained',
                value: '$sessionsCount',
                subtitle: 'Total frequency',
                icon: Icons.repeat_rounded,
                iconColor: Colors.blue,
              ),
              _buildStatCard(
                title: 'Last Lift',
                value: lastWeight != null ? '${lastWeight.toStringAsFixed(1)} kg' : 'N/A',
                subtitle: 'Most recent workout',
                icon: Icons.fitness_center_rounded,
                iconColor: Colors.purple,
              ),
              _buildStatCard(
                title: 'Strength Trend',
                value: trendText,
                subtitle: 'Compared to previous',
                icon: trendIcon,
                iconColor: trendColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: iconColor, size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
