import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Barra de progreso suave para representar el avance de una rutina.
class RoutineProgressBar extends StatelessWidget {
  const RoutineProgressBar({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0, 1);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.accent,
                ),
                width: clamped == 0 ? 0 : clamped * constraints.maxWidth,
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  '${(clamped * 100).round()} %',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
