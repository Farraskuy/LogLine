import 'logline_note.dart';

enum NotesFilter { all, mine, collaboration, ocr }

class NotesSearchFilter {
  const NotesSearchFilter._();

  static List<LogLineNote> apply({
    required List<LogLineNote> notes,
    required String query,
    required NotesFilter filter,
    required String ownerId,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return notes.where((note) {
      if (!_matchesFilter(note, filter, ownerId)) return false;
      if (normalizedQuery.isEmpty) return true;
      final searchable = [
        note.title,
        note.content,
        note.tag,
        ...note.collaborators,
      ].join(' ').toLowerCase();
      return searchable.contains(normalizedQuery);
    }).toList();
  }

  static bool _matchesFilter(
    LogLineNote note,
    NotesFilter filter,
    String ownerId,
  ) {
    switch (filter) {
      case NotesFilter.all:
        return true;
      case NotesFilter.mine:
        return note.ownerId == ownerId && note.collaborators.length <= 1;
      case NotesFilter.collaboration:
        return note.collaborators.length > 1 ||
            note.tag.toLowerCase() == 'kolab';
      case NotesFilter.ocr:
        return note.tag.toLowerCase() == 'ocr' ||
            note.content.toLowerCase().contains('ocr');
    }
  }
}
