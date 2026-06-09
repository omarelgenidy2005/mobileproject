import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_exception.dart';

/// Global error-handling layer: maps exceptions to user-facing snackbars/dialogs.
abstract final class ErrorHandler {
  /// Shows a floating snackbar for non-blocking errors.
  static void showSnackBar(BuildContext context, String message, {bool isError = true}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.primaryContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Shows a modal alert for critical failures (auth, security).
  static Future<void> showAlertDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'OK',
  }) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(confirmLabel)),
        ],
      ),
    );
  }

  /// Normalizes any thrown object into an [AppException] and displays UI feedback.
  static void handle(
    BuildContext context,
    Object error, {
  StackTrace? stackTrace,
    bool useDialog = false,
  }) {
    final appError = _mapToAppException(error);
    debugPrint('ErrorHandler: $appError');
    if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);

    if (useDialog || appError is AuthException || appError is SecurityException) {
      showAlertDialog(
        context,
        title: _titleFor(appError),
        message: appError.message,
      );
    } else {
      showSnackBar(context, appError.message);
    }
  }

  static AppException _mapToAppException(Object error) {
    if (error is AppException) return error;
    if (error is FirebaseAuthException) {
      return AuthException(error.message ?? 'Authentication error.');
    }
    final message = error.toString();
    if (message.contains('SocketException') || message.contains('Network')) {
      return const NetworkException();
    }
    return UnknownException(message);
  }

  static String _titleFor(AppException error) => switch (error) {
        AuthException() => 'Sign In Required',
        SecurityException() => 'Security',
        NetworkException() => 'Offline',
        DatabaseException() => 'Sync Error',
        ValidationException() => 'Invalid Input',
        UnknownException() => 'Error',
      };
}
