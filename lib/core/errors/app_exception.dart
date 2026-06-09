import 'package:equatable/equatable.dart';

/// Typed application errors surfaced to the global error handler.
sealed class AppException extends Equatable implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];

  @override
  String toString() => '$runtimeType: $message';
}

/// Network unavailable or request timed out.
final class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection. Changes will sync when online.']);
}

/// Firestore read/write or sync queue failure.
final class DatabaseException extends AppException {
  const DatabaseException([super.message = 'Could not sync with the cloud database.']);
}

/// Firebase Auth or role validation failure.
final class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed. Please sign in again.']);
}

/// Form / business-rule validation failure.
final class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Biometric lock or local_auth failure.
final class SecurityException extends AppException {
  const SecurityException([super.message = 'Biometric authentication failed.']);
}

/// Catch-all for unexpected failures.
final class UnknownException extends AppException {
  const UnknownException([super.message = 'Something went wrong. Please try again.']);
}
