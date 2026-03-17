import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hen_mortality_model.dart';

class MortalityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> addMortalityRecord(HenMortalityModel record) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('mortalidad_gallinas')
          .add({
            'userId': record.userId,
            'lotId': record.lotId,
            'lotNumber': record.lotNumber,
            'date': record.date.toIso8601String(),
            'deadHens': record.deadHens,
            'cause': record.cause,
            'notes': record.notes,
            'createdAt': record.createdAt.toIso8601String(),
          });

      return docRef.id;
    } catch (e) {
      throw 'Error al guardar el registro de mortalidad: $e';
    }
  }

  Future<List<HenMortalityModel>> getMortalityByUser(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('mortalidad_gallinas')
          .where('userId', isEqualTo: userId)
          .get();

      List<HenMortalityModel> records = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return HenMortalityModel.fromMap(data);
      }).toList();

      records.sort((a, b) => b.date.compareTo(a.date));
      return records;
    } catch (e) {
      throw 'Error al obtener los registros de mortalidad: $e';
    }
  }

  Future<List<HenMortalityModel>> getMortalityByLot(String lotId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('mortalidad_gallinas')
          .where('lotId', isEqualTo: lotId)
          .get();

      List<HenMortalityModel> records = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return HenMortalityModel.fromMap(data);
      }).toList();

      records.sort((a, b) => b.date.compareTo(a.date));
      return records;
    } catch (e) {
      throw 'Error al obtener los registros de mortalidad: $e';
    }
  }

  Future<int> getTotalMortalityByLot(String lotId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('mortalidad_gallinas')
          .where('lotId', isEqualTo: lotId)
          .get();

      int total = 0;
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        total += int.parse(data['deadHens']?.toString() ?? '0');
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, int>> getMortalityStatsByUser(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('mortalidad_gallinas')
          .where('userId', isEqualTo: userId)
          .get();

      Map<String, int> stats = {};
      int totalDead = 0;

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int dead = int.parse(data['deadHens']?.toString() ?? '0');
        totalDead += dead;

        String cause = data['cause']?.toString() ?? 'Unknown';
        stats[cause] = (stats[cause] ?? 0) + dead;
      }

      stats['total'] = totalDead;
      return stats;
    } catch (e) {
      return {'total': 0};
    }
  }

  Future<void> deleteMortality(String mortalityId) async {
    try {
      await _firestore.collection('mortalidad_gallinas').doc(mortalityId).delete();
    } catch (e) {
      throw 'Error al eliminar el registro: $e';
    }
  }

  Future<void> updateMortality(HenMortalityModel record) async {
    try {
      await _firestore.collection('mortalidad_gallinas').doc(record.id).update({
        'lotId': record.lotId,
        'lotNumber': record.lotNumber,
        'date': record.date.toIso8601String(),
        'deadHens': record.deadHens,
        'cause': record.cause,
        'notes': record.notes,
      });
    } catch (e) {
      throw 'Error al actualizar el registro: $e';
    }
  }
}
