import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:logline/features/notes/data/logline_note.dart';
import 'package:logline/features/notes/data/notes_repository.dart';
import 'package:logline/features/notes/data/notes_search_filter.dart';
import 'package:logline/services/auth_service.dart';
import 'package:logline/services/local_storage_service.dart';
import 'package:logline/services/mongo_notes_sync_service.dart';
import 'package:logline/services/sync_queue_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LocalStorageService storage;
  late FakeMongoNotesSyncService mongo;
  late NotesRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('logline_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<Map>(LocalStorageService.notesBoxName);
    await Hive.openBox<Map>(LocalStorageService.usersBoxName);
    await Hive.openBox<Map>(LocalStorageService.collaboratorsBoxName);
    await Hive.openBox<Map>(LocalStorageService.settingsBoxName);
    await Hive.openBox<Map>(LocalStorageService.syncQueueBoxName);

    storage = LocalStorageService();
    mongo = FakeMongoNotesSyncService();
    repository = NotesRepository(
      localStorageService: storage,
      authService: FakeAuthService('user-1'),
      syncService: mongo,
      syncQueueService: SyncQueueService(localStorageService: storage),
    );
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('CRUD notes menyimpan lokal dan cloud save ke Mongo', () async {
    final created = await repository.createNote(
      title: 'Rapat Produk',
      content: 'Catatan sprint dan backlog',
      tag: 'Personal',
    );

    expect(created.ownerId, 'user-1');
    expect((await repository.notes()).single.title, 'Rapat Produk');
    expect(mongo.upserted.single.id, created.id);
    expect(_queueStatuses(storage), contains('synced'));

    final updated = await repository.updateNote(
      created.copyWith(title: 'Rapat Produk Update'),
    );
    expect(
      (await repository.noteById(updated.id))!.title,
      'Rapat Produk Update',
    );
    expect(mongo.upserted.length, 2);

    await repository.deleteNote(updated.id);
    expect(await repository.noteById(updated.id), isNull);
    expect(mongo.deleted, contains(updated.id));
  });

  test(
    'sync queue retry mengirim pending item saat Mongo kembali tersedia',
    () async {
      mongo.failUpsert = true;
      final created = await repository.createNote(
        title: 'Offline Note',
        content: 'Tersimpan lokal dulu',
        tag: 'Personal',
      );

      expect(created.syncedAt, isNull);
      expect(_pendingItems(storage), hasLength(1));
      expect(_pendingItems(storage).single['retryCount'], 1);

      mongo.failUpsert = false;
      await repository.syncPending();

      expect(mongo.upserted.single.id, created.id);
      expect(_pendingItems(storage), isEmpty);
      expect(_queueStatuses(storage), contains('synced'));
    },
  );

  test('kolaborasi menambah dan menghapus collaborator pada note', () async {
    final note = await repository.createNote(
      title: 'Kolab desain',
      content: 'Bahas UX notes',
      tag: 'Personal',
    );

    final invited = await repository.addCollaborator(
      noteId: note.id,
      collaborator: 'dina@team.co',
    );

    expect(invited, isNotNull);
    expect(invited!.tag, 'Kolab');
    expect(invited.collaborators, contains('dina@team.co'));
    expect(storage.collaborators.values, isNotEmpty);

    final removed = await repository.removeCollaborator(
      noteId: note.id,
      collaborator: 'dina@team.co',
    );

    expect(removed!.collaborators, isNot(contains('dina@team.co')));
  });

  test('search dan filter mengembalikan notes sesuai query dan kategori', () {
    final notes = [
      _note(id: '1', title: 'Catatan pribadi', tag: 'Personal'),
      _note(
        id: '2',
        title: 'Audit bersama',
        tag: 'Kolab',
        collaborators: const ['user-1', 'dina@team.co'],
      ),
      _note(id: '3', title: 'Scan OCR invoice', tag: 'OCR'),
    ];

    expect(
      NotesSearchFilter.apply(
        notes: notes,
        query: 'audit',
        filter: NotesFilter.all,
        ownerId: 'user-1',
      ).map((note) => note.id),
      ['2'],
    );

    expect(
      NotesSearchFilter.apply(
        notes: notes,
        query: '',
        filter: NotesFilter.collaboration,
        ownerId: 'user-1',
      ).map((note) => note.id),
      ['2'],
    );

    expect(
      NotesSearchFilter.apply(
        notes: notes,
        query: '',
        filter: NotesFilter.ocr,
        ownerId: 'user-1',
      ).map((note) => note.id),
      ['3'],
    );
  });
}

class FakeAuthService extends AuthService {
  FakeAuthService(this.userId);

  final String userId;

  @override
  Future<String?> currentUserId() async => userId;
}

class FakeMongoNotesSyncService extends MongoNotesSyncService {
  FakeMongoNotesSyncService() : super(uri: 'mongodb://fake');

  final List<LogLineNote> upserted = [];
  final List<String> deleted = [];
  final List<LogLineNote> remoteNotes = [];
  bool failUpsert = false;

  @override
  bool get isConfigured => true;

  @override
  Future<void> upsertNote(LogLineNote note) async {
    if (failUpsert) throw const MongoNotesSyncException('offline');
    upserted.add(note);
  }

  @override
  Future<void> deleteNote(String id) async {
    deleted.add(id);
  }

  @override
  Future<List<LogLineNote>> fetchNotes(String ownerId) async {
    return remoteNotes.where((note) => note.ownerId == ownerId).toList();
  }
}

LogLineNote _note({
  required String id,
  required String title,
  required String tag,
  List<String> collaborators = const ['user-1'],
}) {
  final now = DateTime(2026, 5, 23);
  return LogLineNote(
    id: id,
    ownerId: 'user-1',
    title: title,
    content: 'Isi $title',
    tag: tag,
    collaborators: collaborators,
    createdAt: now,
    updatedAt: now,
  );
}

List<Map<String, dynamic>> _pendingItems(LocalStorageService storage) {
  return storage.syncQueue.values
      .map((item) => Map<String, dynamic>.from(item))
      .where((item) => item['status'] == 'pending')
      .toList();
}

List<String> _queueStatuses(LocalStorageService storage) {
  return storage.syncQueue.values
      .map((item) => Map<String, dynamic>.from(item)['status'] as String)
      .toList();
}
