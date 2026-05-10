import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/egg_sale_model.dart';
import 'sync_service.dart';

class SalesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SyncService _syncService = SyncService.instance;

  static const String _collection = 'ventas_huevos';

  Future<String> addSale(EggSaleModel sale) async {
    try {
      if (_syncService.isOnline) {
        DocumentReference docRef = await _firestore
            .collection(_collection)
            .add(sale.toMap());

        return docRef.id;
      } else {
        final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: tempId,
          data: sale.toMap(),
          operation: 'create',
        );
        return tempId;
      }
    } catch (e) {
      final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: tempId,
        data: sale.toMap(),
        operation: 'create',
      );
      return tempId;
    }
  }

  Future<List<EggSaleModel>> getSalesByUser(String userId) async {
    if (_syncService.isOnline) {
      try {
        QuerySnapshot querySnapshot = await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .get();

        List<EggSaleModel> sales = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return EggSaleModel.fromMap(data);
        }).toList();

        sales.sort((a, b) => b.date.compareTo(a.date));
        return sales;
      } catch (e) {
        return await _getCachedSales(userId);
      }
    } else {
      return await _getCachedSales(userId);
    }
  }

  Future<List<EggSaleModel>> _getCachedSales(String userId) async {
    try {
      final cached = await _syncService.getCachedData(
        collection: _collection,
        userId: userId,
      );
      return cached.map((data) => EggSaleModel.fromMap(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<EggSaleModel>> getSalesByUserStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      List<EggSaleModel> sales = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return EggSaleModel.fromMap(data);
      }).toList();
      sales.sort((a, b) => b.date.compareTo(a.date));
      return sales;
    });
  }

  Future<void> deleteSale(String saleId) async {
    try {
      if (_syncService.isOnline) {
        await _firestore.collection(_collection).doc(saleId).delete();
      } else {
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: saleId,
          data: {},
          operation: 'delete',
        );
      }
    } catch (e) {
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: saleId,
        data: {},
        operation: 'delete',
      );
    }
  }

  Future<void> updateSale(EggSaleModel sale) async {
    try {
      if (_syncService.isOnline) {
        await _firestore.collection(_collection).doc(sale.id).update(sale.toMap());
      } else {
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: sale.id,
          data: sale.toMap(),
          operation: 'update',
        );
      }
    } catch (e) {
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: sale.id,
        data: sale.toMap(),
        operation: 'update',
      );
    }
  }
}