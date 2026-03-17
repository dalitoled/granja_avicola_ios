import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/egg_sale_model.dart';

class SalesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> addSale(EggSaleModel sale) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('ventas_huevos')
          .add({
            'userId': sale.userId,
            'date': sale.date.toIso8601String(),
            'customer': sale.customer,
            'extraQuantity': sale.extraQuantity,
            'extraPrice': sale.extraPrice,
            'especialQuantity': sale.especialQuantity,
            'especialPrice': sale.especialPrice,
            'primeraQuantity': sale.primeraQuantity,
            'primeraPrice': sale.primeraPrice,
            'segundaQuantity': sale.segundaQuantity,
            'segundaPrice': sale.segundaPrice,
            'terceraQuantity': sale.terceraQuantity,
            'terceraPrice': sale.terceraPrice,
            'cuartaQuantity': sale.cuartaQuantity,
            'cuartaPrice': sale.cuartaPrice,
            'quintaQuantity': sale.quintaQuantity,
            'quintaPrice': sale.quintaPrice,
            'suciosQuantity': sale.suciosQuantity,
            'suciosPrice': sale.suciosPrice,
            'rajadosQuantity': sale.rajadosQuantity,
            'rajadosPrice': sale.rajadosPrice,
            'totalSale': sale.totalSale,
            'createdAt': sale.createdAt.toIso8601String(),
          });

      return docRef.id;
    } catch (e) {
      throw 'Error al guardar la venta: $e';
    }
  }

  Future<List<EggSaleModel>> getSalesByUser(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('ventas_huevos')
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
      throw 'Error al obtener las ventas: $e';
    }
  }

  Stream<List<EggSaleModel>> getSalesByUserStream(String userId) {
    return _firestore
        .collection('ventas_huevos')
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
      await _firestore.collection('ventas_huevos').doc(saleId).delete();
    } catch (e) {
      throw 'Error al eliminar venta: $e';
    }
  }

  Future<void> updateSale(EggSaleModel sale) async {
    try {
      await _firestore.collection('ventas_huevos').doc(sale.id).update({
        'date': sale.date.toIso8601String(),
        'customer': sale.customer,
        'extraQuantity': sale.extraQuantity,
        'extraPrice': sale.extraPrice,
        'especialQuantity': sale.especialQuantity,
        'especialPrice': sale.especialPrice,
        'primeraQuantity': sale.primeraQuantity,
        'primeraPrice': sale.primeraPrice,
        'segundaQuantity': sale.segundaQuantity,
        'segundaPrice': sale.segundaPrice,
        'terceraQuantity': sale.terceraQuantity,
        'terceraPrice': sale.terceraPrice,
        'cuartaQuantity': sale.cuartaQuantity,
        'cuartaPrice': sale.cuartaPrice,
        'quintaQuantity': sale.quintaQuantity,
        'quintaPrice': sale.quintaPrice,
        'suciosQuantity': sale.suciosQuantity,
        'suciosPrice': sale.suciosPrice,
        'rajadosQuantity': sale.rajadosQuantity,
        'rajadosPrice': sale.rajadosPrice,
        'totalSale': sale.totalSale,
        'isByMount': sale.isByMount,
      });
    } catch (e) {
      throw 'Error al actualizar venta: $e';
    }
  }
}
