import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LogLineTextField extends StatelessWidget {
  const LogLineTextField({
    super.key,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefixIcon,
  });

  final String label;
  final String hint;
  final bool obscureText;
  final int maxLines;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
          ),
        ),
      ],
    );
  }
}
