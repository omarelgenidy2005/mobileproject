import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/errors/error_handler.dart';
import '../../../data/models/active_workout_session.dart';
import '../../../data/models/workout_exercise.dart';
import '../../../data/models/workout_set.dart';
import '../../history/providers/history_provider.dart';
import '../providers/active_workout_provider.dart';
import '../services/ai_prediction_service.dart';
import '../providers/exercise_provider.dart';

class ActiveWorkoutScreen extends StatelessWidget {
  const ActiveWorkoutScreen({super.key});

  void _showStartWorkoutDialog(BuildContext context, ActiveWorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => _StartWorkoutDialog(
        onStart: (title, date) {
          provider.startWorkout(title: title, startedAt: date);
        },
      ),
    );
  }

  void _showEditWorkoutDialog(BuildContext context, ActiveWorkoutProvider provider) {
    final session = provider.session;
    if (session == null) return;
    showDialog(
      context: context,
      builder: (ctx) => _EditWorkoutDialog(
        initialTitle: session.title,
        initialDate: session.startedAt,
        onSave: (title, date) {
          provider.updateWorkoutDetails(title: title, startedAt: date);
        },
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context, ActiveWorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => _AddExerciseDialog(
        onSelect: (id, name, muscleGroup) {
          provider.addExercise(exerciseId: id, name: name, muscleGroup: muscleGroup);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActiveWorkoutProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!provider.hasActiveSession) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'Ready to train?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Log your exercises, sets, weights and reps to achieve progressive overload.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _showStartWorkoutDialog(context, provider),
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text('Start Workout Session'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final session = provider.session!;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Edit name & date',
                            onPressed: () => _showEditWorkoutDialog(context, provider),
                          ),
                        ],
                      ),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy').format(session.startedAt),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${session.totalVolumeKg.toStringAsFixed(0)} kg',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'total volume',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: 'Take / Pick Photo',
                  onPressed: () async {
                    final picker = ImagePicker();
                    final source = await showModalBottomSheet<ImageSource>(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Take Photo'),
                              onTap: () => Navigator.pop(ctx, ImageSource.camera),
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Choose from Gallery'),
                              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                            ),
                            if (session.photoPath != null)
                              ListTile(
                                leading: const Icon(Icons.delete, color: Colors.red),
                                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                                onTap: () => Navigator.pop(ctx, null),
                              ),
                          ],
                        ),
                      ),
                    );
                    if (!context.mounted) return;
                    if (source == null && session.photoPath != null) {
                      // User chose "Remove Photo"
                      try {
                        final oldFile = File(session.photoPath!);
                        if (await oldFile.exists()) {
                          await oldFile.delete();
                        }
                      } catch (e) {
                        debugPrint('Error deleting photo: $e');
                      }
                      await provider.setPhoto(null);
                      return;
                    }
                    if (source == null) return;
                    final XFile? file = await picker.pickImage(
                      source: source,
                      imageQuality: 80,
                    );
                    if (file != null && context.mounted) {
                      try {
                        final appDir = await getApplicationDocumentsDirectory();
                        final fileName = 'workout_${session.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        final permanentPath = p.join(appDir.path, fileName);
                        
                        // Delete old photo file if exists to prevent leaks
                        if (session.photoPath != null && session.photoPath!.isNotEmpty) {
                          final oldFile = File(session.photoPath!);
                          if (await oldFile.exists()) {
                            await oldFile.delete();
                          }
                        }
                        
                        final File localImage = await File(file.path).copy(permanentPath);
                        await provider.setPhoto(localImage.path);
                      } catch (e) {
                        debugPrint('Error saving photo: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to save photo: $e')),
                          );
                        }
                      }
                    }
                  },
                  icon: Icon(
                    session.photoPath != null ? Icons.photo : Icons.camera_alt_outlined,
                    color: session.photoPath != null ? Colors.green : null,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: session.photoPath != null
                        ? Colors.green.withValues(alpha: 0.15)
                        : null,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  tooltip: 'Finish & Save',
                  onPressed: () => provider.endWorkout(),
                  icon: const Icon(Icons.check_rounded, color: Colors.green),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
          if (session.photoPath != null && session.photoPath!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Remove Photo',
                        onPressed: () async {
                          try {
                            final oldFile = File(session.photoPath!);
                            if (await oldFile.exists()) {
                              await oldFile.delete();
                            }
                          } catch (e) {
                            debugPrint('Error deleting photo: $e');
                          }
                          await provider.setPhoto(null);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.exercises.length,
              itemBuilder: (context, exerciseIndex) {
                final exercise = provider.exercises[exerciseIndex];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (exercise.muscleGroup != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    exercise.muscleGroup!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                          tooltip: 'Remove exercise',
                          onPressed: () => provider.removeExercise(exercise.id),
                        ),
                      ],
                    ),
                    children: [
                      if (exercise.sets.isNotEmpty) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 36,
                                child: Text(
                                  'Set',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'Weight (kg)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'Reps',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 50,
                                child: Center(
                                  child: Text(
                                    'Done',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                      for (int i = 0; i < exercise.sets.length; i++)
                        WorkoutSetRow(
                          key: ValueKey(exercise.sets[i].id),
                          exerciseId: exercise.id,
                          set: exercise.sets[i],
                          index: i,
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Builder(
                              builder: (context) {
                                final historyProvider = context.read<HistoryProvider>();
                                final prediction = AiPredictionService.predictNextSet(exercise.exerciseId, historyProvider);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.auto_awesome, size: 16, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'AI Suggests: ${prediction.weightKg}kg for ${prediction.reps} reps\n${prediction.reasoning}',
                                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimaryContainer),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    // Smart overload UX: copy previous set values if available, else use AI prediction
                                    final lastSet = exercise.sets.isNotEmpty ? exercise.sets.last : null;
                                    final historyProvider = context.read<HistoryProvider>();
                                    final prediction = AiPredictionService.predictNextSet(exercise.exerciseId, historyProvider);
                                    provider.addSet(
                                      exercise.id,
                                      weightKg: lastSet?.weightKg ?? prediction.weightKg,
                                      reps: lastSet?.reps ?? prediction.reps,
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Set'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _showAddExerciseDialog(context, provider),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Exercise to Workout'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A custom editable row for sets weight, reps and completion state.
class WorkoutSetRow extends StatefulWidget {
  final String exerciseId;
  final WorkoutSet set;
  final int index;

  const WorkoutSetRow({
    required super.key,
    required this.exerciseId,
    required this.set,
    required this.index,
  });

  @override
  State<WorkoutSetRow> createState() => _WorkoutSetRowState();
}

class _WorkoutSetRowState extends State<WorkoutSetRow> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;
  late final FocusNode _weightFocus;
  late final FocusNode _repsFocus;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListeningWeight = false;
  bool _isListeningReps = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set.weightKg > 0 ? widget.set.weightKg.toString() : '',
    );
    _repsController = TextEditingController(
      text: widget.set.reps > 0 ? widget.set.reps.toString() : '',
    );
    _weightFocus = FocusNode();
    _repsFocus = FocusNode();

    _weightFocus.addListener(_onFocusChange);
    _repsFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    // Save changes when losing focus
    if (!_weightFocus.hasFocus) {
      _saveWeight();
    }
    if (!_repsFocus.hasFocus) {
      _saveReps();
    }
  }

  void _saveWeight() {
    final parsed = double.tryParse(_weightController.text) ?? 0.0;
    if (parsed != widget.set.weightKg) {
      context.read<ActiveWorkoutProvider>().updateSet(
            exerciseId: widget.exerciseId,
            setId: widget.set.id,
            weightKg: parsed,
          );
    }
  }

  void _saveReps() {
    final parsed = int.tryParse(_repsController.text) ?? 0;
    if (parsed != widget.set.reps) {
      context.read<ActiveWorkoutProvider>().updateSet(
            exerciseId: widget.exerciseId,
            setId: widget.set.id,
            reps: parsed,
          );
    }
  }

  void _listenForWeight() async {
    if (!_isListeningWeight) {
      bool available = await _speech.initialize(
        onError: (val) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mic Error: ${val.errorMsg}')));
          }
          setState(() => _isListeningWeight = false);
        },
      );
      if (available) {
        setState(() => _isListeningWeight = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _weightController.text = _parseNumberWord(result.recognizedWords);
            });
            if (result.finalResult) {
              setState(() => _isListeningWeight = false);
              _saveWeight();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Heard weight: "${result.recognizedWords}"')));
              }
            }
          },
        );
      }
    } else {
      setState(() => _isListeningWeight = false);
      _speech.stop();
      _saveWeight();
    }
  }

  void _listenForReps() async {
    if (!_isListeningReps) {
      bool available = await _speech.initialize(
        onError: (val) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mic Error: ${val.errorMsg}')));
          }
          setState(() => _isListeningReps = false);
        },
      );
      if (available) {
        setState(() => _isListeningReps = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _repsController.text = _parseNumberWord(result.recognizedWords);
            });
            if (result.finalResult) {
              setState(() => _isListeningReps = false);
              _saveReps();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Heard reps: "${result.recognizedWords}"')));
              }
            }
          },
        );
      }
    } else {
      setState(() => _isListeningReps = false);
      _speech.stop();
      _saveReps();
    }
  }

  String _parseNumberWord(String word) {
    final map = {
      'one': '1', 'two': '2', 'to': '2', 'too': '2', 'three': '3', 'tree': '3', 'four': '4', 'for': '4', 'five': '5',
      'six': '6', 'seven': '7', 'eight': '8', 'ate': '8', 'nine': '9', 'ten': '10',
      'eleven': '11', 'twelve': '12', 'twenty': '20', 'thirty': '30'
    };
    final w = word.toLowerCase().trim();
    return map[w] ?? w;
  }

  @override
  void didUpdateWidget(covariant WorkoutSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.set.weightKg != oldWidget.set.weightKg && !_weightFocus.hasFocus) {
      _weightController.text = widget.set.weightKg > 0 ? widget.set.weightKg.toString() : '';
    }
    if (widget.set.reps != oldWidget.set.reps && !_repsFocus.hasFocus) {
      _repsController.text = widget.set.reps > 0 ? widget.set.reps.toString() : '';
    }
  }

  @override
  void dispose() {
    _weightFocus.removeListener(_onFocusChange);
    _repsFocus.removeListener(_onFocusChange);
    _weightController.dispose();
    _repsController.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ActiveWorkoutProvider>();
    final isCompleted = widget.set.isCompleted;

    return Container(
      color: isCompleted
          ? Colors.green.withValues(alpha: 0.05)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Set index
          SizedBox(
            width: 36,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: isCompleted
                  ? Colors.green.withValues(alpha: 0.2)
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
              child: Text(
                '${widget.index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? Colors.green[700]
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          // Weight input
          Expanded(
            child: Center(
              child: SizedBox(
                width: 90,
                height: 36,
                child: TextField(
                  controller: _weightController,
                  focusNode: _weightFocus,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: isCompleted
                        ? Colors.green.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText: '0',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: IconButton(
                      icon: Icon(
                        _isListeningWeight ? Icons.mic : Icons.mic_none,
                        size: 16,
                        color: _isListeningWeight ? Colors.red : Colors.grey,
                      ),
                      onPressed: _listenForWeight,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  onChanged: (val) {
                      final d = double.tryParse(val) ?? 0.0;
                      if (d < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Weight must be a positive number.')),
                        );
                        return;
                      }
                      provider.updateSet(
                        exerciseId: widget.exerciseId,
                        setId: widget.set.id,
                        weightKg: d,
                      );
                    }
                ),
              ),
            ),
          ),
          // Reps input
          Expanded(
            child: Center(
              child: SizedBox(
                width: 80,
                height: 36,
                child: TextField(
                  controller: _repsController,
                  focusNode: _repsFocus,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: isCompleted
                        ? Colors.green.withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText: '0',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: IconButton(
                      icon: Icon(
                        _isListeningReps ? Icons.mic : Icons.mic_none,
                        size: 16,
                        color: _isListeningReps ? Colors.red : Colors.grey,
                      ),
                      onPressed: _listenForReps,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  onChanged: (val) {
                    final r = int.tryParse(val) ?? 0;
                    if (r <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reps must be a positive integer.')),
                      );
                      return;
                    }
                    provider.updateSet(
                      exerciseId: widget.exerciseId,
                      setId: widget.set.id,
                      reps: r,
                    );
                  }
                ),
              ),
            ),
          ),
          // Done/Checkbox Toggle
          SizedBox(
            width: 50,
            child: Center(
              child: InkWell(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  try {
                    provider.updateSet(
                      exerciseId: widget.exerciseId,
                      setId: widget.set.id,
                      isCompleted: !isCompleted,
                    );
                  } catch (e, st) {
                    ErrorHandler.handle(context, e, stackTrace: st);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green
                        : Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: isCompleted
                        ? null
                        : Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1.5,
                          ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ),
          ),
          // Delete action
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
              onPressed: () {
                provider.removeSet(
                  exerciseId: widget.exerciseId,
                  setId: widget.set.id,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog to prompt workout session details on start.
class _StartWorkoutDialog extends StatefulWidget {
  final Function(String title, DateTime date) onStart;

  const _StartWorkoutDialog({required this.onStart});

  @override
  State<_StartWorkoutDialog> createState() => _StartWorkoutDialogState();
}

class _StartWorkoutDialogState extends State<_StartWorkoutDialog> {
  late final TextEditingController _titleController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'Workout');
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start New Workout'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Workout Name',
              hintText: 'e.g. Legs, Chest & Back',
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_rounded),
            title: const Text('Date'),
            subtitle: Text(DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)),
            trailing: TextButton(
              onPressed: _pickDate,
              child: const Text('Change'),
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
            widget.onStart(
              _titleController.text.trim().isEmpty ? 'Workout' : _titleController.text.trim(),
              _selectedDate,
            );
            Navigator.pop(context);
          },
          child: const Text('Start'),
        ),
      ],
    );
  }
}

/// Dialog to edit active workout details.
class _EditWorkoutDialog extends StatefulWidget {
  final String initialTitle;
  final DateTime initialDate;
  final Function(String title, DateTime date) onSave;

  const _EditWorkoutDialog({
    required this.initialTitle,
    required this.initialDate,
    required this.onSave,
  });

  @override
  State<_EditWorkoutDialog> createState() => _EditWorkoutDialogState();
}

class _EditWorkoutDialogState extends State<_EditWorkoutDialog> {
  late final TextEditingController _titleController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Workout Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Workout Name',
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_rounded),
            title: const Text('Date'),
            subtitle: Text(DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)),
            trailing: TextButton(
              onPressed: _pickDate,
              child: const Text('Change'),
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
            widget.onSave(
              _titleController.text.trim().isEmpty ? 'Workout' : _titleController.text.trim(),
              _selectedDate,
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Dialog to search, filter and choose an exercise, or add a custom one.
class _AddExerciseDialog extends StatefulWidget {
  final Function(String id, String name, String muscleGroup) onSelect;

  const _AddExerciseDialog({required this.onSelect});

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String _selectedMuscleGroup = 'All';

  final List<String> _muscleGroups = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateCustomExerciseFlow(String customName) {
    String muscleGroup = 'Chest';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Custom Exercise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: "$customName"'),
              const SizedBox(height: 16),
              const Text('Select Muscle Group:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: muscleGroup,
                items: _muscleGroups
                    .where((mg) => mg != 'All')
                    .map((mg) => DropdownMenuItem(value: mg, child: Text(mg)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      muscleGroup = val;
                    });
                  }
                },
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                // Add custom exercise
                final exerciseProvider = context.read<ExerciseProvider>();
                await exerciseProvider.addCustomExercise(name: customName, muscleGroup: muscleGroup);
                final newEx = exerciseProvider.exercises.firstWhere((e) => e.name == customName);
                widget.onSelect(newEx.id, newEx.name, newEx.muscleGroup);
                Navigator.pop(ctx); // Close custom dialog
                Navigator.pop(this.context); // Close parent add dialog
              },
              child: const Text('Create & Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = context.watch<ExerciseProvider>();
    final allExercises = exerciseProvider.exercises;

    final filtered = allExercises.where((ex) {
      final matchesSearch = ex.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMuscle = _selectedMuscleGroup == 'All' || ex.muscleGroup == _selectedMuscleGroup;
      return matchesSearch && matchesMuscle;
    }).toList();

    final exactMatch = allExercises.any((e) => e.name.toLowerCase() == _searchQuery.trim().toLowerCase());

    return AlertDialog(
      title: const Text('Add Exercise'),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 12),
            // Muscle group filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _muscleGroups.map((mg) {
                  final isSelected = _selectedMuscleGroup == mg;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(mg, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedMuscleGroup = mg;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(
                            'No exercises found.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, index) {
                        final ex = filtered[index];
                        return ListTile(
                          title: Text(ex.name),
                          subtitle: Text(ex.muscleGroup),
                          trailing: ex.isCustom
                              ? const Icon(Icons.person_outline_rounded, size: 18, color: Colors.grey)
                              : null,
                          onTap: () {
                            widget.onSelect(ex.id, ex.name, ex.muscleGroup);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        if (_searchQuery.trim().isNotEmpty && !exactMatch)
          TextButton.icon(
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text('Custom "${_searchQuery.trim()}"'),
            onPressed: () => _showCreateCustomExerciseFlow(_searchQuery.trim()),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

