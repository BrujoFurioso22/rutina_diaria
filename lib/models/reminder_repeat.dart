/// Modelo para manejar repeticiones avanzadas de recordatorios.
class ReminderRepeat {
  const ReminderRepeat({
    required this.type,
    this.weekdays,
    this.monthDay,
    this.isLastDayOfMonth = false,
    this.everyNDays,
    this.everyNWeeks,
  });

  /// Tipo de repetición
  final ReminderRepeatType type;

  /// Días de la semana para repetición semanal (1=Lunes, 7=Domingo)
  final List<int>? weekdays;

  /// Día del mes para repetición mensual (1-31)
  final int? monthDay;

  /// Si es true, se repite el último día del mes
  final bool isLastDayOfMonth;

  /// Cada N días para repetición personalizada
  final int? everyNDays;

  /// Cada N semanas para repetición personalizada
  final int? everyNWeeks;

  ReminderRepeat copyWith({
    ReminderRepeatType? type,
    List<int>? weekdays,
    int? monthDay,
    bool? isLastDayOfMonth,
    int? everyNDays,
    int? everyNWeeks,
    bool removeWeekdays = false,
    bool removeMonthDay = false,
    bool removeEveryNDays = false,
    bool removeEveryNWeeks = false,
  }) {
    return ReminderRepeat(
      type: type ?? this.type,
      weekdays: removeWeekdays ? null : (weekdays ?? this.weekdays),
      monthDay: removeMonthDay ? null : (monthDay ?? this.monthDay),
      isLastDayOfMonth: isLastDayOfMonth ?? this.isLastDayOfMonth,
      everyNDays: removeEveryNDays ? null : (everyNDays ?? this.everyNDays),
      everyNWeeks: removeEveryNWeeks ? null : (everyNWeeks ?? this.everyNWeeks),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.name,
      'weekdays': weekdays,
      'monthDay': monthDay,
      'isLastDayOfMonth': isLastDayOfMonth,
      'everyNDays': everyNDays,
      'everyNWeeks': everyNWeeks,
    };
  }

  factory ReminderRepeat.fromMap(Map<String, dynamic> map) {
    return ReminderRepeat(
      type: ReminderRepeatType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReminderRepeatType.none,
      ),
      weekdays: map['weekdays'] != null
          ? (map['weekdays'] as List<dynamic>).map((e) => e as int).toList()
          : null,
      monthDay: map['monthDay'] as int?,
      isLastDayOfMonth: (map['isLastDayOfMonth'] as bool?) ?? false,
      everyNDays: map['everyNDays'] as int?,
      everyNWeeks: map['everyNWeeks'] as int?,
    );
  }

  /// Crea una repetición diaria
  factory ReminderRepeat.daily() {
    return const ReminderRepeat(type: ReminderRepeatType.daily);
  }

  /// Crea una repetición semanal para los días especificados
  factory ReminderRepeat.weekly(List<int> weekdays) {
    return ReminderRepeat(
      type: ReminderRepeatType.weekly,
      weekdays: weekdays,
    );
  }

  /// Crea una repetición mensual
  factory ReminderRepeat.monthly({
    int? monthDay,
    bool isLastDayOfMonth = false,
  }) {
    return ReminderRepeat(
      type: ReminderRepeatType.monthly,
      monthDay: monthDay,
      isLastDayOfMonth: isLastDayOfMonth,
    );
  }

  /// Crea una repetición personalizada (cada N días)
  factory ReminderRepeat.customDays(int everyNDays) {
    return ReminderRepeat(
      type: ReminderRepeatType.custom,
      everyNDays: everyNDays,
    );
  }

  /// Crea una repetición personalizada (cada N semanas)
  factory ReminderRepeat.customWeeks(int everyNWeeks) {
    return ReminderRepeat(
      type: ReminderRepeatType.custom,
      everyNWeeks: everyNWeeks,
    );
  }

  /// Sin repetición (recordatorio único)
  factory ReminderRepeat.none() {
    return const ReminderRepeat(type: ReminderRepeatType.none);
  }

  /// Calcula la próxima fecha basada en el tipo de repetición
  DateTime? getNextDate(DateTime fromDate) {
    switch (type) {
      case ReminderRepeatType.none:
        return null;
      case ReminderRepeatType.daily:
        return fromDate.add(const Duration(days: 1));
      case ReminderRepeatType.weekly:
        if (weekdays == null || weekdays!.isEmpty) return null;
        var nextDate = fromDate;
        for (var i = 0; i < 7; i++) {
          nextDate = nextDate.add(const Duration(days: 1));
          if (weekdays!.contains(nextDate.weekday)) {
            return nextDate;
          }
        }
        return null;
      case ReminderRepeatType.monthly:
        var nextDate = fromDate;
        if (isLastDayOfMonth) {
          // Buscar el último día del mes siguiente
          nextDate = DateTime(nextDate.year, nextDate.month + 1, 0);
        } else if (monthDay != null) {
          // Buscar el mismo día del mes siguiente
          try {
            nextDate = DateTime(nextDate.year, nextDate.month + 1, monthDay!);
          } catch (e) {
            // Si el mes siguiente no tiene ese día, usar el último día
            nextDate = DateTime(nextDate.year, nextDate.month + 1, 0);
          }
        }
        return nextDate.isAfter(fromDate) ? nextDate : null;
      case ReminderRepeatType.custom:
        if (everyNDays != null) {
          return fromDate.add(Duration(days: everyNDays!));
        } else if (everyNWeeks != null) {
          return fromDate.add(Duration(days: everyNWeeks! * 7));
        }
        return null;
    }
  }
}

/// Tipos de repetición disponibles
enum ReminderRepeatType {
  none, // Sin repetición (recordatorio único)
  daily, // Diario
  weekly, // Semanal (días específicos)
  monthly, // Mensual
  custom, // Personalizada (cada N días o semanas)
}

