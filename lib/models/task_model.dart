import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

/// Representa una tarea dentro de una rutina diaria.
class RoutineTask {
  RoutineTask({
    required this.id,
    required this.title,
    this.description,
    this.isOptional = false,
  });

  final String id;
  final String title;
  final String? description;
  final bool isOptional;

  RoutineTask copyWith({
    String? id,
    String? title,
    String? description,
    bool? isOptional,
  }) {
    return RoutineTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isOptional: isOptional ?? this.isOptional,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'isOptional': isOptional,
    };
  }

  factory RoutineTask.fromMap(Map<String, dynamic> map) {
    return RoutineTask(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isOptional: (map['isOptional'] as bool?) ?? false,
    );
  }

  static RoutineTask create({
    required String title,
    String? description,
    bool isOptional = false,
  }) {
    return RoutineTask(
      id: const Uuid().v4(),
      title: title,
      description: description,
      isOptional: isOptional,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RoutineTask &&
            other.id == id &&
            other.title == title &&
            other.description == description &&
            other.isOptional == isOptional);
  }

  @override
  int get hashCode => Object.hash(id, title, description, isOptional);

  static bool listEquals(List<RoutineTask> a, List<RoutineTask> b) {
    return const ListEquality<RoutineTask>().equals(a, b);
  }
}
