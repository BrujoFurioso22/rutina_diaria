import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/routine_model.dart';
import '../models/task_model.dart';
import '../services/ads_service.dart';
import '../services/notifications_service.dart';
import '../services/storage_service.dart';
import '../services/widget_service.dart';
import '../utils/app_theme.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService.instance;
});

final adsServiceProvider = Provider<AdsService>((ref) {
  return AdsService.instance;
});

final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService.instance;
});

final routineControllerProvider =
    StateNotifierProvider<RoutineController, RoutineState>((ref) {
      final controller = RoutineController(
        storageService: ref.watch(storageServiceProvider),
        notificationsService: ref.watch(notificationsServiceProvider),
        adsService: ref.watch(adsServiceProvider),
        widgetService: ref.watch(widgetServiceProvider),
      );
      scheduleMicrotask(() => controller.loadInitialData());
      return controller;
    });

/// Estado derivado de la gestión de rutinas almacenadas localmente.
class RoutineState {
  const RoutineState({
    this.routines = const [],
    this.history = const [],
    this.allProgress = const [],
    this.isPremium = false,
    this.streakDays = 0,
    this.isLoading = true,
    this.dailyReminder = const TimeOfDay(hour: 19, minute: 0),
    this.displayName,
    this.birthday,
    this.vibrationEnabled = true,
    this.paletteId = AppTheme.defaultPaletteId,
    this.notificationsEnabled = true,
  });

  final List<Routine> routines;
  final List<RoutineHistoryEntry> history;
  final List<RoutineProgress> allProgress;
  final bool isPremium;
  final int streakDays;
  final bool isLoading;
  final TimeOfDay dailyReminder;
  final String? displayName;
  final DateTime? birthday;
  final bool vibrationEnabled;
  final String paletteId;
  final bool notificationsEnabled;

