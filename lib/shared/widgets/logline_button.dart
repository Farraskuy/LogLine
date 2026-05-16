import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LogLineButton extends StatelessWidget {
  const LogLineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = LogLineButtonVariant.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final LogLineButtonVariant variant;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final style = switch (variant) {
      LogLineButtonVariant.primary => FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      LogLineButtonVariant.success => FilledButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
      ),
      LogLineButtonVariant.danger => FilledButton.styleFrom(
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
      ),
      LogLineButtonVariant.secondary => OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.border),
      ),
    };

    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    final button = variant == LogLineButtonVariant.secondary
        ? OutlinedButton(onPressed: onPressed, style: style, child: child)
        : FilledButton(onPressed: onPressed, style: style, child: child);

    return SizedBox(
      width: expand ? double.infinity : null,
      height: 48,
      child: button,
    );
  }
}

enum LogLineButtonVariant { primary, secondary, success, danger }
