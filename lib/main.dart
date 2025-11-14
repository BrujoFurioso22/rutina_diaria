import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'providers/routine_controller.dart';
import 'screens/home_screen.dart';
import 'screens/routine_player.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'es';
  await initializeDateFormatting('es');
  runApp(const ProviderScope(child: MiRutinaDiariaApp()));
}

/// Raíz de la aplicación Daylyo.
class MiRutinaDiariaApp extends ConsumerStatefulWidget {
  const MiRutinaDiariaApp({super.key});

  @override
  ConsumerState<MiRutinaDiariaApp> createState() => _MiRutinaDiariaAppState();
}

class _MiRutinaDiariaAppState extends ConsumerState<MiRutinaDiariaApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationHandler();
    });
  }

  void _setupNotificationHandler() {
    final controller = ref.read(routineControllerProvider.notifier);
    controller.setupNotificationHandler((response) {
      final payload = response.payload;
      debugPrint('[Notification] Tap recibido - payload: $payload');
      if (payload != null && payload.isNotEmpty) {
        final routineId = payload;
        _handleNotificationNavigation(routineId);
      }
    });
  }

  void _handleNotificationNavigation(String routineId) {
    // Intentar múltiples veces hasta que el estado esté disponible
    int attempts = 0;
    void tryNavigate() {
      attempts++;
      final state = ref.read(routineControllerProvider);
      debugPrint(
        '[Notification] Intento $attempts - Buscando rutina ID: $routineId',
      );
      debugPrint(
        '[Notification] Rutinas disponibles: ${state.routines.length}',
      );

      if (state.isLoading && attempts < 10) {
        // Si aún está cargando, esperar un poco más
        Future.delayed(const Duration(milliseconds: 300), tryNavigate);
        return;
      }

      try {
        final routine = state.routines.firstWhere((r) => r.id == routineId);
        debugPrint('[Notification] Rutina encontrada: ${routine.name}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (_) => RoutinePlayerScreen(routine: routine),
              ),
            );
          } else {
            debugPrint(
              '[Notification] Navigator no disponible, reintentando...',
            );
            if (attempts < 10) {
              Future.delayed(const Duration(milliseconds: 200), tryNavigate);
            }
          }
        });
      } catch (e) {
        if (attempts < 10) {
          debugPrint(
            '[Notification] Rutina no encontrada aún, reintentando...',
          );
          Future.delayed(const Duration(milliseconds: 300), tryNavigate);
        } else {
          debugPrint(
            '[Notification] Error: Rutina no encontrada después de $attempts intentos - $routineId',
          );
          debugPrint('[Notification] Error completo: $e');
        }
      }
    }

    tryNavigate();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routineControllerProvider);
    // Siempre mostrar splash si está cargando o si no hay estado aún
    final showSplash = state.isLoading;
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Daylyo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: showSplash ? const SplashScreen() : const HomeScreen(),
    );
  }
}
