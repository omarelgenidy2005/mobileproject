import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../history/providers/history_provider.dart';
import '../../../data/models/active_workout_session.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryProvider>(
      builder: (context, historyProvider, _) {
        final sessions = historyProvider.sessions;
        if (sessions.isEmpty) {
          return const Center(
            child: Text('No workout history yet.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return historyProvider.buildSessionCard(context, session);
          },
        );
      },
    );
  }
}
