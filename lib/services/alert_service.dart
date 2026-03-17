import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert_model.dart';
import '../models/egg_production_model.dart';
import '../models/hen_mortality_model.dart';
import '../models/feed_inventory_model.dart';
import '../models/vaccination_model.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const double PRODUCTION_THRESHOLD = 0.85;
  static const int MORTALITY_DEFAULT_THRESHOLD = 5;
  static const int VACCINE_DAYS_WARNING = 3;

  Future<List<AlertModel>> getAllAlerts(String userId) async {
    List<AlertModel> alerts = [];

    alerts.addAll(await checkLowProduction(userId));
    alerts.addAll(await checkHighMortality(userId));
    alerts.addAll(await checkLowFeedStock(userId));
    alerts.addAll(await checkUpcomingVaccines(userId));

    alerts.sort((a, b) {
      if (a.severity == AlertSeverity.critical &&
          b.severity != AlertSeverity.critical) {
        return -1;
      }
      if (b.severity == AlertSeverity.critical &&
          a.severity != AlertSeverity.critical) {
        return 1;
      }
      if (a.severity == AlertSeverity.warning &&
          b.severity == AlertSeverity.normal) {
        return -1;
      }
      if (b.severity == AlertSeverity.warning &&
          a.severity == AlertSeverity.normal) {
        return 1;
      }
      return b.date.compareTo(a.date);
    });

    return alerts;
  }

  Future<AlertSeverity> getOverallStatus(String userId) async {
    final alerts = await getAllAlerts(userId);

    if (alerts.isEmpty) return AlertSeverity.normal;
    if (alerts.any((a) => a.severity == AlertSeverity.critical)) {
      return AlertSeverity.critical;
    }
    if (alerts.any((a) => a.severity == AlertSeverity.warning)) {
      return AlertSeverity.warning;
    }
    return AlertSeverity.normal;
  }

  Future<int> getAlertCount(String userId) async {
    final alerts = await getAllAlerts(userId);
    return alerts.where((a) => a.severity != AlertSeverity.normal).length;
  }

  Future<List<AlertModel>> checkLowProduction(String userId) async {
    List<AlertModel> alerts = [];

    try {
      DateTime today = DateTime.now();
      DateTime weekAgo = today.subtract(const Duration(days: 7));

      QuerySnapshot snapshot = await _firestore
          .collection('produccion_diaria')
          .where('userId', isEqualTo: userId)
          .get();

      List<EggProductionModel> productions = [];
      for (var doc in snapshot.docs) {
        productions.add(
          EggProductionModel.fromMap(doc.data() as Map<String, dynamic>),
        );
      }

      productions.sort((a, b) => b.date.compareTo(a.date));

      EggProductionModel? todayProduction;
      List<EggProductionModel> weekProductions = [];

      for (var p in productions) {
        if (p.date.year == today.year &&
            p.date.month == today.month &&
            p.date.day == today.day) {
          todayProduction = p;
        }
        if (p.date.isAfter(weekAgo) && p.date.isBefore(today)) {
          weekProductions.add(p);
        }
      }

      if (todayProduction != null && weekProductions.isNotEmpty) {
        double weeklyAverage =
            weekProductions.map((p) => p.totalHuevos).reduce((a, b) => a + b) /
            weekProductions.length;
        double productionRatio = todayProduction.totalHuevos / weeklyAverage;

        if (productionRatio < PRODUCTION_THRESHOLD) {
          alerts.add(
            AlertModel.lowProduction(
              todayProduction: todayProduction.totalHuevos,
              weeklyAverage: weeklyAverage,
            ),
          );
        }
      }
    } catch (e) {
      // Handle error silently
    }

    return alerts;
  }

  Future<List<AlertModel>> checkHighMortality(String userId) async {
    List<AlertModel> alerts = [];

    try {
      DateTime today = DateTime.now();
      DateTime threeDaysAgo = today.subtract(const Duration(days: 3));

      QuerySnapshot snapshot = await _firestore
          .collection('mortalidad_gallinas')
          .where('userId', isEqualTo: userId)
          .get();

      List<HenMortalityModel> mortalities = [];
      for (var doc in snapshot.docs) {
        HenMortalityModel m = HenMortalityModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );
        if (m.date.isAfter(threeDaysAgo) &&
            m.date.isBefore(today.add(const Duration(days: 1)))) {
          mortalities.add(m);
        }
      }

      int totalDeaths = mortalities
          .map((m) => m.deadHens)
          .reduce((a, b) => a + b);

      QuerySnapshot lotsSnapshot = await _firestore
          .collection('lotes')
          .where('userId', isEqualTo: userId)
          .get();

      int totalHens = 0;
      for (var doc in lotsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final currentCount = data['currentCount'] ?? data[' hens'] ?? 0;
        totalHens += (currentCount is int
            ? currentCount
            : int.tryParse(currentCount.toString()) ?? 0);
      }

      int threshold = MORTALITY_DEFAULT_THRESHOLD;
      if (totalHens > 0) {
        threshold = (totalHens * 0.01).ceil().clamp(3, 10);
      }

      if (totalDeaths > threshold) {
        alerts.add(
          AlertModel.highMortality(deaths: totalDeaths, threshold: threshold),
        );
      }
    } catch (e) {
      // Handle error silently
    }

    return alerts;
  }

  Future<List<AlertModel>> checkLowFeedStock(String userId) async {
    List<AlertModel> alerts = [];

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('inventario_alimento')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        FeedInventoryModel inventory = FeedInventoryModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        if (inventory.stockKg <= inventory.minimumStock) {
          alerts.add(
            AlertModel.lowFeedStock(
              currentStock: inventory.stockKg,
              minimumStock: inventory.minimumStock,
            ),
          );
        }
      }
    } catch (e) {
      // Handle error silently
    }

    return alerts;
  }

  Future<List<AlertModel>> checkUpcomingVaccines(String userId) async {
    List<AlertModel> alerts = [];

    try {
      DateTime today = DateTime.now();

      QuerySnapshot snapshot = await _firestore
          .collection('plan_vacunacion')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        try {
          VaccinationModel vaccine = VaccinationModel.fromMap(
            doc.data() as Map<String, dynamic>,
          );

          if (vaccine.nextDoseDate != null) {
            DateTime nextDate = vaccine.nextDoseDate!;
            int daysUntil = nextDate.difference(today).inDays;

            if (daysUntil >= 0 && daysUntil <= VACCINE_DAYS_WARNING) {
              alerts.add(
                AlertModel.upcomingVaccine(
                  vaccineName: vaccine.vaccineName,
                  nextDate: nextDate,
                  daysUntil: daysUntil,
                ),
              );
            } else if (daysUntil < 0) {
              alerts.add(
                AlertModel.upcomingVaccine(
                  vaccineName: '${vaccine.vaccineName} (ATRASADA)',
                  nextDate: nextDate,
                  daysUntil: daysUntil,
                ),
              );
            }
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      // Handle error silently
    }

    return alerts;
  }
}
