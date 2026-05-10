import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hen_lot_model.dart';
import 'sync_service.dart';

class LotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SyncService _syncService = SyncService.instance;

  static const String _collection = 'lotes_gallinas';

  Future<String> addLot(HenLotModel lot) async {
    try {
      if (_syncService.isOnline) {
        DocumentReference docRef = await _firestore
            .collection(_collection)
            .add({
              'userId': lot.userId,
              'lotNumber': lot.lotNumber,
              'breed': lot.breed,
              'supplier': lot.supplier,
              'startDate': lot.startDate.toIso8601String(),
              'initialHens': lot.initialHens,
              'currentHens': lot.currentHens,
              'notes': lot.notes,
              'createdAt': lot.createdAt.toIso8601String(),
            });

        return docRef.id;
      } else {
        final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: tempId,
          data: {
            'userId': lot.userId,
            'lotNumber': lot.lotNumber,
            'breed': lot.breed,
            'supplier': lot.supplier,
            'startDate': lot.startDate.toIso8601String(),
            'initialHens': lot.initialHens,
            'currentHens': lot.currentHens,
            'notes': lot.notes,
            'createdAt': lot.createdAt.toIso8601String(),
          },
          operation: 'create',
        );
        return tempId;
      }
    } catch (e) {
      final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: tempId,
        data: {
          'userId': lot.userId,
          'lotNumber': lot.lotNumber,
          'breed': lot.breed,
          'supplier': lot.supplier,
          'startDate': lot.startDate.toIso8601String(),
          'initialHens': lot.initialHens,
          'currentHens': lot.currentHens,
          'notes': lot.notes,
          'createdAt': lot.createdAt.toIso8601String(),
        },
        operation: 'create',
      );
      return tempId;
    }
  }

  Future<List<HenLotModel>> getLotsByUser(String userId) async {
    if (_syncService.isOnline) {
      try {
        QuerySnapshot querySnapshot = await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .get();

        List<HenLotModel> lots = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return HenLotModel.fromMap(data);
        }).toList();

        lots.sort((a, b) => b.startDate.compareTo(a.startDate));
        return lots;
      } catch (e) {
        return await _getCachedLots(userId);
      }
    } else {
      return await _getCachedLots(userId);
    }
  }

  Future<List<HenLotModel>> _getCachedLots(String userId) async {
    try {
      final cached = await _syncService.getCachedData(
        collection: _collection,
        userId: userId,
      );
      return cached.map((data) => HenLotModel.fromMap(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateLot(HenLotModel lot) async {
    try {
      if (_syncService.isOnline) {
        await _firestore.collection(_collection).doc(lot.id).update({
          'lotNumber': lot.lotNumber,
          'breed': lot.breed,
          'supplier': lot.supplier,
          'startDate': lot.startDate.toIso8601String(),
          'initialHens': lot.initialHens,
          'currentHens': lot.currentHens,
          'notes': lot.notes,
        });
      } else {
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: lot.id,
          data: {
            'lotNumber': lot.lotNumber,
            'breed': lot.breed,
            'supplier': lot.supplier,
            'startDate': lot.startDate.toIso8601String(),
            'initialHens': lot.initialHens,
            'currentHens': lot.currentHens,
            'notes': lot.notes,
          },
          operation: 'update',
        );
      }
    } catch (e) {
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: lot.id,
        data: {
          'lotNumber': lot.lotNumber,
          'breed': lot.breed,
          'supplier': lot.supplier,
          'startDate': lot.startDate.toIso8601String(),
          'initialHens': lot.initialHens,
          'currentHens': lot.currentHens,
          'notes': lot.notes,
        },
        operation: 'update',
      );
    }
  }

  Future<void> deleteLot(String lotId) async {
    try {
      if (_syncService.isOnline) {
        await _firestore.collection(_collection).doc(lotId).delete();
      } else {
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: lotId,
          data: {},
          operation: 'delete',
        );
      }
    } catch (e) {
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: lotId,
        data: {},
        operation: 'delete',
      );
    }
  }

  Future<HenLotModel?> getLotById(String lotId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collection)
          .doc(lotId)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return HenLotModel.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> hasActiveLots(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int currentHens = int.tryParse(data['currentHens']?.toString() ?? '0') ?? 0;
        if (currentHens > 0) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
