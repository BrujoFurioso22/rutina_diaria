import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Servicio para manejar widgets de la pantalla de inicio.
class WidgetService {
  WidgetService._();

  static final WidgetService instance = WidgetService._();

  static const String _widgetName = 'RutinaDiariaWidget';
  static const String _streakKey = 'streak_days';
  static const String _nextRoutineKey = 'next_routine';
  static const String _nextRoutineTimeKey = 'next_routine_time';

  /// Inicializa el servicio de widgets.
  Future<void> init() async {
    try {
      // Para Android, el App Group ID debe coincidir con el nombre del SharedPreferences
      await HomeWidget.setAppGroupId('group.com.rutinadiaria.widgets');
    } catch (e) {
      debugPrint('Error inicializando widgets: $e');
    }
  }

  /// Actualiza el widget con la información de la racha y próxima rutina.
  Future<void> updateWidget({
    required int streakDays,
    String? nextRoutineName,
    String? nextRoutineTime,
  }) async {
    try {
      debugPrint('[Widget] Actualizando widget - Racha: $streakDays días');
      debugPrint(
        '[Widget] Próxima rutina: $nextRoutineName a las $nextRoutineTime',
      );

      // Guardar datos del widget
      await HomeWidget.saveWidgetData<int>(_streakKey, streakDays);
      debugPrint('[Widget] Racha guardada: $streakDays');

      if (nextRoutineName != null && nextRoutineName.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>(
          _nextRoutineKey,
          nextRoutineName,
        );
        debugPrint('[Widget] Próxima rutina guardada: $nextRoutineName');
      } else {
        await HomeWidget.saveWidgetData<String>(_nextRoutineKey, '');
        debugPrint('[Widget] Próxima rutina vacía');
      }

      if (nextRoutineTime != null && nextRoutineTime.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>(
          _nextRoutineTimeKey,
          nextRoutineTime,
        );
        debugPrint('[Widget] Hora guardada: $nextRoutineTime');
      } else {
        await HomeWidget.saveWidgetData<String>(_nextRoutineTimeKey, '');
        debugPrint('[Widget] Hora vacía');
      }

      // Forzar actualización del widget
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: 'RutinaDiariaWidget',
        iOSName: 'RutinaDiariaWidget',
      );
      debugPrint('[Widget] Widget actualizado exitosamente');
    } catch (e, stackTrace) {
      debugPrint('[Widget] Error actualizando widget: $e');
      debugPrint('[Widget] Stack trace: $stackTrace');
    }
  }
}
