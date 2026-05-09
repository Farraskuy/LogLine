import 'package:uuid/uuid.dart';

import 'local_storage_service.dart';

class SyncQueueService {
  SyncQueueService({LocalStorageService? localStorageService})
    : _localStorageService = localStorageService ?? LocalStorageService();

  final LocalStorageService _localStorageService;
  final Uuid _uuid = const Uuid();

  Future<void> initialize() async {
    if (!_localStorageService.syncQueue.isOpen) {
      await _localStorageService.initialize();
    }
  }

  Future<String> enqueue({
    required String collection,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final id = _uuid.v4();
    await _localStorageService.syncQueue.put(id, {
      'id': id,
      'collection': collection,
      'operation': operation,
      'payload': payload,
      'createdAt': DateTime.now().toIso8601String(),
      'retryCount': 0,
      'status': 'pending',
    });
    return id;
  }

  List<Map<String, dynamic>> pendingItems() {
    return _localStorageService.syncQueue.values
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['status'] == 'pending')
        .toList();
  }

  Future<void> markSynced(String id) async {
    final item = _localStorageService.syncQueue.get(id);
    if (item == null) return;
    await _localStorageService.syncQueue.put(id, {
      ...Map<String, dynamic>.from(item),
      'status': 'synced',
      'syncedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markFailed(String id, Object error) async {
    final item = _localStorageService.syncQueue.get(id);
    if (item == null) return;
    final current = Map<String, dynamic>.from(item);
    await _localStorageService.syncQueue.put(id, {
      ...current,
      'status': 'pending',
      'retryCount': (current['retryCount'] as int? ?? 0) + 1,
      'lastError': error.toString(),
    });
  }
}
