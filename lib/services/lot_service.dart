import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hen_lot_model.dart';

class LotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> addLot(HenLotModel lot) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('lotes_gallinas')
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
    } catch (e) {
      throw 'Error al guardar el lote: $e';
    }
  }

  Future<List<HenLotModel>> getLotsByUser(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('lotes_gallinas')
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
      throw 'Error al obtener los lotes: $e';
    }
  }

  Future<void> updateLot(HenLotModel lot) async {
    try {
      await _firestore.collection('lotes_gallinas').doc(lot.id).update({
        'lotNumber': lot.lotNumber,
        'breed': lot.breed,
        'supplier': lot.supplier,
        'startDate': lot.startDate.toIso8601String(),
        'initialHens': lot.initialHens,
        'currentHens': lot.currentHens,
        'notes': lot.notes,
      });
    } catch (e) {
      throw 'Error al actualizar el lote: $e';
    }
  }

  Future<void> deleteLot(String lotId) async {
    try {
      await _firestore.collection('lotes_gallinas').doc(lotId).delete();
    } catch (e) {
      throw 'Error al eliminar el lote: $e';
    }
  }

  Future<HenLotModel?> getLotById(String lotId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('lotes_gallinas')
          .doc(lotId)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return HenLotModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw 'Error al obtener el lote: $e';
    }
  }

  Future<bool> hasActiveLots(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('lotes_gallinas')
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
