import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_database_service.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  final LocalDatabaseService _localDb = LocalDatabaseService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _syncTimer;

  SyncService._init() {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.isNotEmpty &&
          !results.contains(ConnectivityResult.none);
      _updateConnectionStatus(isOnline);
    });
  }

  Future<void> _updateConnectionStatus(bool isOnline) async {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectionController.add(isOnline);
      if (isOnline) {
        await syncPendingData();
      }
    }
  }

  Future<void> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    final isOnline = results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);
    _updateConnectionStatus(isOnline);
  }

  Future<void> startAutoSync({Duration interval = const Duration(minutes: 1)}) async {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) async {
      if (_isOnline) {
        await syncPendingData();
      }
    });
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> saveForLaterSync({
    required String collection,
    String? documentId,
    required Map<String, dynamic> data,
    required String operation,
  }) async {
    await _localDb.insertPendingSync(
      collection: collection,
      documentId: documentId,
      data: jsonEncode(data),
      operation: operation,
    );
  }

  Future<void> syncPendingData() async {
    if (!_isOnline) return;

    final pendingItems = await _localDb.getPendingSyncItems();

    for (var item in pendingItems) {
      try {
        final collection = item['collection'] as String;
        final documentId = item['documentId'] as String?;
        final data = jsonDecode(item['data'] as String) as Map<String, dynamic>;
        final operation = item['operation'] as String;
        final id = item['id'] as int;

        switch (operation) {
          case 'create':
            if (documentId != null) {
              await _firestore.collection(collection).doc(documentId).set(data);
            } else {
              await _firestore.collection(collection).add(data);
            }
            break;
          case 'update':
            if (documentId != null) {
              await _firestore.collection(collection).doc(documentId).update(data);
            }
            break;
          case 'delete':
            if (documentId != null) {
              await _firestore.collection(collection).doc(documentId).delete();
            }
            break;
        }

        await _localDb.markAsSynced(id);
      } catch (e) {
        // Continue with next item
      }
    }
  }

  Future<int> getPendingSyncCount() async {
    return await _localDb.getPendingSyncCount();
  }

  Future<void> cacheData({
    required String collection,
    required String documentId,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    await _localDb.cacheData(
      collection: collection,
      documentId: documentId,
      userId: userId,
      data: jsonEncode(data),
    );
  }

  Future<List<Map<String, dynamic>>> getCachedData({
    required String collection,
    required String userId,
  }) async {
    final cached = await _localDb.getCachedData(
      collection: collection,
      userId: userId,
    );
    return cached.map((item) {
      return {
        ...jsonDecode(item['data'] as String) as Map<String, dynamic>,
        'id': item['documentId'],
      };
    }).toList();
  }

  void dispose() {
    _syncTimer?.cancel();
    _connectionController.close();
  }
}
