import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.fingerprint),
            title: Text('Biometric App Lock'),
            subtitle: Text('Face ID / fingerprint after 30s in background'),
          ),
          ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Push & Rest Timers'),
            subtitle: Text('FCM alerts and local rest-interval notifications'),
          ),
          ListTile(
            leading: Icon(Icons.camera_alt_outlined),
            title: Text('Progress Photos'),
            subtitle: Text('Camera integration for profile progress snaps'),
          ),
        ],
      ),
    );
  }
}
