import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Representa una tarea dentro de una rutina diaria.
class RoutineTask {
  RoutineTask({
    required this.id,
    required this.title,
    this.description,
    this.isOptional = false,
    this.reminderTime,
  });

  final String id;
  final String title;
  final String? description;
  final bool isOptional;
  final TimeOfDay? reminderTime;

  RoutineTask copyWith({
    String? id,
    String? title,
    String? description,
    bool? isOptional,
    TimeOfDay? reminderTime,
    bool removeReminderTime = false,
  }) {
    return RoutineTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isOptional: isOptional ?? this.isOptional,
      reminderTime: removeReminderTime ? null : (reminderTime ?? this.reminderTime),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'isOptional': isOptional,
      'reminderHour': reminderTime?.hour,
      'reminderMinute': reminderTime?.minute,
    };
  }

  factory RoutineTask.fromMap(Map<String, dynamic> map) {
    TimeOfDay? reminder;
    if (map['reminderHour'] != null && map['reminderMinute'] != null) {
      reminder = TimeOfDay(
        hour: map['reminderHour'] as int,
        minute: map['reminderMinute'] as int,
      );
    }
    return RoutineTask(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isOptional: (map['isOptional'] as bool?) ?? false,
      reminderTime: reminder,
    );
  }

  static RoutineTask create({
    required String title,
    String? description,
    bool isOptional = false,
    TimeOfDay? reminderTime,
  }) {
    return RoutineTask(
      id: const Uuid().v4(),
      title: title,
      description: description,
      isOptional: isOptional,
      reminderTime: reminderTime,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RoutineTask &&
            other.id == id &&
            other.title == title &&
            other.description == description &&
            other.isOptional == isOptional &&
            other.reminderTime?.hour == reminderTime?.hour &&
            other.reminderTime?.minute == reminderTime?.minute);
  }

  @override
  int get hashCode => Object.hash(id, title, description, isOptional, reminderTime?.hour, reminderTime?.minute);

  static bool listEquals(List<RoutineTask> a, List<RoutineTask> b) {
    return const ListEquality<RoutineTask>().equals(a, b);
  }
}
