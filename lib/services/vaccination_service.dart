import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vaccination_model.dart';

class VaccinationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> addVaccination(VaccinationModel vaccination) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('plan_vacunacion')
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
    } catch (e) {
      throw 'Error al guardar la vacunación: $e';
    }
  }

  Future<List<VaccinationModel>> getVaccinationsByUser(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('plan_vacunacion')
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
      throw 'Error al obtener las vaccinations: $e';
    }
  }

  Future<List<VaccinationModel>> getVaccinationsByLot(String lotId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('plan_vacunacion')
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
      throw 'Error al obtener las vaccinations: $e';
    }
  }

  Future<List<VaccinationModel>> getUpcomingVaccinations(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('plan_vacunacion')
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
          .collection('plan_vacunacion')
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
      await _firestore.collection('plan_vacunacion').doc(vaccinationId).delete();
    } catch (e) {
      throw 'Error al eliminar vacunación: $e';
    }
  }

  Future<void> updateVaccination(VaccinationModel vaccination) async {
    try {
      await _firestore.collection('plan_vacunacion').doc(vaccination.id).update({
        'lotId': vaccination.lotId,
        'lotNumber': vaccination.lotNumber,
        'vaccineName': vaccination.vaccineName,
        'applicationDate': vaccination.applicationDate.toIso8601String(),
        'nextDoseDate': vaccination.nextDoseDate?.toIso8601String(),
        'dose': vaccination.dose,
        'method': vaccination.method,
        'notes': vaccination.notes,
      });
    } catch (e) {
      throw 'Error al actualizar vacunación: $e';
    }
  }
}
