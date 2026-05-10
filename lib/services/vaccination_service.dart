import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vaccination_model.dart';
import 'sync_service.dart';

class VaccinationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SyncService _syncService = SyncService.instance;

  static const String _collection = 'plan_vacunacion';

  Future<String> addVaccination(VaccinationModel vaccination) async {
    try {
      if (_syncService.isOnline) {
        DocumentReference docRef = await _firestore
            .collection(_collection)
            .add({
              'userId': vaccination.userId,
              'lotId': vaccination.lotId,
              'lotNumber': vaccination.lotNumber,
              'vaccineName': vaccination.vaccineName,
              'applicationDate': vaccination.applicationDate.toIso8601String(),
              'nextDoseDate': vaccination.nextDoseDate?.toIso8601String(),
              'dose': vaccination.dose,
              'method': vaccination.method,
              'notes': vaccination.notes,
              'createdAt': vaccination.createdAt.toIso8601String(),
            });

        return docRef.id;
      } else {
        final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: tempId,
          data: {
            'userId': vaccination.userId,
            'lotId': vaccination.lotId,
            'lotNumber': vaccination.lotNumber,
            'vaccineName': vaccination.vaccineName,
            'applicationDate': vaccination.applicationDate.toIso8601String(),
            'nextDoseDate': vaccination.nextDoseDate?.toIso8601String(),
            'dose': vaccination.dose,
            'method': vaccination.method,
            'notes': vaccination.notes,
            'createdAt': vaccination.createdAt.toIso8601String(),
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
          'userId': vaccination.userId,
          'lotId': vaccination.lotId,
          'lotNumber': vaccination.lotNumber,
          'vaccineName': vaccination.vaccineName,
          'applicationDate': vaccination.applicationDate.toIso8601String(),
          'nextDoseDate': vaccination.nextDoseDate?.toIso8601String(),
          'dose': vaccination.dose,
          'method': vaccination.method,
          'notes': vaccination.notes,
          'createdAt': vaccination.createdAt.toIso8601String(),
        },
        operation: 'create',
      );
      return tempId;
    }
  }

  Future<List<VaccinationModel>> getVaccinationsByUser(String userId) async {
    if (_syncService.isOnline) {
      try {
        QuerySnapshot querySnapshot = await _firestore
            .collection(_collection)
            .where('userId', isEqualTo: userId)
            .get();

        List<VaccinationModel> vaccinations = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return VaccinationModel.fromMap(data);
        }).toList();

        vaccinations.sort(
          (a, b) => b.applicationDate.compareTo(a.applicationDate),
        );
        return vaccinations;
      } catch (e) {
        return await _getCachedVaccinations(userId);
      }
    } else {
      return await _getCachedVaccinations(userId);
    }
  }

  Future<List<VaccinationModel>> _getCachedVaccinations(String userId) async {
    try {
      final cached = await _syncService.getCachedData(
        collection: _collection,
        userId: userId,
      );
      return cached.map((data) => VaccinationModel.fromMap(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<VaccinationModel>> getVaccinationsByLot(String lotId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('lotId', isEqualTo: lotId)
          .get();

      List<VaccinationModel> vaccinations = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return VaccinationModel.fromMap(data);
      }).toList();

      vaccinations.sort(
        (a, b) => b.applicationDate.compareTo(a.applicationDate),
      );
      return vaccinations;
    } catch (e) {
      return [];
    }
  }

  Future<List<VaccinationModel>> getUpcomingVaccinations(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      List<VaccinationModel> vaccinations = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return VaccinationModel.fromMap(data);
      }).toList();

      List<VaccinationModel> upcoming = vaccinations
          .where(
            (v) =>
                v.isCompleted == false &&
                v.nextDoseDate != null &&
                !v.nextDoseDate!.isBefore(DateTime.now()),
          )
          .toList();

      upcoming.sort((a, b) => a.nextDoseDate!.compareTo(b.nextDoseDate!));
      return upcoming;
    } catch (e) {
      throw 'Error al obtener las próximas vaccinations: $e';
    }
  }

  Future<List<VaccinationModel>> getAllFutureVaccinations(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      List<VaccinationModel> vaccinations = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return VaccinationModel.fromMap(data);
      }).toList();

      DateTime now = DateTime.now();
      List<VaccinationModel> allFuture = [];

      for (var v in vaccinations) {
        if (v.isCompleted) continue;
        if (v.nextDoseDate != null && !v.nextDoseDate!.isBefore(now)) {
          allFuture.add(v);
        }
        if (!v.applicationDate.isBefore(now)) {
          allFuture.add(v);
        }
      }

      allFuture.sort((a, b) {
        DateTime aDate = a.nextDoseDate ?? a.applicationDate;
        DateTime bDate = b.nextDoseDate ?? b.applicationDate;
        return aDate.compareTo(bDate);
      });

      return allFuture;
    } catch (e) {
      throw 'Error al obtener las vaccinations futuras: $e';
    }
  }

  Future<void> deleteVaccination(String vaccinationId) async {
    try {
      if (_syncService.isOnline) {
        await _firestore.collection(_collection).doc(vaccinationId).delete();
      } else {
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: vaccinationId,
          data: {},
          operation: 'delete',
        );
      }
    } catch (e) {
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: vaccinationId,
        data: {},
        operation: 'delete',
      );
    }
  }

  Future<void> updateVaccination(VaccinationModel vaccination) async {
    try {
      if (_syncService.isOnline) {
        await _firestore.collection(_collection).doc(vaccination.id).update({
          'lotId': vaccination.lotId,
          'lotNumber': vaccination.lotNumber,
          'vaccineName': vaccination.vaccineName,
          'applicationDate': vaccination.applicationDate.toIso8601String(),
          'nextDoseDate': vaccination.nextDoseDate?.toIso8601String(),
          'dose': vaccination.dose,
          'method': vaccination.method,
          'notes': vaccination.notes,
        });
      } else {
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: vaccination.id,
          data: {
            'lotId': vaccination.lotId,
            'lotNumber': vaccination.lotNumber,
            'vaccineName': vaccination.vaccineName,
            'applicationDate': vaccination.applicationDate.toIso8601String(),
            'nextDoseDate': vaccination.nextDoseDate?.toIso8601String(),
            'dose': vaccination.dose,
            'method': vaccination.method,
            'notes': vaccination.notes,
          },
          operation: 'update',
        );
      }
    } catch (e) {
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: vaccination.id,
        data: {
          'lotId': vaccination.lotId,
          'lotNumber': vaccination.lotNumber,
          'vaccineName': vaccination.vaccineName,
          'applicationDate': vaccination.applicationDate.toIso8601String(),
          'nextDoseDate': vaccination.nextDoseDate?.toIso8601String(),
          'dose': vaccination.dose,
          'method': vaccination.method,
          'notes': vaccination.notes,
        },
        operation: 'update',
      );
    }
  }

  Future<void> markAsCompleted(String vaccinationId) async {
    try {
      if (_syncService.isOnline) {
        await _firestore.collection(_collection).doc(vaccinationId).update({
          'isCompleted': true,
          'completedAt': DateTime.now().toIso8601String(),
        });
      } else {
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: vaccinationId,
          data: {
            'isCompleted': true,
            'completedAt': DateTime.now().toIso8601String(),
          },
          operation: 'update',
        );
      }
    } catch (e) {
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: vaccinationId,
        data: {
          'isCompleted': true,
          'completedAt': DateTime.now().toIso8601String(),
        },
        operation: 'update',
      );
    }
  }

  Future<void> markAsIncomplete(String vaccinationId) async {
    try {
      if (_syncService.isOnline) {
        await _firestore.collection(_collection).doc(vaccinationId).update({
          'isCompleted': false,
          'completedAt': null,
        });
      } else {
        await _syncService.saveForLaterSync(
          collection: _collection,
          documentId: vaccinationId,
          data: {
            'isCompleted': false,
            'completedAt': null,
          },
          operation: 'update',
        );
      }
    } catch (e) {
      await _syncService.saveForLaterSync(
        collection: _collection,
        documentId: vaccinationId,
        data: {
          'isCompleted': false,
          'completedAt': null,
        },
        operation: 'update',
      );
    }
  }
}
