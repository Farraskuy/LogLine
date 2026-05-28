import 'package:mongo_dart/mongo_dart.dart';

import '../core/config/app_config.dart';
import '../features/notes/data/logline_note.dart';

class MongoNotesSyncService {
  MongoNotesSyncService({String? uri}) : _uri = uri ?? AppConfig.mongodbUri;

  final String _uri;

  bool get isConfigured => _uri.trim().isNotEmpty;

  Future<void> upsertNote(LogLineNote note) async {
    if (!isConfigured) {
      throw const MongoNotesSyncException('MONGODB_URI belum dikonfigurasi.');
    }
    final db = await _open();
    try {
      await db
          .collection('notes')
          .updateOne(
            where.eq('id', note.id),
            modify
                .set('id', note.id)
                .set('ownerId', note.ownerId)
                .set('title', note.title)
                .set('content', note.content)
                .set('tag', note.tag)
                .set('collaborators', note.collaborators)
                .set('createdAt', note.createdAt.toIso8601String())
                .set('updatedAt', note.updatedAt.toIso8601String())
                .set('isDeleted', note.isDeleted)
                .set('syncedAt', DateTime.now().toIso8601String()),
            upsert: true,
          );
    } finally {
      await db.close();
    }
  }

  Future<void> deleteNote(String id) async {
    if (!isConfigured) {
      throw const MongoNotesSyncException('MONGODB_URI belum dikonfigurasi.');
    }
    final db = await _open();
    try {
      await db
          .collection('notes')
          .updateOne(
            where.eq('id', id),
            modify
                .set('id', id)
                .set('isDeleted', true)
                .set('updatedAt', DateTime.now().toIso8601String())
                .set('syncedAt', DateTime.now().toIso8601String()),
            upsert: true,
          );
    } finally {
      await db.close();
    }
  }

  Future<List<LogLineNote>> fetchNotes(String ownerId) async {
    if (!isConfigured) return const [];
    final db = await _open();
    try {
      final rows = await db
          .collection('notes')
          .find(where.eq('ownerId', ownerId).ne('isDeleted', true))
          .toList();
      return rows.map((row) => LogLineNote.fromMap(row)).toList();
    } finally {
      await db.close();
    }
  }

  Future<Db> _open() async {
    final db = await Db.create(_uri);
    await db.open().timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        throw const MongoNotesSyncException('Koneksi MongoDB timeout.');
      },
    );
    return db;
  }
}

class MongoNotesSyncException implements Exception {
  const MongoNotesSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}
