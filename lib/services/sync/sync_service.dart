import 'dart:async';


import '../../core/config/app_config.dart';
import '../../repositories/lumora_repository.dart';

/// Sync status exposed to the UI.
enum SyncStatus { synced, pending, syncing, failed, disabled }

/// Offline-first sync orchestrator.
///
/// Local writes always succeed first. When Firebase cloud sync is enabled,
/// pending operations are flushed opportunistically. UI surfaces the status
/// honestly: "synced" only when everything reached the backend.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  SyncStatus _status = SyncStatus.synced;
  Timer? _timer;

  Stream<SyncStatus> get statusStream => _statusController.stream;
  SyncStatus get status => _status;

  void start() {
    if (AppConfig.isFirebaseAvailable && AppConfig.enableCloudSync) {
      _setStatus(SyncStatus.pending);
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => syncNow());
    } else {
      // Fully local mode: everything is "saved on device".
      _setStatus(SyncStatus.synced);
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> syncNow() async {
    if (!AppConfig.isFirebaseAvailable || !AppConfig.enableCloudSync) return;
    final int pending = LumoraRepository.instance.pendingOps;
    if (pending == 0) {
      _setStatus(SyncStatus.synced);
      return;
    }
    _setStatus(SyncStatus.syncing);
    try {
      final int flushed = await LumoraRepository.instance.flushPendingOps();
      _setStatus(flushed >= pending ? SyncStatus.synced : SyncStatus.pending);
    } on Exception {
      _setStatus(SyncStatus.failed);
    }
  }

  void _setStatus(SyncStatus s) {
    if (_status == s) return;
    _status = s;
    if (!_statusController.isClosed) {
      _statusController.add(s);
    }
  }

  void dispose() {
    _timer?.cancel();
    _statusController.close();
  }
}
