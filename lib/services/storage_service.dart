import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/routine_model.dart';
import '../models/task_model.dart';
import '../models/journal_model.dart';
import '../utils/app_theme.dart';

const _routinesBoxName = 'routines_box';
const _historyBoxName = 'history_box';
const _settingsBoxName = 'settings_box';
const _progressBoxName = 'progress_box';
const _journalBoxName = 'journal_box';

/// Administra el almacenamiento local de rutinas, historial y ajustes.
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    try {
      await Hive.initFlutter();
      await Future.wait([
        Hive.openBox<Map>(_routinesBoxName),
        Hive.openBox<Map>(_historyBoxName),
        Hive.openBox(_settingsBoxName),
        Hive.openBox<Map>(_progressBoxName),
        Hive.openBox<Map>(_journalBoxName),
      ]);
      await _ensurePresetsSeeded();
      _initialized = true;
      debugPrint('[Storage] Inicialización completada');
    } catch (e, stackTrace) {
      debugPrint('[Storage] Error en inicialización: $e');
      debugPrint('[Storage] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Box<Map> get _routinesBox => Hive.box<Map>(_routinesBoxName);
  Box<Map> get _historyBox => Hive.box<Map>(_historyBoxName);
  Box get _settingsBox => Hive.box(_settingsBoxName);
  Box<Map> get _progressBox => Hive.box<Map>(_progressBoxName);
  Box<Map> get _journalBox => Hive.box<Map>(_journalBoxName);

  Future<List<Routine>> loadRoutines() async {
    try {
      final count = _routinesBox.length;
      debugPrint('[Storage] Cargando rutinas... Total en caja: $count');
      final routines =
          _routinesBox.values
              .map((entry) {
                try {
                  return Routine.fromMap(_mapFromHive(entry));
                } catch (e) {
                  debugPrint('[Storage] Error parseando rutina: $e');
                  return null;
                }
              })
              .whereType<Routine>()
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      debugPrint('[Storage] Rutinas cargadas: ${routines.length}');
      return routines;
    } catch (e, stackTrace) {
      debugPrint('[Storage] Error cargando rutinas: $e');
      debugPrint('[Storage] Stack trace: $stackTrace');
      return [];
    }
  }

  Future<void> saveRoutine(Routine routine) async {
    try {
      if (!_initialized) {
        debugPrint('[Storage] Error: Storage no inicializado');
        await init();
      }
      final map = routine.toMap();
      debugPrint('[Storage] Guardando rutina: ${routine.name}');
      debugPrint('[Storage] Mapa generado: ${map.keys.toList()}');
      await _routinesBox.put(routine.id, map);
      // Forzar escritura inmediata y verificar
      await _routinesBox.flush();
      // Verificar que se guardó
      final saved = _routinesBox.get(routine.id);
      if (saved == null) {
        debugPrint('[Storage] ERROR: La rutina no se guardó correctamente');
        // Intentar de nuevo
        await _routinesBox.put(routine.id, map);
        await _routinesBox.flush();
      } else {
        debugPrint(
          '[Storage] Rutina guardada y verificada: ${routine.name} (${routine.id})',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[Storage] Error guardando rutina: $e');
      debugPrint('[Storage] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteRoutine(String routineId) async {
    await _routinesBox.delete(routineId);
    final removable = _historyBox.values
        .where((entry) => entry['routineId'] == routineId)
        .map((entry) => entry['id'])
        .toList();
    for (final id in removable) {
      await _historyBox.delete(id);
    }
  }

  Future<void> reorderRoutines(List<Routine> routines) async {
    await _routinesBox.clear();
    for (final routine in routines) {
      await _routinesBox.put(routine.id, routine.toMap());
    }
  }

  Future<void> resetAll() async {
    await _notificationsCleanup();
    await _routinesBox.clear();
    await _historyBox.clear();
    await _settingsBox.clear();
    await _ensurePresetsSeeded();
  }

  Future<void> recordCompletion(RoutineHistoryEntry entry) async {
    try {
      await _historyBox.put(entry.id, entry.toMap());
      await _historyBox.flush();
      await _settingsBox.put(
        'lastCompletionDate',
        entry.completedAt.toIso8601String(),
      );
      await _settingsBox.flush();
      debugPrint('[Storage] Completación registrada: ${entry.id}');
    } catch (e) {
      debugPrint('[Storage] Error registrando completación: $e');
      rethrow;
    }
  }

  Future<List<RoutineHistoryEntry>> loadHistory() async {
    try {
      final count = _historyBox.length;
      debugPrint('[Storage] Cargando historial... Total en caja: $count');
      final entries =
          _historyBox.values
              .map((entry) {
                try {
                  return RoutineHistoryEntry.fromMap(_mapFromHive(entry));
                } catch (e) {
                  debugPrint(
                    '[Storage] Error parseando entrada de historial: $e',
                  );
                  return null;
                }
              })
              .whereType<RoutineHistoryEntry>()
              .toList()
            ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
      debugPrint('[Storage] Entradas de historial cargadas: ${entries.length}');
      return entries;
    } catch (e, stackTrace) {
      debugPrint('[Storage] Error cargando historial: $e');
      debugPrint('[Storage] Stack trace: $stackTrace');
      return [];
    }
  }

  Future<void> clearHistory() async {
    await _historyBox.clear();
  }

  Future<void> savePremium(bool isPremium) async {
    await _settingsBox.delete('isPremium');
  }

  bool isPremium() {
    return false;
  }

  DateTime? lastCompletionDate() {
    final value = _settingsBox.get('lastCompletionDate') as String?;
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Future<void> setDailyReminderTime(TimeOfDay time) async {
    await _settingsBox.put(
      'dailyReminder',
      jsonEncode({'hour': time.hour, 'minute': time.minute}),
    );
  }

  TimeOfDay dailyReminderTime() {
    final raw = _settingsBox.get('dailyReminder') as String?;
    if (raw == null) {
      return const TimeOfDay(hour: 19, minute: 0);
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return TimeOfDay(
      hour: decoded['hour'] as int,
      minute: decoded['minute'] as int,
    );
  }

  Future<void> setDisplayName(String? name) async {
    try {
      final trimmed = name?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        await _settingsBox.delete('displayName');
      } else {
        await _settingsBox.put('displayName', trimmed);
      }
      await _settingsBox.flush(); // Forzar escritura inmediata
      debugPrint('[Storage] Nombre guardado: $trimmed');
    } catch (e) {
      debugPrint('[Storage] Error guardando nombre: $e');
      rethrow;
    }
  }

  String? displayName() {
    final value = _settingsBox.get('displayName');
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return null;
  }

  Future<void> setBirthday(DateTime? date) async {
    try {
      if (date == null) {
        await _settingsBox.delete('birthday');
      } else {
        await _settingsBox.put('birthday', date.toIso8601String());
      }
      await _settingsBox.flush(); // Forzar escritura inmediata
      debugPrint('[Storage] Cumpleaños guardado: $date');
    } catch (e) {
      debugPrint('[Storage] Error guardando cumpleaños: $e');
      rethrow;
    }
  }

  DateTime? birthday() {
    final value = _settingsBox.get('birthday');
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<void> setVibrationEnabled(bool value) async {
    await _settingsBox.put('vibrationEnabled', value);
  }

  bool vibrationEnabled() {
    return (_settingsBox.get('vibrationEnabled') as bool?) ?? true;
  }

  Future<void> setThemePaletteId(String id) async {
    await _settingsBox.put('themePaletteId', id);
  }

  String themePaletteId() {
    return (_settingsBox.get('themePaletteId') as String?) ??
        AppTheme.defaultPaletteId;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _settingsBox.put('notificationsEnabled', value);
  }

  bool notificationsEnabled() {
    return (_settingsBox.get('notificationsEnabled') as bool?) ?? true;
  }

  Future<void> _ensurePresetsSeeded() async {
    try {
      final seeded = (_settingsBox.get('presetsSeeded') as bool?) ?? false;
      final currentRoutineCount = _routinesBox.length;

      debugPrint(
        '[Storage] Verificando presets... seeded: $seeded, rutinas actuales: $currentRoutineCount',
      );

      // Si ya está sembrado Y hay rutinas, no hacer nada
      if (seeded && currentRoutineCount > 0) {
        debugPrint(
          '[Storage] Presets ya sembrados y existen rutinas, omitiendo...',
        );
        return;
      }

      // Si está marcado como sembrado pero no hay rutinas, limpiar y volver a sembrar
      if (seeded && currentRoutineCount == 0) {
        debugPrint(
          '[Storage] Presets marcados como sembrados pero no hay rutinas, re-sembrando...',
        );
        await _routinesBox.clear();
        await _routinesBox.flush();
      }

      debugPrint('[Storage] Sembrando rutinas preseleccionadas...');
      final presets = _buildPresetRoutines();
      for (final preset in presets) {
        final map = preset.toMap();
        await _routinesBox.put(preset.id, map);
        debugPrint('[Storage] Preset guardado: ${preset.name} (${preset.id})');
      }
      await _routinesBox.flush(); // Forzar escritura inmediata

      // Verificar que se guardaron correctamente
      final savedCount = _routinesBox.length;
      debugPrint('[Storage] Rutinas guardadas en caja: $savedCount');

      await _settingsBox.put('presetsSeeded', true);
      await _settingsBox.flush(); // Forzar escritura inmediata
      debugPrint(
        '[Storage] Presets sembrados exitosamente: ${presets.length} rutinas',
      );
    } catch (e, stackTrace) {
      debugPrint('[Storage] Error sembrando presets: $e');
      debugPrint('[Storage] Stack trace: $stackTrace');
      rethrow;
    }
  }

  List<Routine> _buildPresetRoutines() {
    return [
      Routine.create(
        name: 'Rutina de mañana',
        presetKey: 'morning',
        iconName: 'sunny',
        colorHex: 0xFFC8B6FF,
        tasks: [
          RoutineTask.create(title: 'Hidratarse con un vaso de agua'),
          RoutineTask.create(title: 'Estiramiento ligero de 5 minutos'),
          RoutineTask.create(title: 'Revisar objetivos del día'),
          RoutineTask.create(title: 'Preparar desayuno balanceado'),
        ],
      ),
      Routine.create(
        name: 'Rutina nocturna',
        presetKey: 'night',
        iconName: 'nightlight',
        colorHex: 0xFFD7C0FF,
        tasks: [
          RoutineTask.create(
            title: 'Apagar pantallas 30 minutos antes de dormir',
          ),
          RoutineTask.create(title: 'Escribir 3 agradecimientos'),
          RoutineTask.create(title: 'Preparar ropa del día siguiente'),
          RoutineTask.create(title: 'Respirar profundamente 10 veces'),
        ],
      ),
      Routine.create(
        name: 'Ejercicio rápido',
        presetKey: 'quick_workout',
        iconName: 'fitness_center',
        colorHex: 0xFFB8F2E6,
        tasks: [
          RoutineTask.create(title: 'Calentamiento 3 minutos'),
          RoutineTask.create(title: '3 series de 15 sentadillas'),
          RoutineTask.create(title: 'Plancha 45 segundos'),
          RoutineTask.create(title: 'Estiramiento final'),
        ],
      ),
      Routine.create(
        name: 'Enfoque diario',
        presetKey: 'focus',
        iconName: 'self_improvement',
        colorHex: 0xFFBEE3FF,
        tasks: [
          RoutineTask.create(title: 'Revisar agenda prioritaria'),
          RoutineTask.create(
            title: 'Bloquear 2 horas de concentración profunda',
          ),
          RoutineTask.create(title: 'Configurar recordatorios importantes'),
          RoutineTask.create(title: 'Registrar logros al final del día'),
        ],
      ),
    ];
  }

  Map<String, dynamic> _mapFromHive(Map<dynamic, dynamic> input) {
    return input.map(
      (key, value) => MapEntry(key.toString(), _normalizeHiveValue(value)),
    );
  }

  dynamic _normalizeHiveValue(dynamic value) {
    if (value is Map<dynamic, dynamic>) {
      return value.map(
        (key, inner) => MapEntry(key.toString(), _normalizeHiveValue(inner)),
      );
    }
    if (value is List<dynamic>) {
      return value.map(_normalizeHiveValue).toList();
    }
    return value;
  }

  Future<void> _notificationsCleanup() async {
    // Placeholder in case we later persist notification metadata.
  }

  /// Exporta todas las rutinas, historial y configuraciones a JSON.
  Future<String> exportToJson() async {
    try {
      final routines = await loadRoutines();
      final history = await loadHistory();

      // Exportar TODAS las rutinas (incluyendo presets) para preservar el historial
      final allRoutines = routines.map((r) => r.toMap()).toList();

      // Exportar configuraciones relevantes
      final settings = <String, dynamic>{
        'displayName': displayName(),
        'birthday': birthday()?.toIso8601String(),
        'themePaletteId': themePaletteId(),
        'vibrationEnabled': vibrationEnabled(),
        'notificationsEnabled': notificationsEnabled(),
        'dailyReminder': _settingsBox.get('dailyReminder'),
      };

      final exportData = <String, dynamic>{
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'routines': allRoutines,
        'history': history.map((e) => e.toMap()).toList(),
        'settings': settings,
      };

      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(exportData);
    } catch (e, stackTrace) {
      debugPrint('[Storage] Error exportando datos: $e');
      debugPrint('[Storage] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Importa datos desde JSON y los restaura.
  /// [merge] si es true, fusiona con datos existentes; si es false, reemplaza todo.
  Future<void> importFromJson(String jsonString, {bool merge = false}) async {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!merge) {
        // Limpiar TODOS los datos existentes (incluyendo presets) para reemplazar completamente
        await _routinesBox.clear();
        await _historyBox.clear();
        // No limpiar settings aquí, se importarán después
      }

      // Mapa para rastrear IDs antiguos -> nuevos IDs de rutinas importadas
      final importedRoutinesMap = <String, String>{};

      // Importar rutinas
      if (decoded['routines'] != null) {
        final routinesList = decoded['routines'] as List<dynamic>;
        debugPrint('[Storage] Importando ${routinesList.length} rutinas...');
        int importedCount = 0;
        for (final routineMap in routinesList) {
          try {
            final routine = Routine.fromMap(routineMap as Map<String, dynamic>);
            final oldId = routine.id;
            // Mantener el ID original si no hay conflictos, o generar uno nuevo si es necesario
            // Para presets, mantener el presetKey original
            final newRoutine = routine.copyWith(
              id: oldId, // Mantener ID original para preservar referencias del historial
            );
            await saveRoutine(newRoutine);
            // Guardar mapeo de ID (aunque sea el mismo, para consistencia)
            importedRoutinesMap[oldId] = newRoutine.id;
            importedCount++;
            debugPrint(
              '[Storage] Rutina importada: ${routine.name} ($oldId -> ${newRoutine.id})',
            );
            debugPrint(
              '[Storage] Recordatorio: ${newRoutine.reminderTime?.toString() ?? "null"}, '
              'Weekdays: ${newRoutine.reminderWeekdays}, '
              'Date: ${newRoutine.reminderDate?.toString() ?? "null"}',
            );
          } catch (e, stackTrace) {
            debugPrint('[Storage] Error importando rutina: $e');
            debugPrint('[Storage] Stack trace: $stackTrace');
          }
        }
        debugPrint(
          '[Storage] Total rutinas importadas: $importedCount de ${routinesList.length}',
        );
      } else {
        debugPrint('[Storage] No hay rutinas en el JSON para importar');
      }

      // Importar historial (después de importar rutinas para que las referencias existan)
      if (decoded['history'] != null) {
        final historyList = decoded['history'] as List<dynamic>;
        // Cargar todas las rutinas importadas para verificar referencias
        final allRoutines = await loadRoutines();
        final allRoutineIds = allRoutines.map((r) => r.id).toSet();
        int importedHistoryCount = 0;

        for (final entryMap in historyList) {
          try {
            final entry = RoutineHistoryEntry.fromMap(
              entryMap as Map<String, dynamic>,
            );

            // Verificar que la rutina existe (debería existir porque importamos todas)
            if (allRoutineIds.contains(entry.routineId)) {
              await recordCompletion(entry);
              importedHistoryCount++;
              debugPrint(
                '[Storage] Historial importado: ${entry.id} -> rutina ${entry.routineId}',
              );
            } else {
              debugPrint(
                '[Storage] Historial omitido: rutina ${entry.routineId} no existe',
              );
            }
          } catch (e) {
            debugPrint('[Storage] Error importando entrada de historial: $e');
          }
        }
        debugPrint(
          '[Storage] Total historial importado: $importedHistoryCount de ${historyList.length}',
        );
      }

      // Importar configuraciones
      if (decoded['settings'] != null) {
        final settings = decoded['settings'] as Map<String, dynamic>;
        if (settings['displayName'] != null) {
          await setDisplayName(settings['displayName'] as String?);
        }
        if (settings['birthday'] != null) {
          final birthdayStr = settings['birthday'] as String?;
          if (birthdayStr != null) {
            await setBirthday(DateTime.tryParse(birthdayStr));
          }
        }
        if (settings['themePaletteId'] != null) {
          await setThemePaletteId(settings['themePaletteId'] as String);
        }
        if (settings['vibrationEnabled'] != null) {
          await setVibrationEnabled(settings['vibrationEnabled'] as bool);
        }
        if (settings['notificationsEnabled'] != null) {
          await setNotificationsEnabled(
            settings['notificationsEnabled'] as bool,
          );
        }
        if (settings['dailyReminder'] != null) {
          final reminderStr = settings['dailyReminder'] as String?;
          if (reminderStr != null) {
            final decoded = jsonDecode(reminderStr) as Map<String, dynamic>;
            final time = TimeOfDay(
              hour: decoded['hour'] as int,
              minute: decoded['minute'] as int,
            );
            await setDailyReminderTime(time);
          }
        }
      }

      // Forzar flush de todas las cajas para asegurar que los datos se guarden
      await _routinesBox.flush();
      await _historyBox.flush();
      await _settingsBox.flush();

      // Verificar que las rutinas se guardaron correctamente
      final savedRoutines = await loadRoutines();
      final customRoutinesCount = savedRoutines
          .where((r) => r.presetKey == null)
          .length;
      final presetRoutinesCount = savedRoutines
          .where((r) => r.presetKey != null)
          .length;
      debugPrint(
        '[Storage] Importación completada. Rutinas personalizadas: $customRoutinesCount, Presets: $presetRoutinesCount',
      );
      debugPrint('[Storage] Total rutinas en storage: ${savedRoutines.length}');

      if (decoded['routines'] != null) {
        final expectedCount = (decoded['routines'] as List<dynamic>).length;
        if (savedRoutines.length != expectedCount) {
          debugPrint(
            '[Storage] ADVERTENCIA: Se esperaban $expectedCount rutinas pero se encontraron ${savedRoutines.length}',
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('[Storage] Error importando datos: $e');
      debugPrint('[Storage] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Guarda el progreso de una rutina en curso.
  Future<void> saveProgress(RoutineProgress progress) async {
    try {
      if (!_initialized) {
        debugPrint('[Storage] Error: Storage no inicializado');
        await init();
      }
      final map = progress.toMap();
      debugPrint(
        '[Storage] Guardando progreso para rutina: ${progress.routineId}',
      );
      await _progressBox.put(progress.routineId, map);
      await _progressBox.flush();
      debugPrint('[Storage] Progreso guardado: ${progress.routineId}');
    } catch (e, stackTrace) {
      debugPrint('[Storage] Error guardando progreso: $e');
      debugPrint('[Storage] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Carga el progreso guardado de una rutina.
  RoutineProgress? loadProgress(String routineId) {
    try {
      final map = _progressBox.get(routineId);
      if (map == null) {
        return null;
      }
      return RoutineProgress.fromMap(_mapFromHive(map));
    } catch (e, stackTrace) {
      debugPrint('[Storage] Error cargando progreso: $e');
      debugPrint('[Storage] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Elimina el progreso guardado de una rutina.
  Future<void> deleteProgress(String routineId) async {
    try {
      await _progressBox.delete(routineId);
      await _progressBox.flush();
      debugPrint('[Storage] Progreso eliminado: $routineId');
    } catch (e, stackTrace) {
      debugPrint('[Storage] Error eliminando progreso: $e');
      debugPrint('[Storage] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Carga todos los progresos guardados.
  List<RoutineProgress> loadAllProgress() {
    try {
      return _progressBox.values
          .map((entry) {
            try {
              return RoutineProgress.fromMap(_mapFromHive(entry));
            } catch (e) {
              debugPrint('[Storage] Error parseando progreso: $e');
              return null;
            }
          })
          .whereType<RoutineProgress>()
          .toList();
    } catch (e, stackTrace) {
      debugPrint('[Storage] Error cargando todos los progresos: $e');
      debugPrint('[Storage] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Guarda una entrada de diario.
  Future<void> saveJournalEntry(JournalEntry entry) async {
    try {
      if (!_initialized) {
        debugPrint('[Storage] Error: Storage no inicializado');
        await init();
      }
      final map = entry.toMap();
      debugPrint('[Storage] Guardando anotación: ${entry.id}');
      await _journalBox.put(entry.id, map);
      await _journalBox.flush();
      debugPrint('[Storage] Anotación guardada: ${entry.id}');
    } catch (e, stackTrace) {
      debugPrint('[Storage] Error guardando anotación: $e');
      debugPrint('[Storage] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Carga todas las entradas de diario.
  List<JournalEntry> loadJournalEntries() {
    try {
      return _journalBox.values
          .map((entry) {
            try {
              return JournalEntry.fromMap(_mapFromHive(entry));
            } catch (e) {
              debugPrint('[Storage] Error parseando anotación: $e');
              return null;
            }
          })
          .whereType<JournalEntry>()
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e, stackTrace) {
      debugPrint('[Storage] Error cargando anotaciones: $e');
      debugPrint('[Storage] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Carga una entrada de diario por fecha.
  JournalEntry? loadJournalEntryByDate(DateTime date) {
    try {
      final day = DateTime(date.year, date.month, date.day);
      final entries = loadJournalEntries();
      return entries.firstWhere((entry) {
        final entryDay = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        return entryDay == day;
      }, orElse: () => JournalEntry.create(date: day));
    } catch (e) {
      debugPrint('[Storage] Error cargando anotación por fecha: $e');
      return null;
    }
  }

  /// Elimina una entrada de diario.
  Future<void> deleteJournalEntry(String id) async {
    try {
      await _journalBox.delete(id);
      await _journalBox.flush();
      debugPrint('[Storage] Anotación eliminada: $id');
    } catch (e, stackTrace) {
      debugPrint('[Storage] Error eliminando anotación: $e');
      debugPrint('[Storage] Stack trace: $stackTrace');
      rethrow;
    }
  }
}
