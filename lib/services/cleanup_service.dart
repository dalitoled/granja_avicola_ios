import 'package:cloud_firestore/cloud_firestore.dart';

class CleanupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static final CleanupService _instance = CleanupService._internal();
  factory CleanupService() => _instance;
  CleanupService._internal();

  Future<void> deleteSimulationData(String userId) async {
    final collections = [
      'produccion_diaria',
      'ventas_huevos',
      'consumo_alimento',
      'mortalidad',
      'gastos',
      'inventario_alimento',
      'plan_vacunacion',
    ];

    for (String collection in collections) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection(collection)
            .where('userId', isEqualTo: userId)
            .get();

        for (DocumentSnapshot doc in snapshot.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        print('Error deleting $collection: $e');
      }
    }

    // Delete lot
    try {
      QuerySnapshot lotSnapshot = await _firestore
          .collection('lotes')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (DocumentSnapshot doc in lotSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting lots: $e');
    }
  }
}