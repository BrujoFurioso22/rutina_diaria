import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Pantalla para seleccionar un color de una lista amplia.
class ColorPickerScreen extends StatelessWidget {
  const ColorPickerScreen({
    super.key,
    required this.selectedColorValue,
    required this.onColorSelected,
  });

  final int selectedColorValue;
  final ValueChanged<int> onColorSelected;

  static const List<Color> allColors = [
    // Colores pasteles principales
    Color(0xFFC8B6FF), // Lavanda
    Color(0xFFFFC8DD), // Rosa
    Color(0xFFBEE3FF), // Azul cielo
    Color(0xFFB8F2E6), // Menta
    Color(0xFFFFE5B4), // Durazno
    Color(0xFFD7C0FF), // Lila
    // Más colores pasteles
    Color(0xFFFFD6E8), // Rosa suave
    Color(0xFFE0BBE4), // Lila suave
    Color(0xFFF4C2C2), // Rosa coral
    Color(0xFFFFB3BA), // Rosa melocotón
    Color(0xFFFFDFBA), // Melocotón
    Color(0xFFFFE4B5), // Amarillo suave
    Color(0xFFFFF4C2), // Limón
    Color(0xFFE6F3FF), // Azul claro
    Color(0xFFD4F1F4), // Turquesa claro
    Color(0xFFC7E9E8), // Verde menta
    Color(0xFFB5E5CF), // Verde manzana
    Color(0xFFC8E6C9), // Verde pastel
    Color(0xFFD4EDDA), // Verde hierba
    Color(0xFFE8F5E9), // Verde lima
    Color(0xFFFFF9C4), // Amarillo pastel
    Color(0xFFFFF59D), // Amarillo limón
    Color(0xFFFFE082), // Amarillo dorado
    Color(0xFFFFCCBC), // Naranja suave
    Color(0xFFFFAB91), // Coral
    Color(0xFFFFB74D), // Naranja pastel
    Color(0xFFFFD54F), // Amarillo dorado
    Color(0xFFF8BBD0), // Rosa bebé
    Color(0xFFE1BEE7), // Lila claro
    Color(0xFFC5CAE9), // Azul lila
    Color(0xFFBBDEFB), // Azul cielo
    Color(0xFFB3E5FC), // Azul claro
    Color(0xFFB2EBF2), // Cian claro
    Color(0xFFB2DFDB), // Turquesa
    Color(0xFFC8E6C9), // Verde claro
    Color(0xFFDCEDC8), // Verde lima
    Color(0xFFF0F4C3), // Lima
    Color(0xFFFFF9C4), // Amarillo claro
    Color(0xFFFFECB3), // Melocotón claro
    Color(0xFFFFE0B2), // Naranja claro
    Color(0xFFFFCCBC), // Melocotón
    Color(0xFFFFCDD2), // Rosa claro
    Color(0xFFF8BBD9), // Rosa fucsia
    Color(0xFFE1BEE7), // Lila
    Color(0xFFD1C4E9), // Lila medio
    Color(0xFFC5CAE9), // Azul lila
    Color(0xFFBBDEFB), // Azul cielo
    Color(0xFFB3E5FC), // Azul claro
    Color(0xFFB2EBF2), // Cian
    Color(0xFFB2DFDB), // Turquesa claro
    Color(0xFFC8E6C9), // Verde menta
    Color(0xFFDCEDC8), // Verde lima claro
    Color(0xFFF0F4C3), // Lima claro
    Color(0xFFFFF9C4), // Amarillo
    Color(0xFFFFECB3), // Melocotón
    Color(0xFFFFE0B2), // Naranja
    Color(0xFFFFCCBC), // Melocotón suave
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar color')),
      body: Container(
        color: AppColors.background,
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: allColors.length,
          itemBuilder: (context, index) {
            final color = allColors[index];
            final selected = color.value == selectedColorValue;

            return GestureDetector(
              onTap: () {
                onColorSelected(color.value);
                Navigator.of(context).pop();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? Colors.black.withOpacity(0.4)
                        : Colors.transparent,
                    width: selected ? 4 : 0,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 2,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
