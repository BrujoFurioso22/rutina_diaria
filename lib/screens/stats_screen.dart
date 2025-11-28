import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/routine_model.dart';
import '../providers/routine_controller.dart';
import '../utils/app_theme.dart';
import '../utils/icon_mapper.dart';
import '../utils/streak_levels.dart';
import '../widgets/custom_card.dart';

/// Visualiza el progreso histórico, rachas y hábitos más frecuentes.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(routineControllerProvider);
    final controller = ref.read(routineControllerProvider.notifier);
    final completions = controller.completionsByRoutine();
    final weekStart = _weekStart(DateTime.now());
    final weekEntries = controller.entriesForWeek(weekStart);
    final totalWeek = weekEntries.length;
    final streak = state.streakDays;
    final hasCompletedToday = controller.hasCompletedToday();
    final streakLevel = StreakLevel.getLevel(streak);
    final nextLevel = StreakLevel.getNextLevel(streak);
    final upcomingLevels = StreakLevel.getUpcomingLevels(
      streak,
    ).take(3).toList();

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            CustomCard(
              backgroundColor: AppColors.primary.withOpacity(0.28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Color(streakLevel.color).withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            streakLevel.emoji,
                            style: TextStyle(fontSize: streakLevel.size * 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Racha actual',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$streak día${streak == 1 ? '' : 's'} seguidos',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (streakLevel.name != 'Iniciando')
                              Text(
                                streakLevel.name,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Color(streakLevel.color),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    StreakLevel.getMotivationalMessage(
                      streak,
                      hasCompletedToday,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (upcomingLevels.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Próximos niveles',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ...upcomingLevels.map((level) {
                            final isNext = level.days == nextLevel?.days;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Text(
                                    level.emoji,
                                    style: TextStyle(
                                      fontSize: level.size * 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${level.days} días - ${level.name}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isNext
                                                ? AppColors.primary
                                                : AppColors.textSecondary,
                                            fontWeight: isNext
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                    ),
                                  ),
                                  if (isNext)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Próximo',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withOpacity(0.3),
                    ),
                    child: const Center(child: Text('📅')),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semana en curso',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalWeek rutina${totalWeek == 1 ? '' : 's'} completada${totalWeek == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Progreso semanal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: _WeeklyBars(weekStart: weekStart, entries: weekEntries),
            ),
            const SizedBox(height: 16),
            Text(
              'Rutinas favoritas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (completions.isEmpty)
              const CustomCard(
                child: Text(
                  'Aún no hay suficientes datos. Completa tus rutinas para ver estadísticas detalladas.',
                ),
              )
            else
              Column(
                children: completions.entries.map((entry) {
                  final routine = state.routines.firstWhere(
                    (element) => element.id == entry.key,
                  );
                  final color = Color(routine.colorHex);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CustomCard(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              IconMapper.resolve(routine.iconName),
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  routine.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  '${entry.value} vez${entry.value == 1 ? '' : 'es'} completada${entry.value == 1 ? '' : 's'}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  DateTime _weekStart(DateTime date) {
    final weekday = date.weekday;
    return DateUtils.dateOnly(
      date,
    ).subtract(Duration(days: weekday - DateTime.monday));
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.weekStart, required this.entries});

  final DateTime weekStart;
  final List<RoutineHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat.E('es');
    final days = List<DateTime>.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
    final counts = <DateTime, int>{};
    for (final entry in entries) {
      final day = DateUtils.dateOnly(entry.completedAt);
      counts.update(day, (value) => value + 1, ifAbsent: () => 1);
    }

    final maxCount = counts.values.isEmpty
        ? 1
        : counts.values.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 70,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days.map((day) {
                  final count = counts[day] ?? 0;
                  final heightFactor = count / maxCount;
                  final barHeight = (heightFactor.clamp(0.0, 1.0) * 60).clamp(
                    4.0,
                    60.0,
                  );
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        height: barHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.primary.withOpacity(
                            count > 0 ? 0.75 : 0.25,
                          ),
                          boxShadow: [
                            if (count > 0)
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 8),
                              ),
                          ],
                        ),
                        alignment: Alignment.bottomCenter,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 320),
                          opacity: count > 0 ? 1 : 0,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            height: 3,
                            width: 12,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: days.map((day) {
              final count = counts[day] ?? 0;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      formatter.format(day).substring(0, 2).toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '$count',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
