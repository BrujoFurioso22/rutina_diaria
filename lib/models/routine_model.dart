import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'task_model.dart';

const _uuid = Uuid();

/// Describe la configuración completa de una rutina personalizada.
class Routine {
  Routine({
    required this.id,
    required this.name,
    required this.tasks,
    this.colorHex = 0xFFC8B6FF,
    this.iconName = 'sunny',
    this.reminderTime,
    this.reminderWeekdays = const [],
    this.reminderDate,
    this.lastCompleted,
    this.completedCount = 0,
    this.presetKey,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final List<RoutineTask> tasks;
  final int colorHex;
  final String iconName;
  final TimeOfDay? reminderTime;
  final List<int> reminderWeekdays;
  final DateTime? reminderDate;
  final DateTime? lastCompleted;
  final int completedCount;
  final String? presetKey;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Routine copyWith({
    String? id,
    String? name,
    List<RoutineTask>? tasks,
    int? colorHex,
    String? iconName,
    TimeOfDay? reminderTime,
    List<int>? reminderWeekdays,
    DateTime? reminderDate,
    bool removeReminderTime = false,
    bool removeReminderWeekdays = false,
    bool removeReminderDate = false,
    DateTime? lastCompleted,
    int? completedCount,
    String? presetKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final resolvedReminderTime = removeReminderTime
        ? null
        : reminderTime ?? this.reminderTime;
    final resolvedReminderWeekdays = removeReminderWeekdays
        ? <int>[]
        : reminderWeekdays ?? this.reminderWeekdays;
    final resolvedReminderDate = removeReminderDate
        ? null
        : reminderDate ?? this.reminderDate;
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      tasks: tasks ?? this.tasks,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      reminderTime: resolvedReminderTime,
      reminderWeekdays: resolvedReminderWeekdays,
      reminderDate: resolvedReminderDate,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      completedCount: completedCount ?? this.completedCount,
      presetKey: presetKey ?? this.presetKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'tasks': tasks.map((task) => task.toMap()).toList(),
      'colorHex': colorHex,
      'iconName': iconName,
      'reminderHour': reminderTime?.hour,
      'reminderMinute': reminderTime?.minute,
      'reminderWeekdays': reminderWeekdays,
      'reminderDate': reminderDate?.toIso8601String(),
      'lastCompleted': lastCompleted?.toIso8601String(),
      'completedCount': completedCount,
      'presetKey': presetKey,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map) {
    TimeOfDay? reminder;
    if (map['reminderHour'] != null && map['reminderMinute'] != null) {
      reminder = TimeOfDay(
        hour: map['reminderHour'] as int,
        minute: map['reminderMinute'] as int,
      );
    }
    return Routine(
      id: map['id'] as String,
      name: map['name'] as String,
      tasks: (map['tasks'] as List<dynamic>)
          .map((task) => RoutineTask.fromMap(task as Map<String, dynamic>))
          .toList(),
      colorHex: map['colorHex'] as int? ?? 0xFFC8B6FF,
      iconName: map['iconName'] as String? ?? 'sunny',
      reminderTime: reminder,
      reminderWeekdays:
          (map['reminderWeekdays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
      reminderDate: map['reminderDate'] != null
          ? DateTime.parse(map['reminderDate'] as String)
          : null,
      lastCompleted: map['lastCompleted'] != null
          ? DateTime.parse(map['lastCompleted'] as String)
          : null,
      completedCount: map['completedCount'] as int? ?? 0,
      presetKey: map['presetKey'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  static Routine create({
    required String name,
    required List<RoutineTask> tasks,
    int colorHex = 0xFFC8B6FF,
    String iconName = 'sunny',
    TimeOfDay? reminderTime,
    List<int> reminderWeekdays = const [],
    DateTime? reminderDate,
    String? presetKey,
  }) {
    final now = DateTime.now();
    return Routine(
      id: _uuid.v4(),
      name: name,
      tasks: tasks,
      colorHex: colorHex,
      iconName: iconName,
      reminderTime: reminderTime,
      reminderWeekdays: reminderWeekdays,
      reminderDate: reminderDate,
      presetKey: presetKey,
      createdAt: now,
      updatedAt: now,
    );
  }

  String get formattedReminder {
    if (reminderTime == null &&
        reminderDate == null &&
        reminderWeekdays.isEmpty) {
      return 'Sin recordatorio';
    }
    if (reminderWeekdays.isNotEmpty && reminderTime != null) {
      final buffer = reminderWeekdays
          .map((day) => _weekdayShortName(day))
          .where((name) => name.isNotEmpty)
          .join(', ');
      final date = DateTime(0, 1, 1, reminderTime!.hour, reminderTime!.minute);
      final formattedTime = DateFormat.Hm('es').format(date);
      return '$buffer • $formattedTime';
    }
    if (reminderWeekdays.isNotEmpty && reminderTime == null) {
      return reminderWeekdays
          .map((day) => _weekdayShortName(day))
          .where((name) => name.isNotEmpty)
          .join(', ');
    }
    if (reminderDate != null) {
      return DateFormat('d MMM • HH:mm', 'es').format(reminderDate!);
    }
    if (reminderTime != null) {
      final date = DateTime(0, 1, 1, reminderTime!.hour, reminderTime!.minute);
      return DateFormat.Hm().format(date);
    }
    return 'Sin recordatorio';
  }

  Color get color => Color(colorHex);
}

String _weekdayShortName(int weekday) {
  const names = <int, String>{
    DateTime.monday: 'Lun',
    DateTime.tuesday: 'Mar',
    DateTime.wednesday: 'Mié',
    DateTime.thursday: 'Jue',
    DateTime.friday: 'Vie',
    DateTime.saturday: 'Sáb',
    DateTime.sunday: 'Dom',
  };
  return names[weekday] ?? '';
}

/// Registro individual de finalización de rutinas.
class RoutineHistoryEntry {
  RoutineHistoryEntry({
    required this.id,
    required this.routineId,
    required this.completedAt,
    this.note,
    this.completedTaskIndices,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? completedAt,
       updatedAt = updatedAt ?? completedAt;

  final String id;
  final String routineId;
  final DateTime completedAt;
  final String? note;
  final List<int>? completedTaskIndices;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'routineId': routineId,
      'completedAt': completedAt.toIso8601String(),
      'note': note,
      'completedTaskIndices': completedTaskIndices,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RoutineHistoryEntry.fromMap(Map<String, dynamic> map) {
    return RoutineHistoryEntry(
      id: map['id'] as String,
      routineId: map['routineId'] as String,
      completedAt: DateTime.parse(map['completedAt'] as String),
      note: map['note'] as String?,
      completedTaskIndices: map['completedTaskIndices'] != null
          ? (map['completedTaskIndices'] as List<dynamic>)
                .map((e) => e as int)
                .toList()
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  static RoutineHistoryEntry create({
    required String routineId,
    DateTime? completedAt,
    String? note,
    List<int>? completedTaskIndices,
  }) {
    final timestamp = completedAt ?? DateTime.now();
    return RoutineHistoryEntry(
      id: _uuid.v4(),
      routineId: routineId,
      completedAt: timestamp,
      note: note,
      completedTaskIndices: completedTaskIndices,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }
}

/// Progreso guardado de una rutina en curso.
class RoutineProgress {
  RoutineProgress({
    required this.routineId,
    required this.completedTasks,
    required this.startedAt,
    DateTime? lastUpdatedAt,
  }) : lastUpdatedAt = lastUpdatedAt ?? startedAt;

  final String routineId;
  final Map<int, DateTime>
  completedTasks; // índice de tarea -> timestamp de completado
  final DateTime startedAt;
  final DateTime lastUpdatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'routineId': routineId,
      'completedTasks': completedTasks.map(
        (key, value) => MapEntry(key.toString(), value.toIso8601String()),
      ),
      'startedAt': startedAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    };
  }

  factory RoutineProgress.fromMap(Map<String, dynamic> map) {
    final completedTasksMap = <int, DateTime>{};
    if (map['completedTasks'] != null) {
      final tasks = map['completedTasks'] as Map<String, dynamic>;
      tasks.forEach((key, value) {
        final index = int.parse(key);
        completedTasksMap[index] = DateTime.parse(value as String);
      });
    }
    return RoutineProgress(
      routineId: map['routineId'] as String,
      completedTasks: completedTasksMap,
      startedAt: DateTime.parse(map['startedAt'] as String),
      lastUpdatedAt: map['lastUpdatedAt'] != null
          ? DateTime.parse(map['lastUpdatedAt'] as String)
          : null,
    );
  }

  static RoutineProgress create({
    required String routineId,
    Map<int, DateTime>? completedTasks,
    DateTime? startedAt,
  }) {
    final timestamp = startedAt ?? DateTime.now();
    return RoutineProgress(
      routineId: routineId,
      completedTasks: completedTasks ?? {},
      startedAt: timestamp,
    );
  }
}
