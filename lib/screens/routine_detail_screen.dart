import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/routine_model.dart';
import '../providers/routine_controller.dart';
import '../utils/app_theme.dart';
import '../utils/icon_mapper.dart';
import '../widgets/custom_card.dart';
import 'routine_player.dart';

/// Pantalla de detalle de una rutina que muestra información e historial.
class RoutineDetailScreen extends ConsumerWidget {
  const RoutineDetailScreen({super.key, required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(routineControllerProvider);
    final historyEntries =
        state.history.where((entry) => entry.routineId == routine.id).toList()
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    // Agrupar entradas por día
    final groupedHistory = <DateTime, List<RoutineHistoryEntry>>{};
    for (final entry in historyEntries) {
      final day = DateTime(
        entry.completedAt.year,
        entry.completedAt.month,
        entry.completedAt.day,
      );
      if (!groupedHistory.containsKey(day)) {
        groupedHistory[day] = [];
      }
      groupedHistory[day]!.add(entry);
    }

    // Ordenar los días de más reciente a más antiguo
    final sortedDays = groupedHistory.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final baseColor = Color(routine.colorHex);
    final completedCount = historyEntries.length;

    return Scaffold(
      appBar: AppBar(title: Text(routine.name)),
      body: Container(
        color: AppColors.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información de la rutina
              CustomCard(
                padding: const EdgeInsets.all(16),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: baseColor.withOpacity(0.25),
                  width: 1,
                ),
                shadows: [
                  BoxShadow(
                    color: baseColor.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 12),
                  ),
                ],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: baseColor.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            IconMapper.resolve(routine.iconName),
                            color: baseColor,
                            size: 32,
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
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${routine.tasks.length} paso${routine.tasks.length == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Botón grande para iniciar/reanudar rutina
                    Builder(
                      builder: (context) {
                        final hasProgress = state.allProgress.any(
                          (p) =>
                              p.routineId == routine.id &&
                              p.completedTasks.isNotEmpty,
                        );
                        return SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RoutinePlayerScreen(routine: routine),
                                ),
                              );
                            },
                            icon: Icon(
                              hasProgress
                                  ? Icons.play_circle_outline_rounded
                                  : Icons.play_arrow_rounded,
                              size: 24,
                            ),
                            label: Text(
                              hasProgress
                                  ? 'Reanudar rutina'
                                  : 'Iniciar rutina',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: baseColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoItem(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Completada',
                            value:
                                '$completedCount vez${completedCount == 1 ? '' : 'es'}',
                            color: baseColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoItem(
                            icon: Icons.schedule_rounded,
                            label: 'Recordatorio',
                            value: routine.formattedReminder,
                            color: baseColor,
                          ),
                        ),
                      ],
                    ),
                    if (routine.lastCompleted != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: baseColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 20,
                              color: baseColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Última vez: ${DateFormat('d MMM yyyy', 'es').format(routine.lastCompleted!)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: baseColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Historial
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historial',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '$completedCount completado${completedCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (historyEntries.isEmpty)
                CustomCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aún no has completado esta rutina',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...sortedDays.map((day) {
                  final dayEntries = groupedHistory[day]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado del día
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Text(
                          _formatDayHeader(day),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: baseColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      // Entradas del día
                      ...dayEntries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CustomCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: baseColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.access_time_rounded,
                                        color: baseColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Completado a las ${DateFormat('HH:mm', 'es').format(entry.completedAt)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // Mostrar tareas completadas
                                const SizedBox(height: 12),
                                ...routine.tasks.asMap().entries.map((
                                  taskEntry,
                                ) {
                                  final taskIndex = taskEntry.key;
                                  final task = taskEntry.value;
                                  final wasCompleted =
                                      entry.completedTaskIndices != null &&
                                      entry.completedTaskIndices!.contains(
                                        taskIndex,
                                      );

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        Icon(
                                          wasCompleted
                                              ? Icons.check_circle_rounded
                                              : Icons
                                                    .radio_button_unchecked_rounded,
                                          size: 18,
                                          color: wasCompleted
                                              ? baseColor
                                              : AppColors.textSecondary
                                                    .withOpacity(0.4),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            task.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: wasCompleted
                                                      ? AppColors.textPrimary
                                                      : AppColors.textSecondary
                                                            .withOpacity(0.6),
                                                  decoration: wasCompleted
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : TextDecoration.none,
                                                ),
                                          ),
                                        ),
                                        if (task.isOptional)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.textSecondary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Opcional',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 10,
                                                  ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }),
                                // Mostrar nota si existe
                                if (entry.note != null &&
                                    entry.note!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.outline.withOpacity(
                                          0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.attach_file_rounded,
                                          size: 18,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            entry.note!,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDayHeader(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dayDate = DateTime(day.year, day.month, day.day);

    if (dayDate == today) {
      return 'Hoy';
    } else if (dayDate == yesterday) {
      return 'Ayer';
    } else {
      return DateFormat('EEEE, d MMM yyyy', 'es').format(day);
    }
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
