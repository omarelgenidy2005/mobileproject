import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../workout/providers/exercise_provider.dart';

/// Admin-only screen for managing the global pre-defined exercise database.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  String _searchQuery = '';
  final List<String> _muscleGroups = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Other'
  ];

  void _showAddExerciseDialog(BuildContext context, ExerciseProvider provider) {
    String name = '';
    String muscleGroup = _muscleGroups.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Global Exercise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g. Hack Squat',
                ),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: muscleGroup,
                items: _muscleGroups
                    .map((mg) => DropdownMenuItem(value: mg, child: Text(mg)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      muscleGroup = val;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Muscle Group',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (name.trim().isEmpty) return;
                provider.addPredefinedExercise(
                  name: name.trim(),
                  muscleGroup: muscleGroup,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"${name.trim()}" added to global exercises.')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExerciseProvider provider, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exercise?'),
        content: Text('Are you sure you want to delete "$name" globally? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.deleteExercise(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"$name" has been deleted.')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    // Filter predefined (non-custom) exercises by search query
    final predefinedExercises = provider.exercises.where((e) {
      final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch && !e.isCustom;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync with Firestore',
            onPressed: () => provider.fetchRemoteExercises(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search global database...',
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          Expanded(
            child: predefinedExercises.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.storage_rounded,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No predefined exercises found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Search returned zero results, or the global database is empty.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: predefinedExercises.length,
                    itemBuilder: (context, index) {
                      final ex = predefinedExercises[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                          child: const Icon(Icons.fitness_center_rounded, size: 20),
                        ),
                        title: Text(ex.name),
                        subtitle: Text(ex.muscleGroup),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Delete exercise',
                          onPressed: () => _confirmDelete(context, provider, ex.id, ex.name),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExerciseDialog(context, provider),
        icon: const Icon(Icons.add),
        label: const Text('Add Exercise'),
      ),
    );
  }
}
