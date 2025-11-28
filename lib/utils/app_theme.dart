import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Representa una combinación de colores pastel para personalizar la app.
class PastelPalette {
  const PastelPalette({
    required this.id,
    required this.label,
    required this.primary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
  });

  final String id;
  final String label;
  final Color primary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
}

/// Colección de paletas disponibles.
class PastelPalettes {
  static const PastelPalette amis = PastelPalette(
    id: 'amis',
    label: 'Morado suave',
    primary: Color(0xFFDCCBFF),
    accent: Color(0xFFBDAEFA),
    background: Color(0xFFF6F1FF),
    surface: Color(0xFFFFFFFF),
    outline: Color(0xFFE7DAFF),
    textPrimary: Color(0xFF5A5A5A),
    textSecondary: Color(0xFF8A8A8A),
    success: Color(0xFFC5F2E3),
  );

  static const PastelPalette menta = PastelPalette(
    id: 'menta',
    label: 'Menta fresca',
    primary: Color(0xFFCDEFE0),
    accent: Color(0xFF9DDAC6),
    background: Color(0xFFF2FFF8),
    surface: Color(0xFFFFFFFF),
    outline: Color(0xFFCCF1E5),
    textPrimary: Color(0xFF5A5A5A),
    textSecondary: Color(0xFF8A8A8A),
    success: Color(0xFF95E0C4),
  );

  static const PastelPalette cielo = PastelPalette(
    id: 'cielo',
    label: 'Cielo suave',
    primary: Color(0xFFCFE3FF),
    accent: Color(0xFFA3D5FF),
    background: Color(0xFFF3F9FF),
    surface: Color(0xFFFFFFFF),
    outline: Color(0xFFD8E7FF),
    textPrimary: Color(0xFF5A5A5A),
    textSecondary: Color(0xFF8A8A8A),
    success: Color(0xFF8FD0FF),
  );

  static const PastelPalette durazno = PastelPalette(
    id: 'durazno',
    label: 'Durazno cálido',
    primary: Color(0xFFFAD5C9),
    accent: Color(0xFFF8B9A6),
    background: Color(0xFFFFF4EF),
    surface: Color(0xFFFFFFFF),
    outline: Color(0xFFFCDACE),
    textPrimary: Color(0xFF5A5A5A),
    textSecondary: Color(0xFF8A8A8A),
    success: Color(0xFFEFC8B2),
  );

  static const PastelPalette rosa = PastelPalette(
    id: 'rosa',
    label: 'Rosa suave',
    primary: Color(0xFFFFD6E8),
    accent: Color(0xFFFFB8D6),
    background: Color(0xFFFFF0F7),
    surface: Color(0xFFFFFFFF),
    outline: Color(0xFFFFE0ED),
    textPrimary: Color(0xFF5A5A5A),
    textSecondary: Color(0xFF8A8A8A),
    success: Color(0xFFFFC5E0),
  );

  static const PastelPalette limon = PastelPalette(
    id: 'limon',
    label: 'Limón dulce',
    primary: Color(0xFFFFF4C2),
    accent: Color(0xFFFFE99A),
    background: Color(0xFFFFFDF0),
    surface: Color(0xFFFFFFFF),
    outline: Color(0xFFFFF8D0),
    textPrimary: Color(0xFF5A5A5A),
    textSecondary: Color(0xFF8A8A8A),
    success: Color(0xFFFFE5A8),
  );

  static const List<PastelPalette> all = [
    amis,
    menta,
    cielo,
    durazno,
    rosa,
    limon,
  ];

  static PastelPalette byId(String id) {
    return all.firstWhere((palette) => palette.id == id, orElse: () => amis);
  }

  static const String defaultId = 'amis';
}

/// Paleta centralizada y dinámica de la aplicación.
class AppColors {
  static PastelPalette _palette = PastelPalettes.amis;

  static PastelPalette get current => _palette;

  static set current(PastelPalette palette) {
    _palette = palette;
  }

  static void updateById(String paletteId) {
    _palette = PastelPalettes.byId(paletteId);
  }

  static Color get primary => _palette.primary;
  static Color get accent => _palette.accent;
  static Color get background => _palette.background;
  static Color get surface => _palette.surface;
  static Color get outline => _palette.outline;
  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get success => _palette.success;
}

/// Construye los temas visuales de Mi Rutina Diaria.
class AppTheme {
  static const String defaultPaletteId = PastelPalettes.defaultId;

  static ThemeData lightTheme() {
    final colors = AppColors.current;
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.quicksand(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      headlineMedium: GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      bodyMedium: GoogleFonts.poppins(
        color: colors.textSecondary,
        fontSize: 12,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 11,
        color: colors.textSecondary.withOpacity(0.85),
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        color: colors.textSecondary,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 11,
        color: colors.textSecondary,
      ),
      headlineSmall: GoogleFonts.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        primary: colors.primary,
        secondary: colors.accent,
        surface: colors.surface,
        background: colors.background,
        error: const Color(0xFFFF9BAA),
      ).copyWith(
        onSurface: colors.textPrimary,
        onBackground: colors.textPrimary,
        onPrimary: colors.textPrimary,
        onSecondary: colors.textPrimary,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.quicksand(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary, size: 20),
        toolbarHeight: 48,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        foregroundColor: colors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outline.withOpacity(0.6)),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.accent
              : colors.accent.withOpacity(0.25);
        }),
        side: BorderSide(color: colors.primary.withOpacity(0.5)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 13),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 13),
        ),
      ),
      iconTheme: IconThemeData(color: colors.textPrimary),
      dividerTheme: DividerThemeData(
        color: colors.outline.withOpacity(0.7),
        thickness: 1,
      ),
    );
  }
}
