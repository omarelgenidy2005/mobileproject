/// Application roles enforced via Firestore `users/{uid}.role`.
enum UserRole {
  /// Can log workouts, view history, and manage personal data.
  regular('regular'),

  /// Can manage the global pre-defined exercise database.
  admin('admin');

  const UserRole(this.firestoreValue);

  final String firestoreValue;

  static UserRole fromFirestore(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.firestoreValue == value,
      orElse: () => UserRole.regular,
    );
  }

  bool get isAdmin => this == UserRole.admin;
}
