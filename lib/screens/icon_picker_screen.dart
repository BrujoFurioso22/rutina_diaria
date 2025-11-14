import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/icon_mapper.dart';

/// Pantalla para seleccionar un icono de una lista amplia.
class IconPickerScreen extends StatelessWidget {
  const IconPickerScreen({
    super.key,
    required this.selectedIconName,
    required this.onIconSelected,
  });

  final String selectedIconName;
  final ValueChanged<String> onIconSelected;

  @override
  Widget build(BuildContext context) {
    final allIcons = IconMapper.allIconNames();

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar icono')),
      body: Container(
        color: AppColors.background,
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: allIcons.length,
          itemBuilder: (context, index) {
            final iconName = allIcons[index];
            final selected = iconName == selectedIconName;

            return GestureDetector(
              onTap: () {
                onIconSelected(iconName);
                Navigator.of(context).pop();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : Colors.black.withOpacity(0.1),
                    width: selected ? 2.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Icon(
                  IconMapper.resolve(iconName),
                  color: selected
                      ? AppColors.primary
                      : AppColors.textPrimary.withOpacity(0.7),
                  size: 32,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
