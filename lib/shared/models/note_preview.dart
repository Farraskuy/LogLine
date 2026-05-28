import '../../features/notes/data/logline_note.dart';

class NotePreview {
  const NotePreview({
    required this.id,
    required this.title,
    required this.summary,
    required this.tag,
    required this.accentHex,
    required this.collaborators,
    required this.updatedLabel,
  });

  final String id;
  final String title;
  final String summary;
  final String tag;
  final int accentHex;
  final List<String> collaborators;
  final String updatedLabel;

  factory NotePreview.fromNote(LogLineNote note) {
    return NotePreview(
      id: note.id,
      title: note.title,
      summary: note.summary,
      tag: note.tag,
      accentHex: _accentForTag(note.tag),
      collaborators: note.collaborators.isEmpty
          ? const ['ME']
          : note.collaborators,
      updatedLabel: _relativeLabel(note.updatedAt),
    );
  }

  static int _accentForTag(String tag) {
    switch (tag.toLowerCase()) {
      case 'ocr':
        return 0xFFF97316;
      case 'kolab':
        return 0xFF0D9488;
      case 'markdown':
        return 0xFF2563EB;
      default:
        return 0xFF6C3CF0;
    }
  }

  static String _relativeLabel(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }
}
