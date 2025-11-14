import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Entrada del diario con respuestas a preguntas guiadas y nota final.
class JournalEntry {
  JournalEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.dayColor,
    required this.energyLevel,
    required this.gratitude,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? date,
       updatedAt = updatedAt ?? date;

  final String id;
  final DateTime date;
  final String mood; // "excelente", "bueno", "regular", "difícil"
  final String dayColor; // color elegido para el día
  final String energyLevel; // "alta", "media", "baja"
  final String gratitude; // texto de gratitud
  final String? note; // nota libre opcional
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'dayColor': dayColor,
      'energyLevel': energyLevel,
      'gratitude': gratitude,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      mood: map['mood'] as String? ?? '',
      dayColor: map['dayColor'] as String? ?? '',
      energyLevel: map['energyLevel'] as String? ?? '',
      gratitude: map['gratitude'] as String? ?? '',
      note: map['note'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Convierte el string de color a Color object.
  Color? get dayColorValue {
    if (dayColor.isEmpty) return null;
    try {
      final hex = dayColor.startsWith('#') ? dayColor.substring(1) : dayColor;
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return null;
    }
  }

  static JournalEntry create({
    required DateTime date,
    String? mood,
    String? dayColor,
    String? energyLevel,
    String? gratitude,
    String? note,
  }) {
    final timestamp = DateTime.now();
    return JournalEntry(
      id: _uuid.v4(),
      date: date,
      mood: mood ?? '',
      dayColor: dayColor ?? '',
      energyLevel: energyLevel ?? '',
      gratitude: gratitude ?? '',
      note: note,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }
}
