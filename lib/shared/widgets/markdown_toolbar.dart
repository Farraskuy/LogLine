import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class MarkdownToolbar extends StatelessWidget {
  const MarkdownToolbar({super.key});

  static const _tools = [
    (Icons.format_bold_rounded, 'Bold'),
    (Icons.format_italic_rounded, 'Italic'),
    (Icons.title_rounded, 'Heading'),
    (Icons.check_box_outlined, 'Checklist'),
    (Icons.format_quote_rounded, 'Quote'),
    (Icons.code_rounded, 'Code'),
    (Icons.link_rounded, 'Link'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final tool = _tools[index];
          return Tooltip(
            message: tool.$2,
            child: IconButton(
              onPressed: () {},
              icon: Icon(tool.$1, size: 20),
              color: index == 0 ? AppColors.primary : AppColors.muted,
            ),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 2),
        itemCount: _tools.length,
      ),
    );
  }
}
