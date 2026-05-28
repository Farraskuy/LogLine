import 'package:flutter_test/flutter_test.dart';
import 'package:logline/features/notes/data/logline_note.dart';
import 'package:logline/services/mongo_notes_sync_service.dart';

void main() {
  const mongodbUri = String.fromEnvironment('MONGODB_URI');

  test(
    'MongoNotesSyncService cloud save menulis dan menandai delete ke MongoDB Atlas',
    () async {
      final service = MongoNotesSyncService(uri: mongodbUri);
      final note = _testNote();

      await service.upsertNote(note);
      await service.deleteNote(note.id);
    },
    skip: mongodbUri.isEmpty
        ? 'Set MONGODB_URI dengan --dart-define untuk menjalankan test MongoDB Atlas asli.'
        : false,
    timeout: const Timeout(Duration(seconds: 45)),
  );

  test(
    'MongoNotesSyncService pull sync membaca notes dari MongoDB Atlas',
    () async {
      final service = MongoNotesSyncService(uri: mongodbUri);
      final note = _testNote();

      await service.upsertNote(note);
      try {
        final fetched = await service.fetchNotes(note.ownerId);
        expect(fetched.map((item) => item.id), contains(note.id));
      } catch (error) {
        if (error.toString().contains('not allowed to do action [find]')) {
          markTestSkipped(
            'MongoDB user belum punya permission find/read pada logline.notes.',
          );
          return;
        }
        rethrow;
      } finally {
        await service.deleteNote(note.id);
      }
    },
    skip: mongodbUri.isEmpty
        ? 'Set MONGODB_URI dengan --dart-define untuk menjalankan test MongoDB Atlas asli.'
        : false,
    timeout: const Timeout(Duration(seconds: 45)),
  );
}

LogLineNote _testNote() {
  final now = DateTime.now();
  return LogLineNote(
    id: 'test-${now.microsecondsSinceEpoch}',
    ownerId: 'mongo-test-user',
    title: 'Mongo integration test',
    content: 'Cloud save test dari automated test.',
    tag: 'Test',
    collaborators: const ['mongo-test-user'],
    createdAt: now,
    updatedAt: now,
  );
}
