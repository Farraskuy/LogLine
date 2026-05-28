import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum MarkdownTool { bold, italic, heading, checklist, quote, code, link }

class MarkdownToolbar extends StatelessWidget {
  const MarkdownToolbar({super.key, required this.onSelected});

  final ValueChanged<MarkdownTool> onSelected;

  static const _tools = [
    (MarkdownTool.bold, Icons.format_bold_rounded, 'Bold'),
    (MarkdownTool.italic, Icons.format_italic_rounded, 'Italic'),
    (MarkdownTool.heading, Icons.title_rounded, 'Heading'),
    (MarkdownTool.checklist, Icons.check_box_outlined, 'Checklist'),
    (MarkdownTool.quote, Icons.format_quote_rounded, 'Quote'),
    (MarkdownTool.code, Icons.code_rounded, 'Code'),
    (MarkdownTool.link, Icons.link_rounded, 'Link'),
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
            message: tool.$3,
            child: IconButton(
              onPressed: () => onSelected(tool.$1),
              icon: Icon(tool.$2, size: 20),
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
