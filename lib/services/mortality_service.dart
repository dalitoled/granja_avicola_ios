import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hen_mortality_model.dart';
import 'sync_service.dart';

class MortalityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SyncService _syncService = SyncService.instance;

  static const String _collection = 'mortalidad_gallinas';

  Future<String> addMortalityRecord(HenMortalityModel record) async {
    try {
      if (_syncService.isOnline) {
        DocumentReference docRef = await _firestore
            .collection(_collection)
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
      } else {
        final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: tempId,
          data: {
            'userId': record.userId,
            'lotId': record.lotId,
            'lotNumber': record.lotNumber,
            'date': record.date.toIso8601String(),
            'deadHens': record.deadHens,
            'cause': record.cause,
            'notes': record.notes,
            'createdAt': record.createdAt.toIso8601String(),
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
          'userId': record.userId,
          'lotId': record.lotId,
          'lotNumber': record.lotNumber,
          'date': record.date.toIso8601String(),
          'deadHens': record.deadHens,
          'cause': record.cause,
          'notes': record.notes,
          'createdAt': record.createdAt.toIso8601String(),
        },
        operation: 'create',
      );
      return tempId;
    }
  }

  Future<List<HenMortalityModel>> getMortalityByUser(String userId) async {
    if (_syncService.isOnline) {
      try {
        QuerySnapshot querySnapshot = await _firestore
            .collection(_collection)
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
        return await _getCachedMortality(userId);
      }
    } else {
      return await _getCachedMortality(userId);
    }
  }

  Future<List<HenMortalityModel>> _getCachedMortality(String userId) async {
    try {
      final cached = await _syncService.getCachedData(
        collection: _collection,
        userId: userId,
      );
      return cached.map((data) => HenMortalityModel.fromMap(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<HenMortalityModel>> getMortalityByLot(String lotId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
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
      return [];
    }
  }

  Future<int> getTotalMortalityByLot(String lotId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
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
          .collection(_collection)
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
      if (_syncService.isOnline) {
        await _firestore.collection(_collection).doc(mortalityId).delete();
      } else {
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: mortalityId,
          data: {},
          operation: 'delete',
        );
      }
    } catch (e) {
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: mortalityId,
        data: {},
        operation: 'delete',
      );
    }
  }

  Future<void> updateMortality(HenMortalityModel record) async {
    try {
      if (_syncService.isOnline) {
        await _firestore.collection(_collection).doc(record.id).update({
          'lotId': record.lotId,
          'lotNumber': record.lotNumber,
          'date': record.date.toIso8601String(),
          'deadHens': record.deadHens,
          'cause': record.cause,
          'notes': record.notes,
        });
      } else {
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: record.id,
          data: {
            'lotId': record.lotId,
            'lotNumber': record.lotNumber,
            'date': record.date.toIso8601String(),
            'deadHens': record.deadHens,
            'cause': record.cause,
            'notes': record.notes,
          },
          operation: 'update',
        );
      }
    } catch (e) {
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: record.id,
        data: {
          'lotId': record.lotId,
          'lotNumber': record.lotNumber,
          'date': record.date.toIso8601String(),
          'deadHens': record.deadHens,
          'cause': record.cause,
          'notes': record.notes,
        },
        operation: 'update',
      );
    }
  }
}
