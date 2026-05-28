import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_route_paths.dart';
import '../../core/theme/app_theme.dart';
import '../models/note_preview.dart';
import 'logline_chip.dart';

class NotePreviewCard extends StatelessWidget {
  const NotePreviewCard({super.key, required this.note});

  final NotePreview note;

  @override
  Widget build(BuildContext context) {
    final accent = Color(note.accentHex);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.go(AppRoutePaths.noteDetail(note.id)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withAlpha(10),
              offset: const Offset(0, 6),
              blurRadius: 16,
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            note.updatedLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.faint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        note.summary,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          LogLineChip(label: note.tag, color: accent),
                          const Spacer(),
                          ...note.collaborators.map(
                            (initials) => Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: accent.withAlpha(38),
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
