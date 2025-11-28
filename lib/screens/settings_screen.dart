import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/routine_controller.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_card.dart';
import '../widgets/pastel_toggle.dart';

/// Configuraciones generales, recordatorios y modo premium.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nameController;
  bool _nameInitialized = false;
  DateTime? _birthday;
  bool _birthdayInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routineControllerProvider);

    // Inicializar el controlador solo una vez con el valor del estado
    if (!_nameInitialized) {
      _nameController.text = state.displayName ?? '';
      _nameInitialized = true;
    }

    if (!_birthdayInitialized || !_sameDate(state.birthday, _birthday)) {
      _birthday = state.birthday;
      _birthdayInitialized = true;
    }

    final palettes = PastelPalettes.all;
    final selectedPaletteId = state.paletteId;

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferencias',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text('Tu perfil', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: '¿Cómo debemos llamarte?',
                            hintText: 'Ingresa tu nombre (opcional)',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_nameController.text.trim() !=
                          (state.displayName ?? '')) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.check_rounded, size: 20),
                          onPressed: () async {
                            final trimmed = _nameController.text.trim();
                            await ref
                                .read(routineControllerProvider.notifier)
                                .updateDisplayName(
                                  trimmed.isEmpty ? null : trimmed,
                                );
                            if (mounted) {
                              setState(() {});
                            }
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.all(8),
                            minimumSize: const Size(36, 36),
                            maximumSize: const Size(36, 36),
                          ),
                          tooltip: 'Guardar',
                        ),
                      ],
                      if (_nameController.text.isNotEmpty &&
                          _nameController.text.trim() ==
                              (state.displayName ?? '')) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () async {
                            _nameController.clear();
                            await ref
                                .read(routineControllerProvider.notifier)
                                .updateDisplayName(null);
                            if (mounted) {
                              setState(() {});
                            }
                          },
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                            minimumSize: const Size(36, 36),
                            maximumSize: const Size(36, 36),
                          ),
                          tooltip: 'Limpiar',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha de nacimiento',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _birthday != null
                            ? DateFormat('d MMM y', 'es').format(_birthday!)
                            : 'Aún no asignada',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.cake_rounded),
                            label: Text(
                              _birthday != null ? 'Cambiar' : 'Elegir',
                            ),
                            onPressed: () => _pickBirthday(state.birthday),
                          ),
                          if (_birthday != null)
                            TextButton(
                              onPressed: _clearBirthday,
                              child: const Text('Quitar'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Sensaciones', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feedback al completar pasos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Añade una vibración suave cuando completes cada paso de tus rutinas.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PastelToggle(
                    value: state.vibrationEnabled,
                    onChanged: (value) async {
                      await ref
                          .read(routineControllerProvider.notifier)
                          .updateVibrationEnabled(value);
                    },
                    title: const Text('Vibración motivadora'),
                    subtitle: const Text(
                      'Activa un toque háptico cuando marques un paso como completado.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Personalización visual',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elige la paleta pastel que mejor acompañe tu día.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: palettes.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.3,
                        ),
                    itemBuilder: (context, index) {
                      final palette = palettes[index];
                      return _PalettePreview(
                        palette: palette,
                        selected: palette.id == selectedPaletteId,
                        onTap: () => _onPaletteSelected(palette.id),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Recordatorios',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PastelToggle(
                    value: state.notificationsEnabled,
                    onChanged: (value) async {
                      await ref
                          .read(routineControllerProvider.notifier)
                          .updateNotificationsEnabled(value);
                      if (!mounted) return;
                      final message = value
                          ? 'Notificaciones activadas. Revisaremos tus rutinas para programar recordatorios.'
                          : 'Notificaciones desactivadas. Ya no enviaremos alertas.';
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    },
                    title: const Text('Activar notificaciones'),
                    subtitle: const Text(
                      'Permite recordatorios diarios y por rutina en tu dispositivo.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configura los recordatorios directamente en cada rutina para elegir sus días y horarios específicos.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Datos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            CustomCard(
              backgroundColor: AppColors.surface,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Exportar datos'),
                    subtitle: const Text(
                      'Genera un respaldo en formato JSON con tus rutinas, historial y configuraciones.',
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: _exportData,
                      child: const Text('Exportar'),
                    ),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Importar datos'),
                    subtitle: const Text(
                      'Restaura tus datos desde un archivo JSON de respaldo.',
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: _importData,
                      child: const Text('Importar'),
                    ),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Restablecer datos'),
                    subtitle: const Text(
                      'Vuelve al estado inicial con rutinas sugeridas y sin historial.',
                    ),
                    trailing: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                      onPressed: _confirmResetData,
                      child: const Text('Reiniciar'),
                    ),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Soporte y feedback'),
                    subtitle: const Text(
                      'Comparte ideas para seguir mejorando la app.',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.mail_outline_rounded),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Envíanos tus comentarios a diegobarbecho133@gmail.com',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirthday(DateTime? current) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = current ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(today) ? today : initial,
      firstDate: DateTime(1900),
      lastDate: today,
      locale: const Locale('es'),
    );
    if (picked != null) {
      final normalized = DateTime(picked.year, picked.month, picked.day);
      setState(() {
        _birthday = normalized;
      });
      await ref
          .read(routineControllerProvider.notifier)
          .updateBirthday(normalized);
    }
  }

  Future<void> _clearBirthday() async {
    setState(() {
      _birthday = null;
    });
    await ref.read(routineControllerProvider.notifier).updateBirthday(null);
  }

  bool _sameDate(DateTime? a, DateTime? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _onPaletteSelected(String paletteId) async {
    await ref.read(routineControllerProvider.notifier).updatePalette(paletteId);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _exportData() async {
    try {
      // Mostrar indicador de carga
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final jsonString = await StorageService.instance.exportToJson();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'daylyo_backup_$timestamp.json';

      // Guardar temporalmente el archivo
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      // Cerrar el diálogo de carga
      if (!mounted) return;
      Navigator.of(context).pop();

      // Compartir el archivo con tipo MIME específico para mantener la extensión .json
      // El nombre del archivo se especifica explícitamente en el XFile
      final xFile = XFile(
        file.path,
        mimeType: 'application/json',
        name: fileName,
      );
      // No usar 'subject' para evitar que sobrescriba el nombre del archivo
      await Share.shareXFiles([xFile], text: 'Respaldo de Daylyo - $fileName');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Respaldo exportado exitosamente')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar diálogo de carga si está abierto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _importData() async {
    try {
      // Seleccionar archivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return; // Usuario canceló
      }

      final file = result.files.first;
      if (file.bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo leer el archivo'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // Mostrar diálogo de confirmación
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Importar datos?'),
          content: const Text(
            'Esto reemplazará tus rutinas personalizadas e historial actuales. '
            'Las rutinas sugeridas no se verán afectadas.\n\n'
            '¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Importar'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return;
      }

      // Mostrar indicador de carga
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Leer y parsear JSON con codificación UTF-8
      final jsonString = utf8.decode(file.bytes!);

      // Verificar que el JSON tiene contenido
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final routinesCount =
          (jsonData['routines'] as List<dynamic>?)?.length ?? 0;
      debugPrint('[Import] JSON contiene $routinesCount rutinas para importar');

      await StorageService.instance.importFromJson(jsonString, merge: false);

      // Pequeña pausa para asegurar que el storage se haya actualizado
      await Future.delayed(const Duration(milliseconds: 100));

      // Recargar datos en el controlador
      await ref.read(routineControllerProvider.notifier).refreshData();

      // Actualizar el controlador con el nuevo nombre del estado
      if (mounted) {
        final newState = ref.read(routineControllerProvider);
        _nameController.text = newState.displayName ?? '';
      }

      // Cerrar el diálogo de carga
      if (!mounted) return;
      Navigator.of(context).pop();

      // Mostrar mensaje de éxito
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos importados exitosamente')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar diálogo de carga si está abierto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al importar: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _confirmResetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Reiniciar datos?'),
        content: const Text(
          'Se eliminarán tus rutinas personalizadas, historial y ajustes. '
          'Las rutinas sugeridas volverán a su estado original.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(routineControllerProvider.notifier).resetAppData();
      if (!mounted) return;
      // Actualizar el controlador con el nuevo estado (probablemente vacío después de resetear)
      final newState = ref.read(routineControllerProvider);
      _nameController.text = newState.displayName ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos restablecidos correctamente.')),
      );
    }
  }
}

class _PalettePreview extends StatelessWidget {
  const _PalettePreview({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final PastelPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? palette.accent.withOpacity(0.8)
                : palette.outline.withOpacity(0.6),
            width: selected ? 1.5 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? palette.accent.withOpacity(0.22)
                  : palette.outline.withOpacity(0.15),
              blurRadius: selected ? 14 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ColorDot(color: palette.primary),
                const SizedBox(width: 8),
                _ColorDot(color: palette.accent),
                const SizedBox(width: 8),
                _ColorDot(color: palette.success),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              palette.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selected ? 'Seleccionada' : 'Tocar para usar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected
                    ? palette.textPrimary
                    : palette.textSecondary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
      ),
    );
  }
}
