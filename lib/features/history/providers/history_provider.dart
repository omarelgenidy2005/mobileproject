import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/active_workout_session.dart';

class HistoryProvider extends ChangeNotifier {
  static const String _historyKey = 'workout_history';

  final List<ActiveWorkoutSession> _sessions = [];
  SharedPreferences? _prefs;
  String? _currentUserId;

  /// Sets the current user ID for filtering history.
  void setCurrentUser(String? uid) {
    _currentUserId = uid;
    notifyListeners();
  }

  /// Returns only sessions belonging to the current user (or all if no user).
  List<ActiveWorkoutSession> get sessions => List.unmodifiable(
        _sessions.where(
          (s) => _currentUserId == null || s.userId == _currentUserId,
        ),
      );

  /// Builds a card widget for a session with a delete button and optional photo.
  Widget buildSessionCard(
      BuildContext context, ActiveWorkoutSession session) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show photo if available
          if (session.photoPath != null && session.photoPath!.isNotEmpty)
            GestureDetector(
              onTap: () {
                // Show full-screen photo on tap
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    child: InteractiveViewer(
                      child: Image.file(
                        File(session.photoPath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
              child: SizedBox(
                width: double.infinity,
                height: 180,
                child: Image.file(
                  File(session.photoPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ListTile(
            title: Text(
              session.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Started: ${session.startedAt.toLocal().toString().split('.').first}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Volume: ${session.totalVolumeKg.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () =>
                  context.read<HistoryProvider>().deleteSession(session.id),
            ),
          ),
        ],
      ),
    );
  }

  /// Load persisted history from SharedPreferences.
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    final rawList = _prefs!.getStringList(_historyKey) ?? [];
    _sessions
      ..clear()
      ..addAll(
        rawList.map(
          (s) => ActiveWorkoutSession.fromJson(
              jsonDecode(s) as Map<String, dynamic>),
        ),
      );
    notifyListeners();
  }

  /// Add a completed session to history and persist it.
  Future<void> addSession(ActiveWorkoutSession session) async {
    _prefs ??= await SharedPreferences.getInstance();
    // Insert at the front for reverse-chronological order.
    _sessions.insert(0, session);
    final List<String> encoded =
        _sessions.map((s) => jsonEncode(s.toJson())).toList().cast<String>();
    await _prefs!.setStringList(_historyKey, encoded);
    notifyListeners();
  }

  /// Delete a session from history and persist the change.
  Future<void> deleteSession(String id) async {
    _prefs ??= await SharedPreferences.getInstance();
    
    // Find the session to clean up its photo file
    try {
      final sessionIndex = _sessions.indexWhere((s) => s.id == id);
      if (sessionIndex != -1) {
        final session = _sessions[sessionIndex];
        if (session.photoPath != null && session.photoPath!.isNotEmpty) {
          final file = File(session.photoPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting photo file during session deletion: $e');
    }

    _sessions.removeWhere((s) => s.id == id);
    final List<String> encoded =
        _sessions.map((s) => jsonEncode(s.toJson())).toList().cast<String>();
    await _prefs!.setStringList(_historyKey, encoded);
    notifyListeners();
  }
}
