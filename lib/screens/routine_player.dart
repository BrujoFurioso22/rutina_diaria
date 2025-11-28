import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/routine_model.dart';
import '../providers/routine_controller.dart';
import '../utils/app_theme.dart';
import '../widgets/congratulation_modal.dart';
import '../widgets/progress_bar.dart';

/// Pantalla de ejecución paso a paso con feedback motivacional.
class RoutinePlayerScreen extends ConsumerStatefulWidget {
  const RoutinePlayerScreen({super.key, required this.routine});

  final Routine routine;

  @override
  ConsumerState<RoutinePlayerScreen> createState() =>
      _RoutinePlayerScreenState();
}

class _RoutinePlayerScreenState extends ConsumerState<RoutinePlayerScreen> {
  late List<bool> _completed;
  late List<RoutineStep> _steps;
  bool _celebrated = false;
  late String _phrase;
  Map<int, DateTime> _taskCompletionTimes = {};
  DateTime? _startedAt;
  bool _hasLoadedProgress = false;

  @override
  void initState() {
    super.initState();
    _completed = List<bool>.filled(widget.routine.tasks.length, false);
    _steps = widget.routine.tasks
        .map(
          (task) => RoutineStep(title: task.title, optional: task.isOptional),
        )
        .toList();
    _phrase = randomPhrase();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedProgress) {
      _loadProgress();
    }
  }

  Future<void> _loadProgress() async {
    final savedProgress = ref
        .read(routineControllerProvider.notifier)
        .loadProgress(widget.routine.id);

    if (savedProgress != null) {
      setState(() {
        _startedAt = savedProgress.startedAt;
        _taskCompletionTimes = Map<int, DateTime>.from(
          savedProgress.completedTasks,
        );
        for (var entry in _taskCompletionTimes.entries) {
          if (entry.key < _completed.length) {
            _completed[entry.key] = true;
          }
        }
        _hasLoadedProgress = true;
      });
    } else {
      setState(() {
        _startedAt = DateTime.now();
        _hasLoadedProgress = true;
      });
    }
  }

  Future<void> _saveProgress() async {
    if (!_hasLoadedProgress) return;

    final completedTasks = <int, DateTime>{};
    for (var i = 0; i < _completed.length; i++) {
      if (_completed[i] && _taskCompletionTimes.containsKey(i)) {
        completedTasks[i] = _taskCompletionTimes[i]!;
      }
    }

    final progress = RoutineProgress.create(
      routineId: widget.routine.id,
      completedTasks: completedTasks,
      startedAt: _startedAt,
    );

    await ref.read(routineControllerProvider.notifier).saveProgress(progress);
  }

  @override
  void dispose() {
    _saveProgress();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _steps.isEmpty
        ? 0.0
        : _completed.where((value) => value).length / _steps.length;

    return WillPopScope(
      onWillPop: () async {
        await _saveProgress();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.routine.name),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                if (value == 'cancel') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cancelar rutina'),
                      content: const Text(
                        '¿Estás seguro de que quieres cancelar esta rutina? Se perderá el progreso actual.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Sí, cancelar'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(routineControllerProvider.notifier)
                        .deleteProgress(widget.routine.id);
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                } else if (value == 'restart') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reiniciar rutina'),
                      content: const Text(
                        '¿Estás seguro de que quieres reiniciar esta rutina? Se perderá el progreso actual.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Sí, reiniciar'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(routineControllerProvider.notifier)
                        .deleteProgress(widget.routine.id);
                    if (mounted) {
                      setState(() {
                        _completed = List<bool>.filled(
                          widget.routine.tasks.length,
                          false,
                        );
                        _taskCompletionTimes = {};
                        _startedAt = DateTime.now();
                        _celebrated = false;
                      });
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'restart',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Reiniciar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cancelar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.35),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RoutineProgressBar(progress: progress),
                  const SizedBox(height: 8),
                  Text(
                    _steps.isEmpty
                        ? 'Agrega pasos a la rutina para comenzar.'
                        : '${_completed.where((value) => value).length} de ${_steps.length} pasos completados',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _phrase,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  final isDone = _completed[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(26),
                    onTap: () => _toggleStep(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.only(top: index == 0 ? 0 : 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: isDone
                              ? AppColors.accent.withOpacity(0.45)
                              : AppColors.primary.withOpacity(0.08),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDone
                                ? AppColors.accent.withOpacity(0.25)
                                : AppColors.primary.withOpacity(0.13),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isDone
                                  ? LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.accent,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isDone
                                  ? null
                                  : AppColors.primary.withOpacity(0.08),
                              border: Border.all(
                                color: isDone
                                    ? Colors.transparent
                                    : AppColors.primary.withOpacity(0.35),
                                width: 1.4,
                              ),
                            ),
                            child: Icon(
                              isDone
                                  ? Icons.emoji_emotions_rounded
                                  : Icons.circle_outlined,
                              color: isDone
                                  ? Colors.white
                                  : AppColors.primary.withOpacity(0.55),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        decoration: isDone
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                ),
                                if (isDone &&
                                    _taskCompletionTimes.containsKey(index))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Completado a las ${DateFormat('HH:mm').format(_taskCompletionTimes[index]!)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                    ),
                                  ),
                                if (step.optional)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withOpacity(
                                          0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        'Paso opcional',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemCount: _steps.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStep(int index) async {
    final now = DateTime.now();
    setState(() {
      if (_completed[index]) {
        // Desmarcar: eliminar el timestamp
        _taskCompletionTimes.remove(index);
        _completed[index] = false;
      } else {
        // Marcar: guardar el timestamp
        _taskCompletionTimes[index] = now;
        _completed[index] = true;
      }
    });

    // Guardar progreso después de cada cambio
    await _saveProgress();

    if (ref.read(routineControllerProvider).vibrationEnabled) {
      await HapticFeedback.lightImpact();
    }
    // Verificar si todos los pasos obligatorios están completados
    final allRequiredCompleted = _steps.asMap().entries.every((entry) {
      final index = entry.key;
      final step = entry.value;
      // Si es opcional, no cuenta para completar la rutina
      if (step.optional) {
        return true;
      }
      // Si es obligatorio, debe estar completado
      return _completed[index];
    });

    if (allRequiredCompleted && !_celebrated) {
      _celebrated = true;
      if (!mounted) return;
      String? savedNote;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CongratulationModal(
          message:
              '¡Excelente! Has completado tu rutina de ${widget.routine.name.toLowerCase()}. ¡Sigue así!',
          streakText:
              '🔥 Llevas ${ref.read(routineControllerProvider).streakDays} día(s) seguidos cumpliendo rutinas.',
          onFinish: (note) {
            savedNote = note;
          },
        ),
      );
      if (!mounted) return;
      // Obtener los índices de las tareas completadas
      final completedIndices = <int>[];
      for (var i = 0; i < _completed.length; i++) {
        if (_completed[i]) {
          completedIndices.add(i);
        }
      }
      // Eliminar el progreso guardado ya que la rutina está completa
      await ref
          .read(routineControllerProvider.notifier)
          .deleteProgress(widget.routine.id);

      // Completar la rutina con la nota y las tareas completadas
      await ref
          .read(routineControllerProvider.notifier)
          .completeRoutine(
            widget.routine.id,
            note: savedNote,
            completedTaskIndices: completedIndices,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }
}

class RoutineStep {
  RoutineStep({required this.title, this.optional = false});

  final String title;
  final bool optional;
}

final _phrases = [
  'Un pequeño paso impulsa grandes hábitos.',
  'Respira profundo y disfruta del progreso.',
  'Lo estás haciendo muy bien, continúa.',
  'Tu constancia construye tus resultados.',
  'Cada día cuenta para tu mejor versión.',
];

String randomPhrase() {
  final random = Random();
  return _phrases[random.nextInt(_phrases.length)];
}
