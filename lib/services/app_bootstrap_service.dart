import 'local_storage_service.dart';
import 'sync_queue_service.dart';

class AppBootstrapService {
  AppBootstrapService({
    LocalStorageService? localStorageService,
    SyncQueueService? syncQueueService,
  }) : _localStorageService = localStorageService ?? LocalStorageService(),
       _syncQueueService = syncQueueService ?? SyncQueueService();

  final LocalStorageService _localStorageService;
  final SyncQueueService _syncQueueService;

  Future<void> initialize() async {
    await _localStorageService.initialize();
    await _syncQueueService.initialize();
  }
}
