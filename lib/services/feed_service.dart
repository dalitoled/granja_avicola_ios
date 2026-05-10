import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_consumption_model.dart';
import 'sync_service.dart';

class FeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SyncService _syncService = SyncService.instance;

  static const String _collection = 'consumo_alimento';

  Future<String> addFeedConsumption(FeedConsumptionModel feed) async {
    try {
      if (_syncService.isOnline) {
        DocumentReference docRef = await _firestore
            .collection(_collection)
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
      } else {
        final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: tempId,
          data: {
            'userId': feed.userId,
            'date': feed.date.toIso8601String(),
            'hensCount': feed.hensCount,
            'feedKg': feed.feedKg,
            'feedType': feed.feedType,
            'pricePerKg': feed.pricePerKg,
            'feedCost': feed.feedCost,
            'notes': feed.notes,
            'createdAt': feed.createdAt.toIso8601String(),
          },
          operation: 'create',
        );
        return tempId;
      }
    } catch (e) {
      final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: tempId,
        data: {
          'userId': feed.userId,
          'date': feed.date.toIso8601String(),
          'hensCount': feed.hensCount,
          'feedKg': feed.feedKg,
          'feedType': feed.feedType,
          'pricePerKg': feed.pricePerKg,
          'feedCost': feed.feedCost,
          'notes': feed.notes,
          'createdAt': feed.createdAt.toIso8601String(),
        },
        operation: 'create',
      );
      return tempId;
    }
  }

  Future<List<FeedConsumptionModel>> getFeedConsumptionByUser(
    String userId,
  ) async {
    if (_syncService.isOnline) {
      try {
        QuerySnapshot querySnapshot = await _firestore
            .collection(_collection)
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
        return await _getCachedFeed(userId);
      }
    } else {
      return await _getCachedFeed(userId);
    }
  }

  Future<List<FeedConsumptionModel>> _getCachedFeed(String userId) async {
    try {
      final cached = await _syncService.getCachedData(
        collection: _collection,
        userId: userId,
      );
      return cached.map((data) => FeedConsumptionModel.fromMap(data)).toList();
    } catch (e) {
      return [];
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
          .collection(_collection)
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
      if (_syncService.isOnline) {
        await _firestore.collection(_collection).doc(consumptionId).delete();
      } else {
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: consumptionId,
          data: {},
          operation: 'delete',
        );
      }
    } catch (e) {
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: consumptionId,
        data: {},
        operation: 'delete',
      );
    }
  }

  Future<void> updateFeedConsumption(FeedConsumptionModel feed) async {
    try {
      if (_syncService.isOnline) {
        await _firestore.collection(_collection).doc(feed.id).update({
          'date': feed.date.toIso8601String(),
          'hensCount': feed.hensCount,
          'feedKg': feed.feedKg,
          'feedType': feed.feedType,
          'pricePerKg': feed.pricePerKg,
          'feedCost': feed.feedCost,
          'notes': feed.notes,
        });
      } else {
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: feed.id,
          data: {
            'date': feed.date.toIso8601String(),
            'hensCount': feed.hensCount,
            'feedKg': feed.feedKg,
            'feedType': feed.feedType,
            'pricePerKg': feed.pricePerKg,
            'feedCost': feed.feedCost,
            'notes': feed.notes,
          },
          operation: 'update',
        );
      }
    } catch (e) {
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: feed.id,
        data: {
          'date': feed.date.toIso8601String(),
          'hensCount': feed.hensCount,
          'feedKg': feed.feedKg,
          'feedType': feed.feedType,
          'pricePerKg': feed.pricePerKg,
          'feedCost': feed.feedCost,
          'notes': feed.notes,
        },
        operation: 'update',
      );
    }
  }
}
