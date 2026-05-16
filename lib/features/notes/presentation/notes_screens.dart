import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/note_preview.dart';
import '../../../shared/widgets/collaborator_confirm_sheet.dart';
import '../../../shared/widgets/logline_button.dart';
import '../../../shared/widgets/logline_chip.dart';
import '../../../shared/widgets/logline_scaffold.dart';
import '../../../shared/widgets/logline_text_field.dart';
import '../../../shared/widgets/markdown_toolbar.dart';
import '../../../shared/widgets/note_preview_card.dart';

class NotesListScreen extends StatelessWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LogLineScaffold(
      currentIndex: 1,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(AppRoutePaths.addNote),
        child: const Icon(Icons.add_rounded),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logbook',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '14 notes aktif',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                child: const Text(
                  'AF',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Cari notes, tag, atau hasil OCR',
            ),
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              LogLineChip(label: 'Semua', selected: true),
              LogLineChip(label: 'Saya'),
              LogLineChip(label: 'Kolab'),
              LogLineChip(label: 'OCR'),
            ],
          ),
          const SizedBox(height: 22),
          ...sampleNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: NotePreviewCard(note: note),
            ),
          ),
        ],
      ),
    );
  }
}

class AddNoteScreen extends StatelessWidget {
  const AddNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _EditorFrame(
      title: 'Tambah Note',
      actionLabel: 'Simpan',
      onAction: () => context.go(AppRoutePaths.detailNote),
      titleHint: 'Judul catatan',
      body:
          '# Judul logbook\n\nTulis ringkasan, checklist, atau tempel hasil OCR di sini.\n\n- Poin pertama\n- Poin berikutnya',
    );
  }
}

class EditNoteScreen extends StatelessWidget {
  const EditNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _EditorFrame(
      title: 'Edit Note',
      actionLabel: 'Update',
      onAction: () => context.go(AppRoutePaths.detailNote),
      titleHint: 'Audit gudang mingguan',
      body:
          '## Audit gudang\n\nTanggal: 16 Mei 2026\n\n- Area inbound selesai dicek\n- 4 rak perlu label ulang\n- Hasil OCR lampiran faktur sudah valid\n\n> Follow up dengan tim inventory.',
    );
  }
}

class _EditorFrame extends StatelessWidget {
  const _EditorFrame({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.titleHint,
    required this.body,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final String titleHint;
  final String body;

  @override
  Widget build(BuildContext context) {
    return LogLineScaffold(
      title: title,
      showBack: true,
      actions: [TextButton(onPressed: onAction, child: Text(actionLabel))],
      currentIndex: 1,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          LogLineTextField(label: 'Judul', hint: titleHint),
          const SizedBox(height: 16),
          Row(
            children: [
              const LogLineChip(label: 'Private', selected: true),
              const SizedBox(width: 8),
              const LogLineChip(label: 'Tag: kerja', color: AppColors.teal),
              const Spacer(),
              TextButton(
                onPressed: () => CollaboratorConfirmSheet.show(context),
                child: const Text('+ Kolaborator'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const MarkdownToolbar(),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: body),
            maxLines: 13,
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              hintText: 'Tulis Markdown...',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: LogLineButton(
                  label: 'Buka kamera OCR',
                  variant: LogLineButtonVariant.success,
                  onPressed: () => context.go(AppRoutePaths.scanner),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LogLineButton(
                  label: 'Preview',
                  variant: LogLineButtonVariant.secondary,
                  onPressed: () => context.go(AppRoutePaths.detailNote),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LogLineScaffold(
      title: 'Detail Note',
      showBack: true,
      actions: [
        TextButton(
          onPressed: () => context.go(AppRoutePaths.editNote),
          child: const Text('Edit'),
        ),
      ],
      currentIndex: 1,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Audit gudang mingguan',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'Terakhir update 16 Mei 2026, 14:30',
                  style: TextStyle(color: AppColors.muted),
                ),
                SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    LogLineChip(label: 'Kolab', color: AppColors.teal),
                    LogLineChip(label: 'OCR', color: AppColors.coral),
                  ],
                ),
                SizedBox(height: 28),
                Text(
                  'Ringkasan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'Area inbound selesai dicek. Ada 4 rak yang perlu label ulang dan hasil OCR faktur sudah cocok dengan stok masuk.',
                  style: TextStyle(color: AppColors.muted, height: 1.45),
                ),
                SizedBox(height: 24),
                Text(
                  'Checklist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  '[x] Foto rak\n[x] Scan faktur\n[ ] Follow up inventory',
                  style: TextStyle(height: 1.7),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'Kolaborator',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => CollaboratorConfirmSheet.show(context),
                child: const Text('Kelola'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
