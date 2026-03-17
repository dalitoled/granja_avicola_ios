import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/farm_profile_model.dart';

class FarmService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<FarmProfileModel?> getFarmByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('granjas')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return FarmProfileModel.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      final querySnapshot = await _firestore.collection('granjas').get();
      final filtered = querySnapshot.docs.where((doc) {
        final data = doc.data();
        return data['userId'] == userId;
      });

      if (filtered.isNotEmpty) {
        return FarmProfileModel.fromMap(filtered.first.data());
      }
      return null;
    }
  }

  Future<FarmProfileModel?> getFarmById(String farmId) async {
    try {
      final doc = await _firestore.collection('granjas').doc(farmId).get();
      if (doc.exists) {
        return FarmProfileModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String> createFarm(FarmProfileModel farm) async {
    final docRef = _firestore.collection('granjas').doc();
    final farmWithId = farm.copyWith(id: docRef.id);
    await docRef.set(farmWithId.toMap());
    return docRef.id;
  }

  Future<void> updateFarm(FarmProfileModel farm) async {
    await _firestore.collection('granjas').doc(farm.id).update({
      'nombre': farm.nombre,
      'direccion': farm.direccion,
      'telefono': farm.telefono,
      'capacidad': farm.capacidad,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteFarm(String farmId) async {
    await _firestore.collection('granjas').doc(farmId).delete();
  }

  Stream<FarmProfileModel?> farmStream(String userId) {
    return _firestore
        .collection('granjas')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return FarmProfileModel.fromMap(snapshot.docs.first.data());
          }
          return null;
        });
  }
}
