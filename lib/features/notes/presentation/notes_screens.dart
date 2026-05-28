import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
import '../data/logline_note.dart';
import '../data/notes_repository.dart';
import '../data/notes_search_filter.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final NotesRepository _repository = NotesRepository();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<LogLineNote>> _notesFuture;
  String _query = '';
  String _ownerId = 'local-user';
  NotesFilter _selectedFilter = NotesFilter.all;

  @override
  void initState() {
    super.initState();
    _notesFuture = _loadNotes();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  Future<List<LogLineNote>> _loadNotes() async {
    _ownerId = await _repository.currentOwnerId();
    await _repository.pullRemote();
    return _repository.notes();
  }

  Future<void> _refresh() async {
    setState(() => _notesFuture = _loadNotes());
    await _notesFuture;
  }

  List<LogLineNote> _filteredNotes(List<LogLineNote> notes) {
    return NotesSearchFilter.apply(
      notes: notes,
      query: _query,
      filter: _selectedFilter,
      ownerId: _ownerId,
    );
  }

  void _selectFilter(NotesFilter filter) {
    setState(() => _selectedFilter = filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LogLineScaffold(
      currentIndex: 0,
      child: FutureBuilder<List<LogLineNote>>(
        future: _notesFuture,
        builder: (context, snapshot) {
          final allNotes = snapshot.data ?? const <LogLineNote>[];
          final notes = _filteredNotes(allNotes);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${allNotes.length} notes tersimpan',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () => context.go(AppRoutePaths.addNote),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Cari notes, tag, atau hasil OCR',
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    LogLineChip(
                      label: 'Semua',
                      selected: _selectedFilter == NotesFilter.all,
                      onTap: () => _selectFilter(NotesFilter.all),
                    ),
                    LogLineChip(
                      label: 'Saya',
                      selected: _selectedFilter == NotesFilter.mine,
                      onTap: () => _selectFilter(NotesFilter.mine),
                    ),
                    LogLineChip(
                      label: 'Kolab',
                      selected: _selectedFilter == NotesFilter.collaboration,
                      onTap: () => _selectFilter(NotesFilter.collaboration),
                    ),
                    LogLineChip(
                      label: 'OCR',
                      selected: _selectedFilter == NotesFilter.ocr,
                      onTap: () => _selectFilter(NotesFilter.ocr),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (allNotes.isEmpty)
                  const _EmptyNotesState()
                else if (notes.isEmpty)
                  const _EmptySearchState()
                else
                  ...notes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: NotePreviewCard(note: NotePreview.fromNote(note)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AddNoteScreen extends StatelessWidget {
  const AddNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EditorFrame(title: 'Tambah Note', actionLabel: 'Simpan');
  }
}

class EditNoteScreen extends StatelessWidget {
  const EditNoteScreen({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context) {
    return _EditorFrame(
      title: 'Edit Note',
      actionLabel: 'Update',
      noteId: noteId,
    );
  }
}

class _EditorFrame extends StatefulWidget {
  const _EditorFrame({
    required this.title,
    required this.actionLabel,
    this.noteId,
  });

  final String title;
  final String actionLabel;
  final String? noteId;

  @override
  State<_EditorFrame> createState() => _EditorFrameState();
}

class _EditorFrameState extends State<_EditorFrame> {
  final NotesRepository _repository = NotesRepository();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagController = TextEditingController(
    text: 'Personal',
  );
  final TextEditingController _bodyController = TextEditingController(
    text:
        '# Judul logbook\n\nTulis ringkasan, checklist, atau tempel hasil OCR di sini.',
  );
  LogLineNote? _loadedNote;
  List<String> _collaborators = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.noteId != null) {
      final note = await _repository.noteById(widget.noteId!);
      if (note != null) {
        _loadedNote = note;
        _titleController.text = note.title;
        _tagController.text = note.tag;
        _bodyController.text = note.content;
        _collaborators = note.collaborators;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final note = _loadedNote;
    final saved = note == null
        ? await _repository.createNote(
            title: _titleController.text,
            content: _bodyController.text,
            tag: _tagController.text,
            collaborators: _collaborators,
          )
        : await _repository.updateNote(
            note.copyWith(
              title: _titleController.text,
              content: _bodyController.text,
              tag: _tagController.text,
              collaborators: _collaborators,
            ),
          );
    if (!mounted) return;
    context.go(AppRoutePaths.noteDetail(saved.id));
  }

  void _applyMarkdownTool(MarkdownTool tool) {
    switch (tool) {
      case MarkdownTool.bold:
        _wrapSelection('**', '**', 'teks tebal');
      case MarkdownTool.italic:
        _wrapSelection('_', '_', 'teks miring');
      case MarkdownTool.heading:
        _insertLinePrefix('## ');
      case MarkdownTool.checklist:
        _insertAtCursor('- [ ] tugas baru');
      case MarkdownTool.quote:
        _insertLinePrefix('> ');
      case MarkdownTool.code:
        _wrapSelection('`', '`', 'kode');
      case MarkdownTool.link:
        _wrapSelection('[', '](https://)', 'tautan');
    }
  }

  void _wrapSelection(String before, String after, String fallback) {
    final value = _bodyController.value;
    final text = value.text;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: text.length);
    final selected = selection.isCollapsed
        ? fallback
        : text.substring(selection.start, selection.end);
    final replacement = '$before$selected$after';
    final nextText = text.replaceRange(
      selection.start,
      selection.end,
      replacement,
    );
    final cursor = selection.start + before.length + selected.length;
    _bodyController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  void _insertLinePrefix(String prefix) {
    final value = _bodyController.value;
    final text = value.text;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: text.length);
    final lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
    final nextText = text.replaceRange(lineStart, lineStart, prefix);
    _bodyController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(
        offset: selection.extentOffset + prefix.length,
      ),
    );
  }

  void _insertAtCursor(String markdown) {
    final value = _bodyController.value;
    final text = value.text;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: text.length);
    final needsBreak = selection.start > 0 && text[selection.start - 1] != '\n';
    final insertion = needsBreak ? '\n$markdown' : markdown;
    final nextText = text.replaceRange(
      selection.start,
      selection.end,
      insertion,
    );
    _bodyController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(
        offset: selection.start + insertion.length,
      ),
    );
  }

  Future<void> _addCollaborator() async {
    final invite = await CollaboratorConfirmSheet.show(context);
    if (invite == null || invite.identity.trim().isEmpty) return;
    final value = invite.identity.trim();
    final next = <String>[..._collaborators];
    if (!next.any((item) => item.toLowerCase() == value.toLowerCase())) {
      next.add(value);
    }
    setState(() => _collaborators = next);
    final note = _loadedNote;
    if (note != null) {
      final updated = await _repository.addCollaborator(
        noteId: note.id,
        collaborator: value,
      );
      if (updated != null && mounted) {
        setState(() {
          _loadedNote = updated;
          _collaborators = updated.collaborators;
        });
      }
    }
  }

  void _removeDraftCollaborator(String collaborator) {
    setState(() {
      _collaborators = _collaborators
          .where((item) => item.toLowerCase() != collaborator.toLowerCase())
          .toList();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LogLineScaffold(
      title: widget.title,
      showBack: true,
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Menyimpan...' : widget.actionLabel),
        ),
      ],
      currentIndex: 0,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
              children: [
                LogLineTextField(
                  label: 'Judul',
                  hint: 'Judul catatan',
                  controller: _titleController,
                ),
                const SizedBox(height: 16),
                LogLineTextField(
                  label: 'Tag',
                  hint: 'Personal, OCR, Kolab',
                  controller: _tagController,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const LogLineChip(label: 'Private', selected: true),
                    const SizedBox(width: 8),
                    const LogLineChip(
                      label: 'Offline-first',
                      color: AppColors.teal,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _addCollaborator,
                      child: const Text('+ Kolaborator'),
                    ),
                  ],
                ),
                if (_collaborators.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _collaborators
                        .map(
                          (item) => InputChip(
                            label: Text(item),
                            onDeleted: () => _removeDraftCollaborator(item),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                MarkdownToolbar(onSelected: _applyMarkdownTool),
                const SizedBox(height: 16),
                TextField(
                  controller: _bodyController,
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
                        label: 'Simpan',
                        variant: LogLineButtonVariant.secondary,
                        onPressed: _saving ? null : _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key, required this.noteId});

  final String noteId;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final NotesRepository _repository = NotesRepository();
  late Future<LogLineNote?> _noteFuture;

  @override
  void initState() {
    super.initState();
    _noteFuture = _repository.noteById(widget.noteId);
  }

  Future<void> _delete() async {
    await _repository.deleteNote(widget.noteId);
    if (mounted) context.go(AppRoutePaths.notes);
  }

  Future<void> _addCollaboratorToNote(LogLineNote note) async {
    final invite = await CollaboratorConfirmSheet.show(context);
    if (invite == null || invite.identity.trim().isEmpty) return;
    final updated = await _repository.addCollaborator(
      noteId: note.id,
      collaborator: invite.identity.trim(),
    );
    if (updated != null && mounted) {
      setState(() => _noteFuture = Future.value(updated));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LogLineNote?>(
      future: _noteFuture,
      builder: (context, snapshot) {
        final note = snapshot.data;
        return LogLineScaffold(
          title: 'Detail Note',
          showBack: true,
          actions: [
            IconButton(
              onPressed: note == null
                  ? null
                  : () => context.go(AppRoutePaths.noteEdit(note.id)),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: note == null ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
          currentIndex: 0,
          child: note == null
              ? const Center(child: Text('Note tidak ditemukan.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Terakhir update ${note.updatedAt.day}/${note.updatedAt.month}/${note.updatedAt.year}',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            children: [
                              LogLineChip(
                                label: note.tag,
                                color: AppColors.teal,
                              ),
                              if (note.syncedAt != null)
                                const LogLineChip(
                                  label: 'Tersinkron',
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          MarkdownBody(data: note.content),
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
                          onPressed: () => _addCollaboratorToNote(note),
                          child: const Text('Kelola'),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 54, color: AppColors.muted),
          SizedBox(height: 14),
          Text(
            'Notes tidak ditemukan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 8),
          Text(
            'Coba kata kunci lain atau cek tag yang kamu masukkan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotesState extends StatelessWidget {
  const _EmptyNotesState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.note_add_outlined,
            size: 54,
            color: AppColors.primary,
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada notes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buat catatan pertama, lalu data akan disimpan lokal dan disinkronkan saat MongoDB tersedia.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          LogLineButton(
            label: 'Tambah note',
            onPressed: () => context.go(AppRoutePaths.addNote),
          ),
        ],
      ),
    );
  }
}
