import 'package:uuid/uuid.dart';

import '../../../services/auth_service.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/mongo_notes_sync_service.dart';
import '../../../services/sync_queue_service.dart';
import 'logline_note.dart';
import 'notes_search_filter.dart';

class NotesRepository {
  NotesRepository({
    LocalStorageService? localStorageService,
    AuthService? authService,
    MongoNotesSyncService? syncService,
    SyncQueueService? syncQueueService,
  }) : _localStorageService = localStorageService ?? LocalStorageService(),
       _authService = authService ?? AuthService(),
       _syncService = syncService ?? MongoNotesSyncService(),
       _syncQueueService = syncQueueService ?? SyncQueueService();

  final LocalStorageService _localStorageService;
  final AuthService _authService;
  final MongoNotesSyncService _syncService;
  final SyncQueueService _syncQueueService;
  final Uuid _uuid = const Uuid();

  Future<String> currentOwnerId() => _ownerId();

  Future<List<LogLineNote>> notes() async {
    final ownerId = await _ownerId();
    final localNotes =
        _localStorageService
            .getAllNotes()
            .map(LogLineNote.fromMap)
            .where((note) => note.ownerId == ownerId && !note.isDeleted)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return localNotes;
  }

  Future<List<LogLineNote>> searchNotes({
    String query = '',
    NotesFilter filter = NotesFilter.all,
  }) async {
    final ownerId = await _ownerId();
    final allNotes = await notes();
    return NotesSearchFilter.apply(
      notes: allNotes,
      query: query,
      filter: filter,
      ownerId: ownerId,
    );
  }

  Future<LogLineNote?> noteById(String id) async {
    final map = _localStorageService.getNote(id);
    if (map == null) return null;
    final note = LogLineNote.fromMap(map);
    return note.isDeleted ? null : note;
  }

  Future<LogLineNote> createNote({
    required String title,
    required String content,
    required String tag,
    List<String> collaborators = const [],
  }) async {
    final now = DateTime.now();
    final ownerId = await _ownerId();
    final normalizedCollaborators = _normalizeCollaborators(
      collaborators.isEmpty ? [ownerId] : collaborators,
      ownerId,
    );
    final note = LogLineNote(
      id: _uuid.v4(),
      ownerId: ownerId,
      title: title.trim().isEmpty ? 'Tanpa judul' : title.trim(),
      content: content.trim(),
      tag: tag.trim().isEmpty ? 'Personal' : tag.trim(),
      collaborators: normalizedCollaborators,
      createdAt: now,
      updatedAt: now,
    );
    return _saveAndSync(note, 'create');
  }

  Future<LogLineNote> updateNote(LogLineNote note) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    return _saveAndSync(updated, 'update');
  }

  Future<LogLineNote?> addCollaborator({
    required String noteId,
    required String collaborator,
  }) async {
    final note = await noteById(noteId);
    if (note == null) return null;
    final value = collaborator.trim();
    if (value.isEmpty) return note;
    final updatedCollaborators = _normalizeCollaborators([
      ...note.collaborators,
      value,
    ], note.ownerId);
    final updated = note.copyWith(
      collaborators: updatedCollaborators,
      tag: 'Kolab',
      updatedAt: DateTime.now(),
    );
    await _localStorageService.collaborators.put('${note.id}:$value', {
      'id': '${note.id}:$value',
      'noteId': note.id,
      'collaborator': value,
      'role': 'editor',
      'createdAt': DateTime.now().toIso8601String(),
    });
    return _saveAndSync(updated, 'collaborator_add');
  }

  Future<LogLineNote?> removeCollaborator({
    required String noteId,
    required String collaborator,
  }) async {
    final note = await noteById(noteId);
    if (note == null) return null;
    final updated = note.copyWith(
      collaborators: note.collaborators
          .where((item) => item.toLowerCase() != collaborator.toLowerCase())
          .toList(),
      updatedAt: DateTime.now(),
    );
    await _localStorageService.collaborators.delete('${note.id}:$collaborator');
    return _saveAndSync(updated, 'collaborator_remove');
  }

  Future<void> deleteNote(String id) async {
    final existing = await noteById(id);
    if (existing == null) return;
    final deleted = existing.copyWith(
      isDeleted: true,
      updatedAt: DateTime.now(),
    );
    await _localStorageService.saveNote(deleted.toMap());
    final queueId = await _syncQueueService.enqueue(
      collection: 'notes',
      operation: 'delete',
      payload: {'id': id},
    );
    try {
      await _syncService.deleteNote(id);
      await _syncQueueService.markSynced(queueId);
    } catch (error) {
      await _syncQueueService.markFailed(queueId, error);
    }
  }

  Future<void> pullRemote() async {
    await syncPending();
    try {
      final remoteNotes = await _syncService.fetchNotes(await _ownerId());
      await _localStorageService.settings.put('lastSyncError', {'message': ''});
      for (final note in remoteNotes) {
        await _localStorageService.saveNote(
          note.copyWith(syncedAt: DateTime.now()).toMap(),
        );
      }
    } catch (error) {
      await _localStorageService.settings.put('lastSyncError', {
        'message': error.toString(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> syncPending() async {
    final pending = _syncQueueService.pendingItems();
    for (final item in pending) {
      if (item['collection'] != 'notes') continue;
      final id = item['id'] as String?;
      if (id == null) continue;
      try {
        final operation = item['operation'] as String?;
        final payload = Map<String, dynamic>.from(item['payload'] as Map);
        if (operation == 'delete') {
          await _syncService.deleteNote(payload['id'] as String);
        } else {
          await _syncService.upsertNote(LogLineNote.fromMap(payload));
        }
        await _syncQueueService.markSynced(id);
      } catch (error) {
        await _syncQueueService.markFailed(id, error);
      }
    }
  }

  Future<LogLineNote> _saveAndSync(LogLineNote note, String operation) async {
    await _localStorageService.saveNote(note.toMap());
    final queueId = await _syncQueueService.enqueue(
      collection: 'notes',
      operation: operation,
      payload: note.toMap(),
    );
    try {
      await _syncService.upsertNote(note);
      await _syncQueueService.markSynced(queueId);
      final synced = note.copyWith(syncedAt: DateTime.now());
      await _localStorageService.saveNote(synced.toMap());
      return synced;
    } catch (error) {
      await _syncQueueService.markFailed(queueId, error);
      return note;
    }
  }

  List<String> _normalizeCollaborators(
    List<String> collaborators,
    String ownerId,
  ) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final raw in [ownerId, ...collaborators]) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      final key = value.toLowerCase();
      if (seen.add(key)) normalized.add(value);
    }
    return normalized;
  }

  Future<String> _ownerId() async {
    return await _authService.currentUserId() ?? 'local-user';
  }
}
