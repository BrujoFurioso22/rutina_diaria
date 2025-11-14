import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/routine_model.dart';
import '../models/task_model.dart';
import '../providers/routine_controller.dart';
import '../utils/app_theme.dart';
import '../utils/icon_mapper.dart';
import '../utils/streak_levels.dart';
import '../widgets/custom_card.dart';
import '../widgets/progress_bar.dart';
import 'routine_detail_screen.dart';
import 'routine_editor.dart';
import 'routine_player.dart';
import 'journal_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

/// Shell principal con navegación inferior entre las secciones clave.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  BannerAd? _bannerAd;
  bool _bannerReady = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadBannerAd() async {
    final state = ref.read(routineControllerProvider);
    if (state.isPremium) {
      return;
    }
    final adsService = ref.read(adsServiceProvider);
    final ad = await adsService.createBannerAd();
    if (!mounted) {
      ad?.dispose();
      return;
    }
    setState(() {
      _bannerAd = ad;
      _bannerReady = ad != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routineControllerProvider);
    final isLoading = state.isLoading;

    if (isLoading && _bannerAd != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _disposeBanner();
      });
    }

    if (state.isPremium && _bannerAd != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _disposeBanner();
      });
    } else if (!state.isPremium && _bannerAd == null && !_bannerReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadBannerAd();
      });
    }

    final pages = [
      _HomeTab(
        onEdit: _openEditor,
        onPlay: _openPlayer,
        onDuplicate: _duplicate,
        onDelete: _delete,
      ),
      const StatsScreen(),
      const JournalScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Daylyo')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: AppColors.background,
              child: Column(
                children: [
                  Expanded(
                    child: IndexedStack(index: _currentIndex, children: pages),
                  ),
                  if (_bannerReady &&
                      state.isPremium == false &&
                      _bannerAd != null)
                    SizedBox(
                      height: _bannerAd!.size.height.toDouble(),
                      width: _bannerAd!.size.width.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nueva rutina'),
              onPressed: () => _openEditor(),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        elevation: 2,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.25),
        labelTextStyle: WidgetStateProperty.all(
          Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            label: 'Rutinas',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Estadísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_rounded),
            label: 'Mi día',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor([Routine? routine]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoutineEditorScreen(routine: routine)),
    );
  }

  Future<void> _openPlayer(Routine routine) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoutinePlayerScreen(routine: routine)),
    );
  }

  Future<void> _duplicate(Routine routine) async {
    await ref
        .read(routineControllerProvider.notifier)
        .duplicateRoutine(routine);
  }

  Future<void> _delete(Routine routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar rutina?'),
        content: Text(
          'Se eliminará "${routine.name}" y su historial asociado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(routineControllerProvider.notifier)
          .removeRoutine(routine.id);
    }
  }

  void _disposeBanner() {
    _bannerAd?.dispose();
    setState(() {
      _bannerAd = null;
      _bannerReady = false;
    });
  }
}

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab({
    required this.onEdit,
    required this.onPlay,
    required this.onDuplicate,
    required this.onDelete,
  });

  final Future<void> Function([Routine?]) onEdit;
  final Future<void> Function(Routine routine) onPlay;
  final Future<void> Function(Routine routine) onDuplicate;
  final Future<void> Function(Routine routine) onDelete;

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routineControllerProvider);
    final filteredRoutines = _searchQuery.isEmpty
        ? state.routines
        : state.routines
              .where(
                (routine) => routine.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
    final streak = state.streakDays;
    final streakLevel = StreakLevel.getLevel(streak);
    final displayName = state.displayName?.trim();
    final today = DateTime.now();
    final isBirthdayToday =
        state.birthday != null &&
        state.birthday!.month == today.month &&
        state.birthday!.day == today.day;
    const suggestions = [
      _SuggestionItem('✨ Gratitud', 'gratitud'),
      _SuggestionItem('💪 Energía', 'energia'),
      _SuggestionItem('🧘‍♀️ Mindfulness', 'mindfulness'),
      _SuggestionItem('📚 Enfoque', 'enfoque'),
      _SuggestionItem('🌙 Buen descanso', 'descanso'),
    ];

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCard(
              backgroundColor: AppColors.primary.withOpacity(0.28),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.35),
                width: 1,
              ),
              shadows: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName != null && displayName.isNotEmpty
                        ? 'Hola, $displayName'
                        : 'Hola',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        streakLevel.emoji,
                        style: TextStyle(fontSize: streakLevel.size * 0.6),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          streak > 0
                              ? 'Increíble, llevas $streak día${streak == 1 ? '' : 's'} seguido${streak == 1 ? '' : 's'}'
                              : 'Comienza tu primera rutina para iniciar tu racha.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: suggestions
                        .map(
                          (item) => GestureDetector(
                            onTap: () =>
                                widget.onEdit(_getSuggestedRoutine(item.key)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.outline.withOpacity(0.7),
                                ),
                              ),
                              child: Text(
                                item.label,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            if (isBirthdayToday) ...[
              const SizedBox(height: 20),
              CustomCard(
                backgroundColor: AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.45),
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 22,
                ),
                shadows: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Celebremos tu día! 🎉',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      displayName != null && displayName.isNotEmpty
                          ? 'Hoy es un día especial para ti, $displayName. Que cada paso en tus rutinas te recuerde lo valioso que eres.'
                          : 'Hoy es un día especial para ti. Que cada paso en tus rutinas te recuerde lo valioso que eres.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Te mandamos un abrazo pastelón y muchos emojis felices. 💜✨',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text('Tus rutinas', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (state.routines.isNotEmpty)
              CustomCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar rutinas...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
            if (state.routines.isNotEmpty) const SizedBox(height: 12),
            if (filteredRoutines.isEmpty && state.routines.isNotEmpty)
              CustomCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No se encontraron rutinas',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            else if (state.routines.isEmpty)
              CustomCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      size: 48,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Comienza con una de las rutinas sugeridas o crea la tuya desde cero.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => widget.onEdit(),
                      child: const Text('Crear rutina'),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final routine = filteredRoutines[index];
                  final completedToday = state.history.any(
                    (entry) =>
                        entry.routineId == routine.id &&
                        DateUtils.isSameDay(entry.completedAt, DateTime.now()),
                  );
                  final progress = state.allProgress.firstWhere(
                    (p) => p.routineId == routine.id,
                    orElse: () => RoutineProgress.create(routineId: routine.id),
                  );
                  final hasProgress = state.allProgress.any(
                    (p) => p.routineId == routine.id && p.completedTasks.isNotEmpty,
                  );
                  return _RoutineListTile(
                    routine: routine,
                    completedToday: completedToday,
                    hasProgress: hasProgress,
                    progress: progress,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RoutineDetailScreen(routine: routine),
                        ),
                      );
                    },
                    onEdit: () => widget.onEdit(routine),
                    onPlay: () => widget.onPlay(routine),
                    onDuplicate: () => widget.onDuplicate(routine),
                    onDelete: () => widget.onDelete(routine),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemCount: filteredRoutines.length,
              ),
          ],
        ),
      ),
    );
  }
}

