import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_inventory_model.dart';
import '../models/feed_purchase_model.dart';

class FeedInventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> defaultFeedTypes = [
    'Inicial',
    'Crecimiento',
    'Engorde',
    'Postura',
    'Reproducción',
  ];

  Future<List<FeedInventoryModel>> getInventory(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('inventario_alimento')
          .where('userId', isEqualTo: userId)
          .get();

      List<FeedInventoryModel> inventory = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return FeedInventoryModel.fromMap(data);
      }).toList();

      inventory.sort((a, b) => a.feedType.compareTo(b.feedType));
      return inventory;
    } catch (e) {
      throw 'Error al obtener inventario: $e';
    }
  }

  Future<FeedInventoryModel?> getInventoryByType(
    String userId,
    String feedType,
  ) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('inventario_alimento')
          .where('userId', isEqualTo: userId)
          .where('feedType', isEqualTo: feedType)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      Map<String, dynamic> data =
          querySnapshot.docs.first.data() as Map<String, dynamic>;
      data['id'] = querySnapshot.docs.first.id;
      return FeedInventoryModel.fromMap(data);
    } catch (e) {
      throw 'Error al obtener inventario por tipo: $e';
    }
  }

  Future<void> initializeInventory(String userId) async {
    try {
      for (String feedType in defaultFeedTypes) {
        final existing = await getInventoryByType(userId, feedType);
        if (existing == null) {
          await _firestore.collection('inventario_alimento').add({
            'userId': userId,
            'feedType': feedType,
            'stockKg': 0.0,
            'minimumStock': 50.0,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      throw 'Error al inicializar inventario: $e';
    }
  }

  Future<void> updateStock(
    String userId,
    String feedType,
    double newStock,
    double? minimumStock,
    double? pricePerKg,
  ) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('inventario_alimento')
          .where('userId', isEqualTo: userId)
          .where('feedType', isEqualTo: feedType)
          .get();

      if (querySnapshot.docs.isEmpty) {
        await _firestore.collection('inventario_alimento').add({
          'userId': userId,
          'feedType': feedType,
          'stockKg': newStock,
          'minimumStock': minimumStock ?? 50.0,
          'pricePerKg': pricePerKg ?? 0.0,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } else {
        await querySnapshot.docs.first.reference.update({
          'stockKg': newStock,
          'minimumStock': minimumStock,
          'pricePerKg': pricePerKg,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw 'Error al actualizar stock: $e';
    }
  }

  Future<void> addStock(
    String userId,
    String feedType,
    double quantityKg,
  ) async {
    try {
      final current = await getInventoryByType(userId, feedType);
      double newStock = (current?.stockKg ?? 0) + quantityKg;
      await updateStock(
        userId,
        feedType,
        newStock,
        current?.minimumStock,
        current?.pricePerKg,
      );
    } catch (e) {
      throw 'Error al agregar stock: $e';
    }
  }

  Future<void> subtractStock(
    String userId,
    String feedType,
    double quantityKg,
  ) async {
    try {
      final current = await getInventoryByType(userId, feedType);
      double newStock = (current?.stockKg ?? 0) - quantityKg;
      if (newStock < 0) newStock = 0;
      await updateStock(
        userId,
        feedType,
        newStock,
        current?.minimumStock,
        current?.pricePerKg,
      );
    } catch (e) {
      throw 'Error al descontar stock: $e';
    }
  }

  Future<String> addPurchase(FeedPurchaseModel purchase) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('compras_alimento')
          .add({
            'userId': purchase.userId,
            'feedType': purchase.feedType,
            'quantityKg': purchase.quantityKg,
            'pricePerKg': purchase.pricePerKg,
            'totalCost': purchase.totalCost,
            'supplier': purchase.supplier,
            'date': purchase.date.toIso8601String(),
            'notes': purchase.notes,
            'createdAt': purchase.createdAt.toIso8601String(),
          });

      final current = await getInventoryByType(
        purchase.userId,
        purchase.feedType,
      );
      double newStock = (current?.stockKg ?? 0) + purchase.quantityKg;
      await updateStock(
        purchase.userId,
        purchase.feedType,
        newStock,
        current?.minimumStock,
        purchase.pricePerKg,
      );

      return docRef.id;
    } catch (e) {
      throw 'Error al registrar compra: $e';
    }
  }

  Future<List<FeedPurchaseModel>> getPurchaseHistory(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('compras_alimento')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();

      List<FeedPurchaseModel> purchases = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return FeedPurchaseModel.fromMap(data);
      }).toList();

      return purchases;
    } catch (e) {
      if (e.toString().contains('failed-precondition')) {
        try {
          QuerySnapshot querySnapshot = await _firestore
              .collection('compras_alimento')
              .where('userId', isEqualTo: userId)
              .get();

          List<FeedPurchaseModel> purchases = querySnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return FeedPurchaseModel.fromMap(data);
          }).toList();

          purchases.sort((a, b) => b.date.compareTo(a.date));
          return purchases;
        } catch (fallbackError) {
          throw 'Error al obtener historial: $fallbackError';
        }
      }
      throw 'Error al obtener historial de compras: $e';
    }
  }

  Future<List<FeedPurchaseModel>> getPurchasesByType(
    String userId,
    String feedType,
  ) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('compras_alimento')
          .where('userId', isEqualTo: userId)
          .where('feedType', isEqualTo: feedType)
          .orderBy('date', descending: true)
          .get();

      List<FeedPurchaseModel> purchases = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return FeedPurchaseModel.fromMap(data);
      }).toList();

      return purchases;
    } catch (e) {
      if (e.toString().contains('failed-precondition')) {
        try {
          QuerySnapshot querySnapshot = await _firestore
              .collection('compras_alimento')
              .where('userId', isEqualTo: userId)
              .get();

          List<FeedPurchaseModel> allPurchases = querySnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return FeedPurchaseModel.fromMap(data);
          }).toList();

          List<FeedPurchaseModel> filtered = allPurchases
              .where((p) => p.feedType == feedType)
              .toList();
          filtered.sort((a, b) => b.date.compareTo(a.date));
          return filtered;
        } catch (fallbackError) {
          throw 'Error al obtener compras por tipo: $fallbackError';
        }
      }
      throw 'Error al obtener compras por tipo: $e';
    }
  }

  Future<List<FeedInventoryModel>> getLowStockItems(String userId) async {
    try {
      List<FeedInventoryModel> inventory = await getInventory(userId);
      return inventory.where((item) => item.isLowStock).toList();
    } catch (e) {
      throw 'Error al obtener items con stock bajo: $e';
    }
  }

  Future<double> getTotalInventoryValue(String userId) async {
    try {
      List<FeedInventoryModel> inventory = await getInventory(userId);
      double totalValue = 0;

      for (var item in inventory) {
        List<FeedPurchaseModel> purchases = await getPurchasesByType(
          userId,
          item.feedType,
        );
        if (purchases.isNotEmpty) {
          double lastPrice = purchases.first.pricePerKg;
          totalValue += item.stockKg * lastPrice;
        }
      }

      return totalValue;
    } catch (e) {
      throw 'Error al calcular valor total: $e';
    }
  }

  Future<void> deleteFeedType(String userId, String feedType) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('inventario_alimento')
          .where('userId', isEqualTo: userId)
          .where('feedType', isEqualTo: feedType)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw 'Error al eliminar tipo de alimento: $e';
    }
  }

  Future<void> deletePurchase(String purchaseId) async {
    try {
      await _firestore.collection('compras_alimento').doc(purchaseId).delete();
    } catch (e) {
      throw 'Error al eliminar compra: $e';
    }
  }

  Future<void> updatePurchase(FeedPurchaseModel purchase) async {
    try {
      await _firestore.collection('compras_alimento').doc(purchase.id).update({
        'feedType': purchase.feedType,
        'quantityKg': purchase.quantityKg,
        'pricePerKg': purchase.pricePerKg,
        'totalCost': purchase.totalCost,
        'supplier': purchase.supplier,
        'date': purchase.date.toIso8601String(),
        'notes': purchase.notes,
      });
    } catch (e) {
      throw 'Error al actualizar compra: $e';
    }
  }
}
