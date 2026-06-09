import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker_3ash/app.dart';
import 'package:workout_tracker_3ash/features/auth/providers/auth_provider.dart';
import 'package:workout_tracker_3ash/features/workout/providers/active_workout_provider.dart';
import 'package:workout_tracker_3ash/features/workout/providers/exercise_provider.dart';

void main() {
  testWidgets('3ash app renders login when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(firebaseEnabled: false)),
          ChangeNotifierProvider(create: (_) => ActiveWorkoutProvider()),
          ChangeNotifierProvider(create: (_) => ExerciseProvider(firebaseEnabled: false)..initialize()),
        ],
        child: const ThreeAshApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to 3ash'), findsOneWidget);
  });
}
