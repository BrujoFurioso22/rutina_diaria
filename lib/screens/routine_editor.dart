import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reminder_repeat.dart';
import '../models/routine_model.dart';
import '../models/task_model.dart';
import '../providers/routine_controller.dart';
import '../utils/app_theme.dart';
import '../utils/icon_mapper.dart';
import '../widgets/custom_card.dart';
import '../widgets/pastel_toggle.dart';
import 'icon_picker_screen.dart';
import 'color_picker_screen.dart';

/// Formulario para crear o editar rutinas personalizadas.
class RoutineEditorScreen extends ConsumerStatefulWidget {
  const RoutineEditorScreen({super.key, this.routine});

  final Routine? routine;

  @override
  ConsumerState<RoutineEditorScreen> createState() =>
      _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final List<TextEditingController> _taskControllers = [];
  final List<bool> _taskOptionalFlags = [];
  final List<TimeOfDay?> _taskReminderTimes = [];
  int _selectedColor = AppColors.primary.value;
  String _selectedIcon = 'sunny';
  TimeOfDay? _reminderTime;
  List<int> _selectedWeekdays = [];
  DateTime? _reminderDate;
  ReminderRepeat? _reminderRepeat;

  @override
  void initState() {
    super.initState();
    final routine = widget.routine;
    _nameController = TextEditingController(text: routine?.name ?? '');
    if (routine != null) {
      _selectedColor = routine.colorHex;
      _selectedIcon = routine.iconName;
      _reminderTime = routine.reminderTime;
      _selectedWeekdays = [...routine.reminderWeekdays];
      _reminderDate = routine.reminderDate;
      _reminderRepeat = routine.reminderRepeat;
      for (final task in routine.tasks) {
        _taskControllers.add(TextEditingController(text: task.title));
        _taskOptionalFlags.add(task.isOptional);
        _taskReminderTimes.add(task.reminderTime);
      }
    }
    if (_taskControllers.isEmpty) {
      _addTaskField();
      _addTaskField();
    } else {
      // Asegurar que todas las tareas tengan un slot para reminderTime
      while (_taskReminderTimes.length < _taskControllers.length) {
        _taskReminderTimes.add(null);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final controller in _taskControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.routine != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar rutina' : 'Nueva rutina'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonal(
              onPressed: _onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.25),
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: AppColors.primary.withOpacity(0.4),
                    width: 1,
                  ),
                ),
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la rutina',
                          hintText: 'Ej. Mañana productiva',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa un nombre para la rutina';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Icono',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: [
                          ...IconMapper.availableIconNames().map((name) {
                            final selected = name == _selectedIcon;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedIcon = name),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary.withOpacity(0.15)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.outline.withOpacity(0.6),
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Icon(
                                  IconMapper.resolve(name),
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            );
                          }),
                          // Mostrar el icono seleccionado si no está en la lista inicial
                          if (!IconMapper.availableIconNames().contains(
                            _selectedIcon,
                          ))
                            GestureDetector(
                              onTap: () => _showIconPicker(context),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  IconMapper.resolve(_selectedIcon),
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          GestureDetector(
                            onTap: () => _showIconPicker(context),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.accent.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.more_horiz_rounded,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Color',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: [
                          ..._palette.map(
                            (color) => GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedColor = color.value),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedColor == color.value
                                        ? AppColors.textSecondary.withOpacity(0.5)
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Mostrar el color seleccionado si no está en la lista inicial
                          if (!_palette.any((c) => c.value == _selectedColor))
                            GestureDetector(
                              onTap: () => _showColorPicker(context),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Color(_selectedColor),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.textSecondary.withOpacity(0.5),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(
                                        _selectedColor,
                                      ).withOpacity(0.5),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          GestureDetector(
                            onTap: () => _showColorPicker(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accent.withOpacity(0.6),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.more_horiz_rounded,
                                color: AppColors.accent,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Días del recordatorio diario',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _weekdayOrder
                            .map(
                              (day) {
                                final isSelected = _selectedWeekdays.contains(day);
                                return GestureDetector(
                                  onTap: () => _toggleWeekday(day),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withOpacity(0.2)
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.outline.withOpacity(0.6),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      _weekdayName(day),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            fontSize: 13,
                                          ),
                                    ),
                                  ),
                                );
                              },
                            )
                            .toList(),
                      ),
                      if (_selectedWeekdays.isNotEmpty &&
                          _reminderTime == null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Selecciona una hora para los días elegidos.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hora del recordatorio diario'),
                        subtitle: Text(
                          _reminderTime != null
                              ? 'Programado a las ${_reminderTime!.format(context)}'
                              : 'Sin hora definida',
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: _pickReminderTime,
                          child: Text(
                            _reminderTime != null ? 'Cambiar' : 'Seleccionar',
                          ),
                        ),
                      ),
                      if (_reminderTime != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setState(() {
                              _reminderTime = null;
                              _selectedWeekdays = [];
                            }),
                            child: const Text('Quitar recordatorio diario'),
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        'Recordatorio con fecha específica',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Fecha y hora específica'),
                        subtitle: Text(
                          _reminderDate != null
                              ? '${_formatDate(_reminderDate!)} a las ${_formatTime(_reminderDate!)}'
                              : 'Ej: "Pagar tarjeta" - 12 de diciembre a las 10:00 AM',
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: _pickReminderDate,
                          child: Text(
                            _reminderDate != null ? 'Cambiar' : 'Seleccionar',
                          ),
                        ),
                      ),
                      if (_reminderDate != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setState(() {
                              _reminderDate = null;
                            }),
                            child: const Text('Quitar fecha'),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Pasos o tareas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Column(
                  children: List.generate(_taskControllers.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == _taskControllers.length - 1 ? 0 : 12,
                      ),
                      child: CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accent,
                                            fontSize: 14,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _taskControllers[index],
                                    decoration: InputDecoration(
                                      hintText: 'Describe la tarea...',
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.outline.withOpacity(
                                            0.5,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.outline.withOpacity(
                                            0.5,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                          color: AppColors.primary.withOpacity(
                                            0.7,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.only(
                                        bottom: 8,
                                      ),
                                      isDense: true,
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                    maxLines: null,
                                    minLines: 1,
                                    textInputAction: TextInputAction.newline,
                                    keyboardType: TextInputType.multiline,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Este paso no puede estar vacío';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.textSecondary.withOpacity(
                                      0.6,
                                    ),
                                    size: 20,
                                  ),
                                  onPressed: () => _removeTask(index),
                                  tooltip: 'Eliminar paso',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: PastelToggle(
                                    value: _taskOptionalFlags[index],
                                    onChanged: (value) {
                                      setState(() {
                                        _taskOptionalFlags[index] = value;
                                      });
                                    },
                                    title: const Text('Opcional'),
                                    backgroundColor: AppColors.accent.withOpacity(
                                      0.18,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    compact: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    title: Text(
                                      _taskReminderTimes[index] != null
                                          ? 'Hora: ${_taskReminderTimes[index]!.format(context)}'
                                          : 'Sin hora',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    trailing: FilledButton.tonal(
                                      onPressed: () => _pickTaskReminderTime(index),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        minimumSize: const Size(0, 32),
                                      ),
                                      child: Text(
                                        _taskReminderTimes[index] != null ? 'Cambiar' : 'Hora',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _addTaskField,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Agregar paso'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addTaskField() {
    setState(() {
      _taskControllers.add(TextEditingController());
      _taskOptionalFlags.add(false);
      _taskReminderTimes.add(null);
    });
  }

  void _removeTask(int index) {
    if (_taskControllers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe existir al menos un paso.')),
      );
      return;
    }
    setState(() {
      _taskControllers.removeAt(index);
      _taskOptionalFlags.removeAt(index);
      if (index < _taskReminderTimes.length) {
        _taskReminderTimes.removeAt(index);
      }
    });
  }

  Future<void> _pickReminderTime() async {
    final initial = _reminderTime ?? const TimeOfDay(hour: 19, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Hora del recordatorio diario',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(
          context,
        ).copyWith(alwaysUse24HourFormat: false);
        final baseTheme = ThemeData.light();
        return MediaQuery(
          data: mediaQuery,
          child: Theme(
            data: baseTheme,
            child: Localizations.override(
              context: context,
              locale: const Locale('en', 'US'),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _pickTaskReminderTime(int taskIndex) async {
    final initial = _taskReminderTimes[taskIndex] ?? const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'Hora del recordatorio para esta tarea',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false);
        final baseTheme = ThemeData.light();
        return MediaQuery(
          data: mediaQuery,
          child: Theme(
            data: baseTheme,
            child: Localizations.override(
              context: context,
              locale: const Locale('en', 'US'),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _taskReminderTimes[taskIndex] = picked;
      });
    } else if (_taskReminderTimes[taskIndex] != null) {
      // Si canceló pero quiere quitar la hora
      setState(() {
        _taskReminderTimes[taskIndex] = null;
      });
    }
  }

  void _toggleWeekday(int day) {
    setState(() {
      if (_selectedWeekdays.contains(day)) {
        _selectedWeekdays.remove(day);
      } else {
        _selectedWeekdays.add(day);
      }
      _selectedWeekdays.sort();
    });
  }

  Future<void> _pickReminderDate() async {
    final now = DateTime.now();
    final initial = _reminderDate ?? now;
    
    // Seleccionar fecha
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      locale: const Locale('es'),
    );
    
    if (pickedDate == null) return;
    
    // Seleccionar hora
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Hora del recordatorio',
      cancelText: 'Cancelar',
      confirmText: 'Guardar',
      initialEntryMode: TimePickerEntryMode.dial,
    );
    
    if (pickedTime != null) {
      setState(() {
        _reminderDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _showIconPicker(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IconPickerScreen(
          selectedIconName: _selectedIcon,
          onIconSelected: (iconName) {
            setState(() {
              _selectedIcon = iconName;
            });
          },
        ),
      ),
    );
  }

  Future<void> _showColorPicker(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ColorPickerScreen(
          selectedColorValue: _selectedColor,
          onColorSelected: (colorValue) {
            setState(() {
              _selectedColor = colorValue;
            });
          },
        ),
      ),
    );
  }

  static const List<int> _weekdayOrder = <int>[
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  String _weekdayName(int weekday) {
    const names = <int, String>{
      DateTime.monday: 'Lun',
      DateTime.tuesday: 'Mar',
      DateTime.wednesday: 'Mié',
      DateTime.thursday: 'Jue',
      DateTime.friday: 'Vie',
      DateTime.saturday: 'Sáb',
      DateTime.sunday: 'Dom',
    };
    return names[weekday] ?? '';
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedWeekdays.isNotEmpty && _reminderTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una hora para los días del recordatorio.'),
        ),
      );
      return;
    }
    final tasks = <RoutineTask>[];
    final previousTasks = widget.routine?.tasks ?? [];
    for (var i = 0; i < _taskControllers.length; i++) {
      final text = _taskControllers[i].text.trim();
      if (text.isEmpty) {
        continue;
      }
      final taskReminderTime = i < _taskReminderTimes.length 
          ? _taskReminderTimes[i] 
          : null;
      final updatedTask =
          (i < previousTasks.length
                  ? previousTasks[i].copyWith()
                  : RoutineTask.create(title: text, reminderTime: taskReminderTime))
              .copyWith(
                title: text, 
                isOptional: _taskOptionalFlags[i],
                reminderTime: taskReminderTime,
                removeReminderTime: taskReminderTime == null && i < previousTasks.length,
              );
      tasks.add(updatedTask);
    }

    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un paso a la rutina.')),
      );
      return;
    }

    final controller = ref.read(routineControllerProvider.notifier);
    final now = DateTime.now();
    final routine = widget.routine == null
        ? Routine.create(
            name: _nameController.text.trim(),
            tasks: tasks,
            colorHex: _selectedColor,
            iconName: _selectedIcon,
            reminderTime: _reminderTime,
            reminderWeekdays: _selectedWeekdays,
            reminderDate: _reminderDate,
            reminderRepeat: _reminderRepeat,
          )
        : widget.routine!.copyWith(
            name: _nameController.text.trim(),
            tasks: tasks,
            colorHex: _selectedColor,
            iconName: _selectedIcon,
            reminderTime: _reminderTime,
            reminderWeekdays: _selectedWeekdays,
            reminderDate: _reminderDate,
            reminderRepeat: _reminderRepeat,
            removeReminderTime: _reminderTime == null,
            removeReminderWeekdays: _selectedWeekdays.isEmpty,
            removeReminderDate: _reminderDate == null,
            removeReminderRepeat: _reminderRepeat == null,
            updatedAt: now,
          );

    await controller.addOrUpdateRoutine(routine);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.routine == null
              ? 'Rutina creada correctamente.'
              : 'Cambios guardados.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }
}

const _palette = [
  Color(0xFFC8B6FF),
  Color(0xFFFFC8DD),
  Color(0xFFBEE3FF),
  Color(0xFFB8F2E6),
  Color(0xFFFFE5B4),
  Color(0xFFD7C0FF),
];
