import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Bootstraps Firebase. Run `flutterfire configure` to generate [DefaultFirebaseOptions].
abstract final class FirebaseInitializer {
  static bool _isReady = false;

  /// Whether [Firebase.initializeApp] succeeded (required for Auth/Firestore on web).
  static bool get isReady => _isReady;

  /// Returns `true` when Firebase is usable; `false` in debug if not configured yet.
  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isReady = true;
      debugPrint('FirebaseInitializer: Firebase initialized.');
      return true;
    } catch (e, st) {
      _isReady = false;
      debugPrint('FirebaseInitializer: skipped or failed — $e');
      debugPrintStack(stackTrace: st);
      if (kReleaseMode) rethrow;
      return false;
    }
  }
}
