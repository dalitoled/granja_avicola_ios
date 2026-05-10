import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final SyncService _syncService = SyncService.instance;
  StreamSubscription<bool>? _connectionSubscription;
  bool _isOnline = true;
  int _pendingSyncCount = 0;

  bool get isOnline => _isOnline;
  int get pendingSyncCount => _pendingSyncCount;

  ConnectivityProvider() {
    _init();
  }

  void _init() {
    _isOnline = _syncService.isOnline;
    _connectionSubscription = _syncService.connectionStream.listen((isOnline) {
      _isOnline = isOnline;
      notifyListeners();
      if (isOnline) {
        _updatePendingCount();
      }
    });
    _updatePendingCount();
  }

  Future<void> _updatePendingCount() async {
    _pendingSyncCount = await _syncService.getPendingSyncCount();
    notifyListeners();
  }

  Future<void> checkConnection() async {
    await _syncService.checkConnection();
    _isOnline = _syncService.isOnline;
    notifyListeners();
    await _updatePendingCount();
  }

  Future<void> syncNow() async {
    if (_isOnline) {
      await _syncService.syncPendingData();
      await _updatePendingCount();
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
