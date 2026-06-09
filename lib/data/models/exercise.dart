import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Represents a predefined or custom exercise definition.
class Exercise extends Equatable {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.isCustom = false,
    this.userId,
  });

  final String id;
  final String name;
  final String muscleGroup;
  final bool isCustom;
  final String? userId;

  factory Exercise.create({
    required String name,
    required String muscleGroup,
    bool isCustom = false,
    String? userId,
  }) {
    return Exercise(
      id: const Uuid().v4(),
      name: name,
      muscleGroup: muscleGroup,
      isCustom: isCustom,
      userId: userId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'muscleGroup': muscleGroup,
        'isCustom': isCustom,
        if (userId != null) 'userId': userId,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      muscleGroup: json['muscleGroup'] as String? ?? 'Other',
      isCustom: json['isCustom'] as bool? ?? false,
      userId: json['userId'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, muscleGroup, isCustom, userId];
}