class _RoutineListTile extends StatelessWidget {
  const _RoutineListTile({
    required this.routine,
    required this.completedToday,
    required this.hasProgress,
    required this.progress,
    required this.onTap,
    required this.onEdit,
    required this.onPlay,
    required this.onDuplicate,
    required this.onDelete,
  });

  final Routine routine;
  final bool completedToday;
  final bool hasProgress;
  final RoutineProgress progress;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onPlay;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final baseColor = Color(routine.colorHex);
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: baseColor.withOpacity(0.25), width: 1),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconMapper.resolve(routine.iconName),
                  color: baseColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${routine.tasks.length} paso${routine.tasks.length == 1 ? '' : 's'} • ${routine.formattedReminder}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (hasProgress)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accent.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pause_circle_outline_rounded,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'En progreso',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'duplicate':
                      onDuplicate();
                      break;
                    case 'play':
                      onPlay();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicar'),
                  ),
                  const PopupMenuItem(value: 'play', child: Text('Iniciar')),
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          RoutineProgressBar(
            progress: hasProgress
                ? progress.completedTasks.length / routine.tasks.length
                : (completedToday ? 1.0 : 0.0),
          ),
          const SizedBox(height: 8),
          Text(
            hasProgress
                ? '${progress.completedTasks.length} de ${routine.tasks.length} pasos completados'
                : (routine.lastCompleted != null
                    ? 'Última vez: ${MaterialLocalizations.of(context).formatShortDate(routine.lastCompleted!)}'
                    : 'Aún no completada'),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

Routine? _getSuggestedRoutine(String key) {
  switch (key) {
    case 'gratitud':
      return Routine.create(
        name: 'Rutina de Gratitud',
        iconName: 'favorite',
        colorHex: 0xFFFFC8DD,
        tasks: [
          RoutineTask.create(
            title: 'Escribir 3 cosas por las que estoy agradecido hoy',
          ),
          RoutineTask.create(
            title: 'Reflexionar sobre un momento positivo del día',
          ),
          RoutineTask.create(title: 'Expresar gratitud a alguien cercano'),
          RoutineTask.create(title: 'Agradecer por algo que damos por sentado'),
        ],
      );
    case 'energia':
      return Routine.create(
        name: 'Rutina de Energía',
        iconName: 'bolt',
        colorHex: 0xFFFFE5B4,
        tasks: [
          RoutineTask.create(title: 'Hidratarse con un vaso de agua'),
          RoutineTask.create(title: 'Estiramiento de 5 minutos'),
          RoutineTask.create(title: 'Respirar profundamente 10 veces'),
          RoutineTask.create(title: 'Escuchar música motivadora'),
          RoutineTask.create(
            title: 'Hacer una caminata corta',
            isOptional: true,
          ),
        ],
      );
    case 'mindfulness':
      return Routine.create(
        name: 'Rutina de Mindfulness',
        iconName: 'self_improvement',
        colorHex: 0xFFB8F2E6,
        tasks: [
          RoutineTask.create(title: 'Meditación de 5 minutos'),
          RoutineTask.create(title: 'Practicar respiración consciente'),
          RoutineTask.create(title: 'Observar el entorno sin juzgar'),
          RoutineTask.create(title: 'Reflexionar sobre el momento presente'),
        ],
      );
    case 'enfoque':
      return Routine.create(
        name: 'Rutina de Enfoque',
        iconName: 'lightbulb',
        colorHex: 0xFFBEE3FF,
        tasks: [
          RoutineTask.create(title: 'Revisar objetivos del día'),
          RoutineTask.create(title: 'Eliminar distracciones del espacio'),
          RoutineTask.create(title: 'Priorizar las 3 tareas más importantes'),
          RoutineTask.create(
            title: 'Configurar temporizador para trabajo profundo',
          ),
        ],
      );
    case 'descanso':
      return Routine.create(
        name: 'Rutina de Buen Descanso',
        iconName: 'bedtime',
        colorHex: 0xFFD7C0FF,
        tasks: [
          RoutineTask.create(
            title: 'Apagar pantallas 30 minutos antes de dormir',
          ),
          RoutineTask.create(
            title: 'Preparar el ambiente (luz tenue, temperatura cómoda)',
          ),
          RoutineTask.create(title: 'Hacer estiramientos suaves'),
          RoutineTask.create(title: 'Leer o escuchar música relajante'),
          RoutineTask.create(title: 'Reflexionar sobre el día con gratitud'),
        ],
      );
    default:
      return null;
  }
}

class _SuggestionItem {
  const _SuggestionItem(this.label, this.key);

  final String label;
  final String key;
}