  RoutineState copyWith({
    List<Routine>? routines,
    List<RoutineHistoryEntry>? history,
    List<RoutineProgress>? allProgress,
    bool? isPremium,
    int? streakDays,
    bool? isLoading,
    TimeOfDay? dailyReminder,
    String? displayName,
    bool removeDisplayName = false,
    DateTime? birthday,
    bool removeBirthday = false,
    bool? vibrationEnabled,
    String? paletteId,
    bool? notificationsEnabled,
  }) {
    return RoutineState(
      routines: routines ?? this.routines,
      history: history ?? this.history,
      allProgress: allProgress ?? this.allProgress,
      isPremium: isPremium ?? this.isPremium,
      streakDays: streakDays ?? this.streakDays,
      isLoading: isLoading ?? this.isLoading,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      displayName: removeDisplayName ? null : (displayName ?? this.displayName),
      birthday: removeBirthday ? null : (birthday ?? this.birthday),
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      paletteId: paletteId ?? this.paletteId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class RoutineController extends StateNotifier<RoutineState> {
  RoutineController({
    required StorageService storageService,
    required NotificationsService notificationsService,
    required AdsService adsService,
    WidgetService? widgetService,
  }) : _storage = storageService,
       _notifications = notificationsService,
       _ads = adsService,
       _widgetService = widgetService,
       super(const RoutineState());

  final StorageService _storage;
  final NotificationsService _notifications;
  final AdsService _ads;
  final WidgetService? _widgetService;

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true);

    // Marcar el tiempo de inicio para asegurar mínimo de 2.5 segundos
    final startTime = DateTime.now();

    try {
      // Inicializar servicios en paralelo para acelerar
      await Future.wait([
        _storage.init(),
        _notifications.init(),
        _ads.init(),
        _widgetService?.init() ?? Future.value(),
      ]);

      // Cargar datos en paralelo
      final results = await Future.wait([
        _storage.loadRoutines(),
        _storage.loadHistory(),
        Future.value(_storage.loadAllProgress()),
        Future.value(_storage.isPremium()),
        Future.value(_storage.dailyReminderTime()),
        Future.value(_storage.vibrationEnabled()),
        Future.value(_storage.themePaletteId()),
        Future.value(_storage.notificationsEnabled()),
        Future.value(_storage.displayName()),
        Future.value(_storage.birthday()),
      ]);

      var routines = results[0] as List<Routine>;
      final history = results[1] as List<RoutineHistoryEntry>;
      final allProgress = results[2] as List<RoutineProgress>;
      final isPremium = results[3] as bool;
      final dailyReminder = results[4] as TimeOfDay;
      final vibrationEnabled = results[5] as bool;
      final paletteId = results[6] as String;
      final notificationsEnabled = results[7] as bool;
      final displayName = results[8] as String?;
      final birthday = results[9] as DateTime?;

      AppColors.updateById(paletteId);

      // Programar notificaciones de forma asíncrona (no bloquea la UI)
      if (notificationsEnabled) {
        _notifications.scheduleDailyReminder(dailyReminder).catchError((e) {
          debugPrint('Error programando recordatorio diario: $e');
        });
        _rescheduleRoutineNotifications(routines)
            .then((updated) {
              state = state.copyWith(routines: updated);
            })
            .catchError((e) {
              debugPrint('Error reprogramando notificaciones: $e');
            });
      } else {
        _notifications.cancelAll().catchError((e) {
          debugPrint('Error cancelando notificaciones: $e');
        });
      }

      final streak = _calculateStreak(history);

      // Calcular tiempo transcurrido y esperar si es necesario para cumplir mínimo de 2.5 segundos
      final elapsed = DateTime.now().difference(startTime);
      const minDuration = Duration(milliseconds: 2500);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }

      state = state.copyWith(
        routines: routines,
        history: history,
        allProgress: allProgress,
        isPremium: isPremium,
        streakDays: streak,
        dailyReminder: dailyReminder,
        displayName: displayName,
        birthday: birthday,
        vibrationEnabled: vibrationEnabled,
        paletteId: paletteId,
        notificationsEnabled: notificationsEnabled,
        isLoading: false,
      );

      // Actualizar widget de forma asíncrona
      Future.microtask(() => _updateWidget(streak, routines));
    } catch (error, stackTrace) {
      debugPrint('Error cargando datos iniciales: $error');
      debugPrint('$stackTrace');

      // Asegurar mínimo de 2.5 segundos incluso en caso de error
      final elapsed = DateTime.now().difference(startTime);
      const minDuration = Duration(milliseconds: 2500);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }

      state = state.copyWith(isLoading: false);
    }
  }

  /// Recarga los datos desde el storage sin reinicializar servicios.
  /// Útil después de importar datos o hacer cambios externos.
  Future<void> refreshData() async {
    try {
      // Cargar datos en paralelo
      final results = await Future.wait([
        _storage.loadRoutines(),
        _storage.loadHistory(),
        Future.value(_storage.loadAllProgress()),
        Future.value(_storage.isPremium()),
        Future.value(_storage.dailyReminderTime()),
        Future.value(_storage.vibrationEnabled()),
        Future.value(_storage.themePaletteId()),
        Future.value(_storage.notificationsEnabled()),
        Future.value(_storage.displayName()),
        Future.value(_storage.birthday()),
      ]);

      var routines = results[0] as List<Routine>;
      final history = results[1] as List<RoutineHistoryEntry>;
      final allProgress = results[2] as List<RoutineProgress>;
      final isPremium = results[3] as bool;
      final dailyReminder = results[4] as TimeOfDay;
      final vibrationEnabled = results[5] as bool;
      final paletteId = results[6] as String;
      final notificationsEnabled = results[7] as bool;
      final displayName = results[8] as String?;
      final birthday = results[9] as DateTime?;

      AppColors.updateById(paletteId);

      // Reprogramar notificaciones si están habilitadas
      if (notificationsEnabled) {
        await _notifications.scheduleDailyReminder(dailyReminder).catchError((
          e,
        ) {
          debugPrint('Error programando recordatorio diario: $e');
        });
        // Programar notificaciones de rutinas de forma síncrona para asegurar que se completen
        try {
          routines = await _rescheduleRoutineNotifications(routines);
        } catch (e) {
          debugPrint('Error reprogramando notificaciones: $e');
        }
      }

      final streak = _calculateStreak(history);
      state = state.copyWith(
        routines: routines,
        history: history,
        allProgress: allProgress,
        isPremium: isPremium,
        streakDays: streak,
        dailyReminder: dailyReminder,
        displayName: displayName,
        birthday: birthday,
        vibrationEnabled: vibrationEnabled,
        paletteId: paletteId,
        notificationsEnabled: notificationsEnabled,
      );

      // Actualizar widget de forma asíncrona
      Future.microtask(() => _updateWidget(streak, routines));
    } catch (error, stackTrace) {
      debugPrint('Error refrescando datos: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> addOrUpdateRoutine(Routine routine) async {
    try {
      final now = DateTime.now();
      var persisted = routine.copyWith(
        createdAt: routine.createdAt ?? now,
        updatedAt: now,
      );
      if (persisted.reminderDate != null &&
          persisted.reminderDate!.isBefore(now)) {
        persisted = persisted.copyWith(
          reminderDate: null,
          removeReminderDate: true,
          updatedAt: now,
        );
      }
      debugPrint('[Controller] Guardando rutina: ${persisted.name}');
      await _storage.saveRoutine(persisted);
      debugPrint('[Controller] Rutina guardada en storage');

      // Cancelar notificaciones existentes (no crítico si falla)
      try {
        await _notifications.cancelRoutineReminder(persisted.id);
      } catch (e) {
        debugPrint(
          '[Controller] Error cancelando notificaciones (no crítico): $e',
        );
      }

      // Programar nuevas notificaciones si están habilitadas
      if (state.notificationsEnabled) {
        try {
          persisted = await _scheduleRoutineNotification(persisted);
        } catch (e) {
          debugPrint(
            '[Controller] Error programando notificaciones (no crítico): $e',
          );
        }
      }

      // Recargar desde storage para asegurar que tenemos la versión más reciente
      final allRoutines = await _storage.loadRoutines();
      debugPrint(
        '[Controller] Rutinas cargadas después de guardar: ${allRoutines.length}',
      );

      final currentStreak = _calculateStreak(state.history);
      state = state.copyWith(routines: allRoutines);
      debugPrint(
        '[Controller] Estado actualizado con ${allRoutines.length} rutinas',
      );
      // Actualizar widget cuando se guarda/edita una rutina
      _updateWidget(currentStreak, allRoutines);
    } catch (e, stackTrace) {
      debugPrint('[Controller] Error guardando rutina: $e');
      debugPrint('[Controller] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> duplicateRoutine(Routine routine) async {
    final duplicatedTasks = routine.tasks
        .map(
          (task) => RoutineTask.create(
            title: task.title,
            description: task.description,
            isOptional: task.isOptional,
          ),
        )
        .toList();
    final duplicate = Routine.create(
      name: '${routine.name} (copia)',
      tasks: duplicatedTasks,
      colorHex: routine.colorHex,
      iconName: routine.iconName,
      reminderTime: routine.reminderTime,
      reminderWeekdays: routine.reminderWeekdays,
    );
    await addOrUpdateRoutine(duplicate);
  }

  Future<void> removeRoutine(String routineId) async {
    await _storage.deleteRoutine(routineId);
    await _notifications.cancelRoutineReminder(routineId);
    final updated = state.routines
        .where((routine) => routine.id != routineId)
        .toList();
    final updatedHistory = state.history
        .where((entry) => entry.routineId != routineId)
        .toList();
    final newStreak = _calculateStreak(updatedHistory);
    state = state.copyWith(
      routines: updated,
      history: updatedHistory,
      streakDays: newStreak,
    );
    // Actualizar widget cuando se elimina una rutina
    _updateWidget(newStreak, updated);
  }

  Future<void> completeRoutine(
    String routineId, {
    String? note,
    List<int>? completedTaskIndices,
  }) async {
    final routineIndex = state.routines.indexWhere(
      (routine) => routine.id == routineId,
    );
    if (routineIndex < 0) {
      return;
    }
    final routine = state.routines[routineIndex];
    final now = DateTime.now();
    debugPrint('[Complete] Completando rutina ${routine.name}');
    debugPrint('[Complete] Fecha actual: $now');
    debugPrint('[Complete] Fecha solo día: ${DateUtils.dateOnly(now)}');

    final entry = RoutineHistoryEntry.create(
      routineId: routineId,
      note: note,
      completedTaskIndices: completedTaskIndices,
    );
    debugPrint('[Complete] Entrada creada con fecha: ${entry.completedAt}');
    debugPrint(
      '[Complete] Entrada fecha solo día: ${DateUtils.dateOnly(entry.completedAt)}',
    );

    final updatedRoutine = routine.copyWith(
      completedCount: routine.completedCount + 1,
      lastCompleted: entry.completedAt,
      updatedAt: entry.completedAt,
    );
    await _storage.saveRoutine(updatedRoutine);
    await _storage.recordCompletion(entry);

    final updatedRoutines = [...state.routines]
      ..[routineIndex] = updatedRoutine;
    final updatedHistory = [entry, ...state.history];
    debugPrint(
      '[Complete] Historial antes de calcular racha: ${updatedHistory.length} entradas',
    );
    final streak = _calculateStreak(updatedHistory);
    state = state.copyWith(
      routines: updatedRoutines,
      history: updatedHistory,
      streakDays: streak,
    );
    _updateWidget(streak, updatedRoutines);
    _ads.registerRoutineCompletion(isPremium: state.isPremium);
  }

  Future<void> togglePremium(bool value) async {
    await _storage.savePremium(value);
    if (value) {
      _ads.disposeInterstitial();
    }
    state = state.copyWith(isPremium: value);
  }

  Future<void> updateDailyReminder(TimeOfDay time) async {
    await _storage.setDailyReminderTime(time);
    if (state.notificationsEnabled) {
      await _notifications.scheduleDailyReminder(time);
    } else {
      await _notifications.cancelNotification(7777);
    }
    state = state.copyWith(dailyReminder: time);
  }

  Future<void> updateDisplayName(String? name) async {
    await _storage.setDisplayName(name);
    state = state.copyWith(displayName: name, removeDisplayName: name == null);
  }

  Future<void> updateBirthday(DateTime? date) async {
    await _storage.setBirthday(date);
    state = state.copyWith(birthday: date, removeBirthday: date == null);
  }

  Future<void> updateVibrationEnabled(bool value) async {
    await _storage.setVibrationEnabled(value);
    state = state.copyWith(vibrationEnabled: value);
  }

  Future<void> updatePalette(String paletteId) async {
    AppColors.updateById(paletteId);
    await _storage.setThemePaletteId(paletteId);
    state = state.copyWith(paletteId: paletteId);
  }

  Future<void> updateNotificationsEnabled(bool value) async {
    await _storage.setNotificationsEnabled(value);
    if (value) {
      await _notifications.init();
      await _notifications.scheduleDailyReminder(state.dailyReminder);
      final rescheduled = await _rescheduleRoutineNotifications([
        ...state.routines,
      ]);
      state = state.copyWith(
        routines: rescheduled,
        notificationsEnabled: value,
      );
      return;
    } else {
      await _notifications.cancelAll();
    }
    state = state.copyWith(notificationsEnabled: value);
  }

  Future<void> resetAppData() async {
    state = state.copyWith(isLoading: true);
    try {
      await _notifications.cancelAll();
      await _storage.resetAll();
      await loadInitialData();
    } catch (error, stackTrace) {
      debugPrint('Error reiniciando datos: $error');
      debugPrint('$stackTrace');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> triggerTestNotification({int seconds = 60}) async {
    if (!state.notificationsEnabled) {
      return false;
    }
    try {
      await _notifications.init();
      await _notifications.scheduleCountdown(
        notificationId: 9998,
        delay: Duration(seconds: seconds),
        title: 'Recordatorio de prueba',
        body:
            'Te avisaremos en ${seconds == 1 ? '1 segundo' : '$seconds segundos'}.',
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('Error enviando notificación de prueba: $error');
      debugPrint('$stackTrace');
      return false;
    }
  }

  Map<String, int> completionsByRoutine() {
    final summary = <String, int>{};
    for (final entry in state.history) {
      summary.update(entry.routineId, (value) => value + 1, ifAbsent: () => 1);
    }
    return summary;
  }

  List<RoutineHistoryEntry> entriesForWeek(DateTime weekStart) {
    final start = DateUtils.dateOnly(weekStart);
    final end = start.add(const Duration(days: 7));
    return state.history
        .where(
          (entry) =>
              entry.completedAt.isAfter(
                start.subtract(const Duration(milliseconds: 1)),
              ) &&
              entry.completedAt.isBefore(end),
        )
        .toList();
  }

  int _calculateStreak(List<RoutineHistoryEntry> history) {
    if (history.isEmpty) {
      debugPrint('[Streak] Historial vacío, racha = 0');
      return 0;
    }
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    // Obtener solo las fechas únicas donde se completaron rutinas
    final uniqueDates = history
        .map((entry) => DateUtils.dateOnly(entry.completedAt))
        .toSet();

    debugPrint('[Streak] Total entradas en historial: ${history.length}');
    debugPrint('[Streak] Fechas únicas con completados: ${uniqueDates.length}');
    debugPrint(
      '[Streak] Fechas: ${uniqueDates.map((d) => d.toString()).join(", ")}',
    );
    debugPrint('[Streak] Hoy: $today');
    debugPrint('[Streak] Ayer: $yesterday');

    // Si no hay completados hoy ni ayer, la racha se rompió
    final hasToday = uniqueDates.contains(today);
    final hasYesterday = uniqueDates.contains(yesterday);

    if (!hasToday && !hasYesterday) {
      debugPrint('[Streak] No hay completados hoy ni ayer, racha = 0');
      return 0;
    }

    // Si hay completados hoy, contar desde hoy hacia atrás
    // Si no hay completados hoy pero sí ayer, contar desde ayer hacia atrás
    var startDate = hasToday ? today : yesterday;
    var streak = 0;
    var currentDate = startDate;

    // Contar días consecutivos hacia atrás
    while (uniqueDates.contains(currentDate)) {
      streak += 1;
      debugPrint('[Streak] Día $streak: $currentDate');
      currentDate = currentDate.subtract(const Duration(days: 1));
    }
    debugPrint('[Streak] Racha final calculada: $streak días');
    return streak;
  }

  /// Verifica si el usuario completó rutinas hoy.
  bool hasCompletedToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    return state.history.any(
      (entry) => DateUtils.dateOnly(entry.completedAt) == today,
    );
  }

  Future<List<Routine>> _rescheduleRoutineNotifications(
    List<Routine> routines,
  ) async {
    for (var i = 0; i < routines.length; i++) {
      routines[i] = await _scheduleRoutineNotification(routines[i]);
    }
    return routines;
  }

  Future<Routine> _scheduleRoutineNotification(Routine routine) async {
    var updatedRoutine = routine;
    
    // Primero cancelar todas las notificaciones previas de esta rutina y sus tareas
    await _notifications.cancelRoutineReminder(routine.id);
    for (final task in routine.tasks) {
      if (task.reminderTime != null) {
        await _notifications.cancelTaskReminder(routine.id, task.id);
      }
    }

    // Si tiene repetición avanzada, usar el nuevo sistema
    if (routine.reminderRepeat != null && routine.reminderTime != null) {
      await _notifications.scheduleRoutineReminderWithRepeat(
        routineId: routine.id,
        title: routine.name,
        time: routine.reminderTime!,
        repeat: routine.reminderRepeat!,
      );
    }
    // Sistema antiguo: compatibilidad con recordatorios por días de la semana
    else if (routine.reminderWeekdays.isNotEmpty && routine.reminderTime != null) {
      await _notifications.scheduleRoutineReminderForWeekdays(
        routineId: routine.id,
        title: routine.name,
        time: routine.reminderTime!,
        weekdays: routine.reminderWeekdays,
      );
    }
    // Sistema antiguo: recordatorio diario simple
    else if (routine.reminderTime != null) {
      await _notifications.scheduleRoutineReminder(
        routineId: routine.id,
        title: routine.name,
        time: routine.reminderTime!,
      );
    }
    // Recordatorio con fecha específica
    else if (routine.reminderDate != null) {
      if (routine.reminderDate!.isAfter(DateTime.now())) {
        await _notifications.scheduleRoutineDateReminder(
          routineId: routine.id,
          title: routine.name,
          dateTime: routine.reminderDate!,
        );
      } else {
        updatedRoutine = routine.copyWith(
          reminderDate: null,
          removeReminderDate: true,
          updatedAt: DateTime.now(),
        );
        await _storage.saveRoutine(updatedRoutine);
      }
    }

    // Programar notificaciones individuales por tarea
    for (final task in routine.tasks) {
      if (task.reminderTime != null) {
        await _notifications.scheduleTaskReminder(
          routineId: routine.id,
          taskId: task.id,
          taskTitle: task.title,
          routineTitle: routine.name,
          time: task.reminderTime!,
          repeat: routine.reminderRepeat,
        );
      }
    }

    return updatedRoutine;
  }

  void setupNotificationHandler(Function(NotificationResponse) handler) {
    _notifications.setNotificationTapHandler(handler);
  }

  void _updateWidget(int streak, List<Routine> routines) {
    final widgetService = _widgetService;
    if (widgetService == null) {
      debugPrint(
        '[Controller] WidgetService no disponible, omitiendo actualización',
      );
      return;
    }

    debugPrint('[Controller] Actualizando widget - Racha actual: $streak días');

    final now = DateTime.now();
    Routine? nextRoutine;
    DateTime? nextRoutineTime;

    // Buscar la próxima rutina programada para hoy
    for (final routine in routines) {
      if (routine.reminderTime != null && routine.reminderWeekdays.isNotEmpty) {
        final today = now.weekday;
        if (routine.reminderWeekdays.contains(today)) {
          final reminderTime = routine.reminderTime!;
          final reminderDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            reminderTime.hour,
            reminderTime.minute,
          );
          if (reminderDateTime.isAfter(now)) {
            final currentNextTime = nextRoutineTime;
            if (currentNextTime == null ||
                reminderDateTime.isBefore(currentNextTime)) {
              nextRoutine = routine;
              nextRoutineTime = reminderDateTime;
            }
          }
        }
      }
    }

    // Si no hay rutina para hoy, buscar la próxima de la semana
    if (nextRoutine == null) {
      for (var dayOffset = 1; dayOffset <= 7; dayOffset++) {
        final checkDate = now.add(Duration(days: dayOffset));
        final checkWeekday = checkDate.weekday;

        for (final routine in routines) {
          if (routine.reminderTime != null &&
              routine.reminderWeekdays.contains(checkWeekday)) {
            final reminderTime = routine.reminderTime!;
            final reminderDateTime = DateTime(
              checkDate.year,
              checkDate.month,
              checkDate.day,
              reminderTime.hour,
              reminderTime.minute,
            );
            final currentNextTime = nextRoutineTime;
            if (currentNextTime == null ||
                reminderDateTime.isBefore(currentNextTime)) {
              nextRoutine = routine;
              nextRoutineTime = reminderDateTime;
            }
          }
        }

        if (nextRoutine != null) break;
      }
    }

    // Actualizar el widget de forma asíncrona
    unawaited(
      widgetService.updateWidget(
        streakDays: streak,
        nextRoutineName: nextRoutine?.name,
        nextRoutineTime: nextRoutineTime != null
            ? '${nextRoutineTime.hour.toString().padLeft(2, '0')}:${nextRoutineTime.minute.toString().padLeft(2, '0')}'
            : null,
      ),
    );
  }

  /// Guarda el progreso de una rutina en curso.
  Future<void> saveProgress(RoutineProgress progress) async {
    try {
      await _storage.saveProgress(progress);
      // Actualizar el estado con el nuevo progreso
      final currentProgress = List<RoutineProgress>.from(state.allProgress);
      final existingIndex = currentProgress.indexWhere(
        (p) => p.routineId == progress.routineId,
      );
      if (existingIndex >= 0) {
        currentProgress[existingIndex] = progress;
      } else {
        currentProgress.add(progress);
      }
      state = state.copyWith(allProgress: currentProgress);
    } catch (e) {
      debugPrint('Error guardando progreso: $e');
      rethrow;
    }
  }

  /// Carga el progreso guardado de una rutina.
  RoutineProgress? loadProgress(String routineId) {
    try {
      // Buscar en el estado primero
      final stateProgress = state.allProgress.firstWhere(
        (p) => p.routineId == routineId,
        orElse: () => RoutineProgress.create(routineId: routineId),
      );

      // Si está en el estado, devolverlo
      if (state.allProgress.any((p) => p.routineId == routineId)) {
        return stateProgress;
      }

      // Si no está en el estado, buscar en storage
      final storageProgress = _storage.loadProgress(routineId);
      if (storageProgress != null) {
        // Actualizar el estado con el progreso encontrado
        final updatedProgress = List<RoutineProgress>.from(state.allProgress)
          ..add(storageProgress);
        state = state.copyWith(allProgress: updatedProgress);
        return storageProgress;
      }

      return null;
    } catch (e) {
      debugPrint('Error cargando progreso: $e');
      return _storage.loadProgress(routineId);
    }
  }

  /// Elimina el progreso guardado de una rutina.
  Future<void> deleteProgress(String routineId) async {
    try {
      await _storage.deleteProgress(routineId);
      // Actualizar el estado eliminando el progreso
      final currentProgress = List<RoutineProgress>.from(state.allProgress)
        ..removeWhere((p) => p.routineId == routineId);
      state = state.copyWith(allProgress: currentProgress);
    } catch (e) {
      debugPrint('Error eliminando progreso: $e');
      rethrow;
    }
  }
}
