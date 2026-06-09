import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'user_role.dart';

/// Domain user model combining Firebase Auth identity with Firestore profile data.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role.isAdmin;

  /// Builds from Firebase Auth user + optional Firestore profile document.
  factory AppUser.fromFirebase({
    required fb.User authUser,
    Map<String, dynamic>? profile,
  }) {
    return AppUser(
      id: authUser.uid,
      email: authUser.email ?? '',
      displayName: profile?['displayName'] as String? ?? authUser.displayName,
      photoUrl: profile?['photoUrl'] as String? ?? authUser.photoURL,
      role: UserRole.fromFirestore(profile?['role'] as String?),
      createdAt: _parseTimestamp(profile?['createdAt']),
      updatedAt: _parseTimestamp(profile?['updatedAt']),
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      role: UserRole.fromFirestore(data['role'] as String?),
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.firestoreValue,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    UserRole? role,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  @override
  List<Object?> get props => [id, email, displayName, photoUrl, role, createdAt, updatedAt];
}
