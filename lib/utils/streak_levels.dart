/// Sistema de niveles de racha con emojis y mensajes motivacionales.
class StreakLevel {
  StreakLevel({
    required this.days,
    required this.emoji,
    required this.name,
    required this.color,
    required this.size,
  });

  final int days;
  final String emoji;
  final String name;
  final int color; // Color en hex
  final double size; // Tamaño del emoji

  static final List<StreakLevel> levels = [
    StreakLevel(
      days: 0,
      emoji: '💤',
      name: 'Iniciando',
      color: 0xFF9E9E9E,
      size: 32.0,
    ),
    StreakLevel(
      days: 1,
      emoji: '🕯️',
      name: 'Primera chispa',
      color: 0xFFFFB74D,
      size: 36.0,
    ),
    StreakLevel(
      days: 5,
      emoji: '🔥',
      name: 'En llamas',
      color: 0xFFFF6B35,
      size: 40.0,
    ),
    StreakLevel(
      days: 15,
      emoji: '🔥',
      name: 'Inferno',
      color: 0xFFFF3D00,
      size: 48.0,
    ),
    StreakLevel(
      days: 40,
      emoji: '🔥',
      name: 'Maestro del fuego',
      color: 0xFFD32F2F,
      size: 56.0,
    ),
  ];

  /// Obtiene el nivel actual basado en los días de racha.
  static StreakLevel getLevel(int streakDays) {
    if (streakDays <= 0) {
      return levels[0];
    }
    for (var i = levels.length - 1; i >= 0; i--) {
      if (streakDays >= levels[i].days) {
        return levels[i];
      }
    }
    return levels[0];
  }

  /// Obtiene el siguiente nivel a desbloquear.
  static StreakLevel? getNextLevel(int streakDays) {
    for (final level in levels) {
      if (streakDays < level.days) {
        return level;
      }
    }
    return null; // Ya alcanzó el nivel máximo
  }

  /// Obtiene todos los niveles futuros a desbloquear.
  static List<StreakLevel> getUpcomingLevels(int streakDays) {
    return levels.where((level) => level.days > streakDays).toList();
  }

  /// Obtiene el mensaje motivacional según el estado de la racha.
  static String getMotivationalMessage(int streakDays, bool hasCompletedToday) {
    if (streakDays == 0) {
      return 'Comienza tu primera rutina para iniciar tu racha.';
    }

    if (!hasCompletedToday) {
      if (streakDays == 1) {
        return 'Tienes $streakDays día de racha. ¡Completa una rutina hoy para mantenerla!';
      }
      return 'Tienes $streakDays días de racha. ¡Completa una rutina hoy para mantenerla!';
    }

    final level = getLevel(streakDays);
    switch (streakDays) {
      case 1:
        return '¡Excelente! Llevas $streakDays día seguido. ¡Sigue así!';
      case 2:
      case 3:
      case 4:
        return '🔥 Llevas $streakDays días seguidos cumpliendo tus rutinas.';
      default:
        return '🔥 ¡Increíble! Llevas $streakDays días seguidos. ¡Eres ${level.name}!';
    }
  }
}
