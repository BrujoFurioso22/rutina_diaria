import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Toggle tipo switch con estilo pastel reutilizable.
class PastelToggle extends StatelessWidget {
  const PastelToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.leading,
    this.padding,
    this.backgroundColor,
    this.compact = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ??
        (compact
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 18, vertical: 14));
    final radius = BorderRadius.circular(compact ? 22 : 26);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: effectivePadding,
        decoration: BoxDecoration(
          color:
              backgroundColor ??
              (compact
                  ? AppColors.surface.withOpacity(0.9)
                  : AppColors.surface),
          borderRadius: radius,
          border: Border.all(
            color: AppColors.outline.withOpacity(compact ? 0.5 : 0.6),
            width: compact ? 0.8 : 1,
          ),
          boxShadow: compact
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle.merge(
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            _PastelSwitch(isOn: value, compact: compact),
          ],
        ),
      ),
    );
  }
}

class _PastelSwitch extends StatelessWidget {
  const _PastelSwitch({required this.isOn, required this.compact});

  final bool isOn;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 46.0 : 54.0;
    final height = compact ? 26.0 : 30.0;
    final knobSize = compact ? 18.0 : 22.0;
    final borderRadius = BorderRadius.circular(compact ? 24 : 30);
    final padding = EdgeInsets.symmetric(
      horizontal: compact ? 3 : 4,
      vertical: compact ? 3 : 4,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 230),
      curve: Curves.easeOutQuad,
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: isOn ? AppColors.accent : AppColors.primary.withOpacity(0.16),
        boxShadow: [
          if (isOn)
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: compact ? 10 : 14,
              offset: Offset(0, compact ? 4 : 6),
            ),
        ],
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 230),
        curve: Curves.easeOutQuad,
        alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: knobSize,
          height: knobSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: compact ? 4 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
