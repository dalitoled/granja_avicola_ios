import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_consumption_model.dart';

class FeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> addFeedConsumption(FeedConsumptionModel feed) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('consumo_alimento')
          .add({
            'userId': feed.userId,
            'date': feed.date.toIso8601String(),
            'hensCount': feed.hensCount,
            'feedKg': feed.feedKg,
            'feedType': feed.feedType,
            'pricePerKg': feed.pricePerKg,
            'feedCost': feed.feedCost,
            'notes': feed.notes,
            'createdAt': feed.createdAt.toIso8601String(),
          });

      return docRef.id;
    } catch (e) {
      throw 'Error al guardar el consumo de alimento: $e';
    }
  }

  Future<List<FeedConsumptionModel>> getFeedConsumptionByUser(
    String userId,
  ) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('consumo_alimento')
          .where('userId', isEqualTo: userId)
          .get();

      List<FeedConsumptionModel> feedList = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return FeedConsumptionModel.fromMap(data);
      }).toList();

      feedList.sort((a, b) => b.date.compareTo(a.date));
      return feedList;
    } catch (e) {
      throw 'Error al obtener el consumo de alimento: $e';
    }
  }

  Future<FeedConsumptionModel?> getFeedConsumptionByDate(
    String userId,
    DateTime date,
  ) async {
    try {
      String dateStr = DateTime(
        date.year,
        date.month,
        date.day,
      ).toIso8601String().split('T')[0];

      QuerySnapshot querySnapshot = await _firestore
          .collection('consumo_alimento')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String docDate = DateTime.parse(
          data['date'],
        ).toIso8601String().split('T')[0];
        if (docDate == dateStr) {
          data['id'] = doc.id;
          return FeedConsumptionModel.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteFeedConsumption(String consumptionId) async {
    try {
      await _firestore.collection('consumo_alimento').doc(consumptionId).delete();
    } catch (e) {
      throw 'Error al eliminar consumo: $e';
    }
  }

  Future<void> updateFeedConsumption(FeedConsumptionModel feed) async {
    try {
      await _firestore.collection('consumo_alimento').doc(feed.id).update({
        'date': feed.date.toIso8601String(),
        'hensCount': feed.hensCount,
        'feedKg': feed.feedKg,
        'feedType': feed.feedType,
        'pricePerKg': feed.pricePerKg,
        'feedCost': feed.feedCost,
        'notes': feed.notes,
      });
    } catch (e) {
      throw 'Error al actualizar consumo: $e';
    }
  }
}
