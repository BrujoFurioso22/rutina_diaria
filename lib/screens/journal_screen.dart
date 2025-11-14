import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/journal_model.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_card.dart';

/// Pantalla de diario con preguntas guiadas interactivas.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  bool _isCreating = false;
  int _currentStep = 0;
  String? _selectedMood;
  Color? _selectedColor;
  String? _selectedEnergy;
  final TextEditingController _gratitudeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final PageController _pageController = PageController();
  bool _isSaving = false;
  List<JournalEntry> _entries = [];

  final List<String> _moodOptions = [
    'Excelente',
    'Bueno',
    'Regular',
    'Difícil',
  ];

  final List<Map<String, dynamic>> _energyOptions = [
    {'label': 'Alta', 'icon': Icons.battery_charging_full_rounded},
    {'label': 'Media', 'icon': Icons.battery_4_bar_rounded},
    {'label': 'Baja', 'icon': Icons.battery_1_bar_rounded},
  ];

  final List<Color> _colorOptions = [
    const Color(0xFFFF6B9D), // Rosa
    const Color(0xFFFFC107), // Amarillo
    const Color(0xFF4CAF50), // Verde
    const Color(0xFF2196F3), // Azul
    const Color(0xFF9C27B0), // Morado
    const Color(0xFFFF9800), // Naranja
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFE91E63), // Rosa fuerte
  ];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _gratitudeController.dispose();
    _noteController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _loadEntries() {
    setState(() {
      _entries = StorageService.instance.loadJournalEntries();
    });
  }

  Future<void> _saveEntry() async {
    if (_selectedMood == null ||
        _selectedColor == null ||
        _selectedEnergy == null ||
        _gratitudeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todas las preguntas'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final entry = JournalEntry.create(
        date: DateTime.now(),
        mood: _selectedMood!,
        dayColor: '#${_selectedColor!.value.toRadixString(16).substring(2)}',
        energyLevel: _selectedEnergy!,
        gratitude: _gratitudeController.text.trim(),
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      );

      await StorageService.instance.saveJournalEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Tu día ha sido guardado'),
          ),
        );
        _resetForm();
        _loadEntries();
        setState(() => _isCreating = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _selectedMood = null;
      _selectedColor = null;
      _selectedEnergy = null;
    });
    _gratitudeController.clear();
    _noteController.clear();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreating) {
      return _buildCreationView();
    }
    return _buildHistoryView();
  }

  Widget _buildHistoryView() {
    // Agrupar entradas por día
    final groupedEntries = <DateTime, List<JournalEntry>>{};
    for (final entry in _entries) {
      final day = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      if (!groupedEntries.containsKey(day)) {
        groupedEntries[day] = [];
      }
      groupedEntries[day]!.add(entry);
    }

    final sortedDays = groupedEntries.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final todayEntry = groupedEntries[todayDay]?.firstOrNull;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (todayEntry != null) {
            // Si ya hay entrada de hoy, preguntar si quiere editarla o crear nueva
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Ya tienes una anotación de hoy'),
                content: const Text(
                  '¿Quieres ver la anotación de hoy o crear una nueva?',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _viewEntry(todayEntry);
                    },
                    child: const Text('Ver la de hoy'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() => _isCreating = true);
                    },
                    child: const Text('Crear nueva'),
                  ),
                ],
              ),
            );
          } else {
            setState(() => _isCreating = true);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva anotación'),
      ),
      body: Container(
        color: AppColors.background,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.book_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mi día',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '${_entries.length} anotación${_entries.length == 1 ? '' : 'es'} guardada${_entries.length == 1 ? '' : 's'}',
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
                const SizedBox(height: 24),
                // Entrada de hoy si existe
                if (todayEntry != null) ...[
                  Text(
                    'Hoy',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildEntryCard(todayEntry),
                  const SizedBox(height: 24),
                ],
                // Historial
                if (sortedDays.isNotEmpty && (todayEntry == null || sortedDays.length > 1)) ...[
                  Text(
                    'Historial',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...sortedDays.where((day) {
                    final dayDate = DateTime(day.year, day.month, day.day);
                    return dayDate != todayDay;
                  }).map((day) {
                    final dayEntries = groupedEntries[day]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          child: Text(
                            _formatDayHeader(day),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ...dayEntries.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildEntryCard(entry),
                            )),
                      ],
                    );
                  }),
                ],
                if (_entries.isEmpty)
                  CustomCard(
                    child: Column(
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aún no has guardado ninguna anotación',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toca el botón "+" para comenzar',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreationView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva anotación'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            _resetForm();
            setState(() => _isCreating = false);
          },
        ),
      ),
      body: Container(
        color: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: List.generate(5, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                          right: index < 4 ? 8 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? AppColors.primary
                              : AppColors.outline.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Content
              Expanded(
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _pageController,
                  children: [
                    _buildMoodStep(),
                    _buildColorStep(),
                    _buildEnergyStep(),
                    _buildGratitudeStep(),
                    _buildNoteStep(),
                  ],
                ),
              ),
              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Atrás'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _currentStep < 4
                            ? _canProceed()
                                ? _nextStep
                                : null
                            : _isSaving
                                ? null
                                : _saveEntry,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _currentStep < 4 ? 'Siguiente' : 'Guardar',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard(JournalEntry entry) {
    final dayColor = entry.dayColorValue ?? AppColors.primary;
    return CustomCard(
      padding: const EdgeInsets.all(20),
      onTap: () => _viewEntry(entry),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: dayColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: dayColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getMoodIcon(entry.mood),
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.mood,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getEnergyIcon(entry.energyLevel),
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.energyLevel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          if (entry.gratitude.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.gratitude,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _viewEntry(JournalEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EntryDetailModal(entry: entry),
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

  IconData _getEnergyIcon(String energy) {
    switch (energy) {
      case 'Alta':
        return Icons.battery_charging_full_rounded;
      case 'Media':
        return Icons.battery_4_bar_rounded;
      case 'Baja':
        return Icons.battery_1_bar_rounded;
      default:
        return Icons.battery_4_bar_rounded;
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedMood != null;
      case 1:
        return _selectedColor != null;
      case 2:
        return _selectedEnergy != null;
      case 3:
        return _gratitudeController.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Widget _buildMoodStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo estuvo tu día?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Reflexiona sobre cómo te sentiste hoy',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ..._moodOptions.map((mood) {
            final isSelected = _selectedMood == mood;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedMood = mood);
                  HapticFeedback.lightImpact();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.outline.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getMoodIcon(mood),
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        mood,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildColorStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cuál fue el color de tu día?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Elige el color que mejor represente cómo te sentiste',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colorOptions.map((color) {
              final isSelected = _selectedColor == color;
              return InkWell(
                onTap: () {
                  setState(() => _selectedColor = color);
                  HapticFeedback.lightImpact();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.textPrimary
                          : Colors.transparent,
                      width: isSelected ? 3 : 0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 24,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cuál fue tu nivel de energía?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Describe cómo te sentiste de energía durante el día',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          ..._energyOptions.map((option) {
            final isSelected = _selectedEnergy == option['label'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedEnergy = option['label'] as String);
                  HapticFeedback.lightImpact();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.outline.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        option['icon'] as IconData,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        option['label'] as String,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGratitudeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Por qué estás agradecido hoy?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Escribe algo por lo que te sientas agradecido',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _gratitudeController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Escribe aquí...',
                border: InputBorder.none,
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nota adicional (opcional)',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega cualquier pensamiento o reflexión adicional',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _noteController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Escribe aquí...',
                border: InputBorder.none,
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'Excelente':
        return Icons.sentiment_very_satisfied_rounded;
      case 'Bueno':
        return Icons.sentiment_satisfied_rounded;
      case 'Regular':
        return Icons.sentiment_neutral_rounded;
      case 'Difícil':
        return Icons.sentiment_dissatisfied_rounded;
      default:
        return Icons.sentiment_neutral_rounded;
    }
  }
}

/// Modal que muestra el detalle completo de una entrada del diario.
class _EntryDetailModal extends StatelessWidget {
  const _EntryDetailModal({required this.entry});

  final JournalEntry entry;

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'Excelente':
        return Icons.sentiment_very_satisfied_rounded;
      case 'Bueno':
        return Icons.sentiment_satisfied_rounded;
      case 'Regular':
        return Icons.sentiment_neutral_rounded;
      case 'Difícil':
        return Icons.sentiment_dissatisfied_rounded;
      default:
        return Icons.sentiment_neutral_rounded;
    }
  }

  IconData _getEnergyIcon(String energy) {
    switch (energy) {
      case 'Alta':
        return Icons.battery_charging_full_rounded;
      case 'Media':
        return Icons.battery_4_bar_rounded;
      case 'Baja':
        return Icons.battery_1_bar_rounded;
      default:
        return Icons.battery_4_bar_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayColor = entry.dayColorValue ?? AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: dayColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: dayColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMM yyyy', 'es').format(entry.date),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            DateFormat('HH:mm', 'es').format(entry.date),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Estado de ánimo
                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _getMoodIcon(entry.mood),
                        size: 32,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estado de ánimo',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.mood,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Nivel de energía
                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _getEnergyIcon(entry.energyLevel),
                        size: 32,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nivel de energía',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.energyLevel,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Gratitud
                Text(
                  'Gratitud',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 24,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.gratitude,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                // Nota adicional
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Nota adicional',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note_rounded,
                          size: 24,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.note!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

