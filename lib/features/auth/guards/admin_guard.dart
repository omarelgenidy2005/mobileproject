// lib/features/auth/guards/admin_guard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// A widget that restricts access to its [child] to admin users only.
/// If the current user is not an admin, an access‑denied page is shown.
class AdminGuard extends StatelessWidget {
  const AdminGuard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.isAdmin) {
      return child;
    }
    // Simple access‑denied UI – can be customized later.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
      ),
      body: const Center(
        child: Text('You do not have permission to view this page.'),
      ),
    );
  }
}
