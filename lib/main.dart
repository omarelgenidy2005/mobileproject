import 'package:cloud_firestore/cloud_firestore.dart';
import 'features/history/providers/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/config/firebase_initializer.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/hive_service.dart';
import 'core/services/sync_queue_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/workout/providers/active_workout_provider.dart';
import 'features/workout/providers/exercise_provider.dart';

import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseReady = await FirebaseInitializer.initialize();
  await HiveService.initialize();
  await NotificationService.initialize();

  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  final syncQueueService =
      firebaseReady ? SyncQueueService(connectivity: connectivityService) : null;
  if (syncQueueService != null) {
    connectivityService.onOnlineChanged.listen((online) {
      if (online) syncQueueService.flush();
    });
  }

  final historyProvider = HistoryProvider();
  await historyProvider.initialize();
  final activeWorkoutProvider = ActiveWorkoutProvider(historyProvider: historyProvider);
  await activeWorkoutProvider.initialize();
  final exerciseProvider = ExerciseProvider(
    firestore: firebaseReady ? FirebaseFirestore.instance : null,
    syncQueue: syncQueueService,
    firebaseEnabled: firebaseReady,
  );
  await exerciseProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(firebaseEnabled: firebaseReady),
        ),
        ChangeNotifierProvider<HistoryProvider>.value(value: historyProvider),
        ChangeNotifierProvider<ActiveWorkoutProvider>.value(value: activeWorkoutProvider),
        ChangeNotifierProvider<ExerciseProvider>.value(value: exerciseProvider),
        Provider<ConnectivityService>.value(value: connectivityService),
        if (syncQueueService != null)
          Provider<SyncQueueService>.value(value: syncQueueService),
      ],
      child: const ThreeAshApp(),
    ),
  );
}
