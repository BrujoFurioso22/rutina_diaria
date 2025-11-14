import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Maneja los recordatorios locales para las rutinas.
class NotificationsService {
  NotificationsService._();

  static final NotificationsService instance = NotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Function(NotificationResponse)? _onNotificationTap;

  Future<void> init({Function(NotificationResponse)? onNotificationTap}) async {
    if (_initialized) {
      return;
    }
    tz.initializeTimeZones();
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    _onNotificationTap = onNotificationTap;
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );
    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
    await _requestPermissions();
    _initialized = true;
  }

  void _handleNotificationTap(NotificationResponse response) {
    _onNotificationTap?.call(response);
  }

  void setNotificationTapHandler(Function(NotificationResponse) handler) {
    _onNotificationTap = handler;
  }

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await cancelNotification(7777);
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    _logDelay('daily reminder', 7777, scheduled);
    final delay = scheduled.difference(now);
    await scheduleCountdown(
      notificationId: 7777,
      delay: delay,
      title: 'Preparación para mañana',
      body: 'Tómate un momento para planear tu rutina de mañana.',
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Recordatorios diarios',
          channelDescription: 'Recordatorio diario para preparar la rutina',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> scheduleRoutineReminder({
    required String routineId,
    required String title,
    required TimeOfDay time,
  }) async {
    final notificationId = _baseNotificationId(routineId);
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    debugPrint(
      '[Notifications] routine reminder request -> now: $now, '
      'initial target: $scheduled',
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
      debugPrint(
        '[Notifications] routine reminder adjusted to next day: $scheduled',
      );
    }
    _logDelay('routine reminder', notificationId, scheduled);
    final delay = scheduled.difference(now);
    await scheduleCountdown(
      notificationId: notificationId,
      delay: delay,
      title: 'Es hora de tu rutina',
      body: '¡$title te está esperando!',
      payload: routineId,
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_reminders_channel',
          'Recordatorios de rutinas',
          channelDescription:
              'Alertas puntuales para las rutinas personalizadas',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> scheduleRoutineReminderForWeekdays({
    required String routineId,
    required String title,
    required TimeOfDay time,
    required List<int> weekdays,
  }) async {
    for (final weekday in weekdays) {
      final notificationId = _notificationIdForDay(routineId, weekday);
      final scheduled = _nextDateForWeekday(time, weekday);
      _logDelay('routine weekday reminder', notificationId, scheduled);
      final delay = scheduled.difference(DateTime.now());
      await scheduleCountdown(
        notificationId: notificationId,
        delay: delay,
        title: title,
        body: '¡$title te está esperando!',
        payload: routineId,
        details: const NotificationDetails(
          android: AndroidNotificationDetails(
            'routine_weekly_channel',
            'Recordatorios semanales',
            channelDescription:
                'Alertas recurrentes según los días seleccionados',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  Future<void> scheduleRoutineDateReminder({
    required String routineId,
    required String title,
    required DateTime dateTime,
  }) async {
    final notificationId = _baseNotificationId(routineId);
    if (!dateTime.isAfter(DateTime.now())) {
      return;
    }
    _logDelay('routine date reminder', notificationId, dateTime);
    final delay = dateTime.difference(DateTime.now());
    await scheduleCountdown(
      notificationId: notificationId,
      delay: delay,
      title: 'Recordatorio puntual',
      body: '¡$title está programada para hoy!',
      payload: routineId,
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_one_shot_channel',
          'Recordatorios puntuales',
          channelDescription: 'Alertas únicas para rutinas programadas',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    if (!_initialized) {
      debugPrint(
        '[Notifications] Servicio no inicializado, omitiendo cancelación',
      );
      return;
    }
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('[Notifications] Error cancelando notificación $id: $e');
      // No relanzar el error, solo registrar
    }
  }

  Future<void> cancelRoutineReminder(String routineId) async {
    if (!_initialized) {
      debugPrint(
        '[Notifications] Servicio no inicializado, omitiendo cancelación de rutina',
      );
      return;
    }
    try {
      final baseId = _baseNotificationId(routineId);
      await cancelNotification(baseId);
      for (
        var weekday = DateTime.monday;
        weekday <= DateTime.sunday;
        weekday++
      ) {
        final dayId = _notificationIdForDay(routineId, weekday);
        await cancelNotification(dayId);
      }
    } catch (e) {
      debugPrint('[Notifications] Error cancelando recordatorio de rutina: $e');
      // No relanzar el error, solo registrar
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> sendTestNotification() async {
    await _plugin.show(
      9999,
      'Notificación de prueba',
      'Así se verá tu recordatorio de Daylyo.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_test_channel',
          'Recordatorios de prueba',
          channelDescription: 'Permite validar que las alertas funcionen',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> scheduleCountdown({
    required int notificationId,
    required Duration delay,
    String? title,
    String? body,
    String? payload,
    NotificationDetails? details,
  }) async {
    final rawSeconds = delay.inSeconds;
    final sanitizedSeconds = rawSeconds <= 0
        ? 1
        : rawSeconds > 86400 * 30
        ? 86400 * 30
        : rawSeconds;
    final scheduledDateTime = DateTime.now().add(
      Duration(seconds: sanitizedSeconds),
    );
    _logSeconds('countdown reminder', notificationId, sanitizedSeconds);
    debugPrint(
      '[Notifications] countdown reminder (id: $notificationId) objetivo local: '
      '$scheduledDateTime',
    );
    debugPrint(
      '[Notifications] countdown reminder (id: $notificationId) objetivo local: '
      '$scheduledDateTime',
    );
    final notificationDetails =
        details ??
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'routine_timer_channel',
            'Recordatorios temporizados',
            channelDescription:
                'Notificaciones que se programan a partir de un temporizador',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        );
    await _scheduleZoned(
      id: notificationId,
      title: title ?? 'Recordatorio en camino',
      body:
          body ??
          'Tu notificación llegará en ${sanitizedSeconds == 1 ? '1 segundo' : '$sanitizedSeconds segundos'}.',
      payload: payload,
      scheduled: tz.TZDateTime.now(
        tz.local,
      ).add(Duration(seconds: sanitizedSeconds)),
      details: notificationDetails,
    );
    if (sanitizedSeconds <= 300) {
      Future.delayed(Duration(seconds: sanitizedSeconds), () async {
        try {
          await _plugin.show(
            notificationId,
            title ?? 'Recordatorio en camino',
            body ??
                'Tu notificación llegó después de $sanitizedSeconds segundos.',
            notificationDetails,
            payload: payload,
          );
        } catch (error) {
          debugPrint(
            '[Notifications] Error mostrando recordatorio de respaldo: $error',
          );
        }
      });
    }
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  DateTime _nextDateForWeekday(TimeOfDay time, int weekday) {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _baseNotificationId(String routineId) {
    return routineId.hashCode & 0x7FFFFFFF;
  }

  int _notificationIdForDay(String routineId, int weekday) {
    final base = _baseNotificationId(routineId);
    return (base + weekday) & 0x7FFFFFFF;
  }

  void _logDelay(String label, int id, DateTime scheduled) {
    final now = DateTime.now();
    final seconds = scheduled.difference(now).inSeconds;
    debugPrint(
      '[Notifications] $label (id: $id) programada para $scheduled '
      'en ${seconds.clamp(0, 86400 * 7)} segundos.',
    );
  }

  void _logSeconds(String label, int id, int seconds) {
    debugPrint(
      '[Notifications] $label (id: $id) programada para ejecutarse en '
      '${seconds.clamp(0, 86400 * 30)} segundos.',
    );
  }

  Future<void> _scheduleZoned({
    required int id,
    required String title,
    required String body,
    String? payload,
    required tz.TZDateTime scheduled,
    required NotificationDetails details,
    DateTimeComponents? matchComponents,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      payload: payload,
      androidAllowWhileIdle: true,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: matchComponents,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
