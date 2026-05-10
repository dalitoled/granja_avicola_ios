import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/egg_production_model.dart';
import 'sync_service.dart';

class ProductionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SyncService _syncService = SyncService.instance;

  static const String _collection = 'produccion_diaria';

  Future<String> addProduction(EggProductionModel production) async {
    try {
      if (_syncService.isOnline) {
        DocumentReference docRef = await _firestore
            .collection(_collection)
            .add(production.toMap());
        return docRef.id;
      } else {
        final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: tempId,
          data: production.toMap(),
          operation: 'create',
        );
        return tempId;
      }
    } catch (e) {
      final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: tempId,
        data: production.toMap(),
        operation: 'create',
      );
      return tempId;
    }
  }

  Future<List<EggProductionModel>> getProductionsByUser(String userId) async {
    if (_syncService.isOnline) {
      try {
        QuerySnapshot querySnapshot = await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .get();

        List<EggProductionModel> productions = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return EggProductionModel.fromMap(data);
        }).toList();

        productions.sort((a, b) => b.date.compareTo(a.date));
        return productions;
      } catch (e) {
        return await _getCachedProductions(userId);
      }
    } else {
      return await _getCachedProductions(userId);
    }
  }

  Future<List<EggProductionModel>> _getCachedProductions(String userId) async {
    try {
      final cached = await _syncService.getCachedData(
        collection: _collection,
        userId: userId,
      );
      return cached.map((data) => EggProductionModel.fromMap(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<EggProductionModel>> getProductionsByUserStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      List<EggProductionModel> productions = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return EggProductionModel.fromMap(data);
      }).toList();
      productions.sort((a, b) => b.date.compareTo(a.date));
      return productions;
    });
  }

  Future<void> deleteProduction(String productionId) async {
    try {
      if (_syncService.isOnline) {
        await _firestore.collection(_collection).doc(productionId).delete();
      } else {
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: productionId,
          data: {},
          operation: 'delete',
        );
      }
    } catch (e) {
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: productionId,
        data: {},
        operation: 'delete',
      );
    }
  }

  Future<void> updateProduction(EggProductionModel production) async {
    try {
      if (_syncService.isOnline) {
        await _firestore.collection(_collection).doc(production.id).update(production.toMap());
      } else {
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: production.id,
          data: production.toMap(),
          operation: 'update',
        );
      }
    } catch (e) {
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: production.id,
        data: production.toMap(),
        operation: 'update',
      );
    }
  }
}
