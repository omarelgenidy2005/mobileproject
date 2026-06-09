import 'package:flutter/material.dart';

class CustomExercisesScreen extends StatelessWidget {
  const CustomExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Exercises')),
      body: const Center(
        child: Text('Personal exercise library — stored locally and synced to Firestore'),
      ),
    );
  }
}
