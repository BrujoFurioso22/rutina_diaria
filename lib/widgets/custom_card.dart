import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Contenedor reutilizable con estilo de tarjeta redondeada.
class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.shadows,
    this.borderRadius,
    this.border,
    this.decoration,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);
    final decorationToUse =
        decoration ??
        BoxDecoration(
          color: backgroundColor ?? AppColors.surface,
          borderRadius: radius,
          border:
              border ??
              Border.all(color: AppColors.outline.withOpacity(0.6), width: 1),
          boxShadow:
              shadows ??
              [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
        );

    final content = Container(
      decoration: decorationToUse,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: child,
    );
    if (onTap == null) {
      return content;
    }
    return InkWell(borderRadius: radius, onTap: onTap, child: content);
  }
}
