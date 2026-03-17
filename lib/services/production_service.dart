import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/egg_production_model.dart';

class ProductionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> addProduction(EggProductionModel production) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('produccion_diaria')
          .add({
            'userId': production.userId,
            'date': production.date.toIso8601String(),
            'extra': production.extra,
            'especial': production.especial,
            'primera': production.primera,
            'segunda': production.segunda,
            'tercera': production.tercera,
            'cuarta': production.cuarta,
            'quinta': production.quinta,
            'sucios': production.sucios,
            'rajados': production.rajados,
            'descarte': production.descarte,
            'totalHuevos': production.totalHuevos,
            'createdAt': production.createdAt.toIso8601String(),
          });

      return docRef.id;
    } catch (e) {
      throw 'Error al guardar la producción: $e';
    }
  }

  Future<List<EggProductionModel>> getProductionsByUser(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('produccion_diaria')
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
      throw 'Error al obtener la producción: $e';
    }
  }

  Stream<List<EggProductionModel>> getProductionsByUserStream(String userId) {
    return _firestore
        .collection('produccion_diaria')
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
      await _firestore.collection('produccion_diaria').doc(productionId).delete();
    } catch (e) {
      throw 'Error al eliminar producción: $e';
    }
  }

  Future<void> updateProduction(EggProductionModel production) async {
    try {
      await _firestore.collection('produccion_diaria').doc(production.id).update({
        'date': production.date.toIso8601String(),
        'extra': production.extra,
        'especial': production.especial,
        'primera': production.primera,
        'segunda': production.segunda,
        'tercera': production.tercera,
        'cuarta': production.cuarta,
        'quinta': production.quinta,
        'sucios': production.sucios,
        'rajados': production.rajados,
        'descarte': production.descarte,
        'totalHuevos': production.totalHuevos,
      });
    } catch (e) {
      throw 'Error al actualizar producción: $e';
    }
  }
}
