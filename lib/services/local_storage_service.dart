import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  static const notesBoxName = 'notes';
  static const usersBoxName = 'users';
  static const collaboratorsBoxName = 'collaborators';
  static const settingsBoxName = 'settings';
  static const syncQueueBoxName = 'sync_queue';

  Future<void> initialize() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<Map>(notesBoxName),
      Hive.openBox<Map>(usersBoxName),
      Hive.openBox<Map>(collaboratorsBoxName),
      Hive.openBox<Map>(settingsBoxName),
      Hive.openBox<Map>(syncQueueBoxName),
    ]);
  }

  Box<Map> get notes => Hive.box<Map>(notesBoxName);
  Box<Map> get users => Hive.box<Map>(usersBoxName);
  Box<Map> get collaborators => Hive.box<Map>(collaboratorsBoxName);
  Box<Map> get settings => Hive.box<Map>(settingsBoxName);
  Box<Map> get syncQueue => Hive.box<Map>(syncQueueBoxName);

  Future<void> saveNote(Map<String, dynamic> note) async {
    final id = note['id'] as String?;
    if (id == null || id.isEmpty) {
      throw ArgumentError('Note must contain a non-empty id.');
    }
    await notes.put(id, Map<String, dynamic>.from(note));
  }

  Map<String, dynamic>? getNote(String id) {
    final note = notes.get(id);
    return note == null ? null : Map<String, dynamic>.from(note);
  }

  List<Map<String, dynamic>> getAllNotes() {
    return notes.values.map((note) => Map<String, dynamic>.from(note)).toList();
  }

  Future<void> deleteNote(String id) async {
    await notes.delete(id);
  }
}
