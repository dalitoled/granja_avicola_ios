import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/egg_production_model.dart';

class ProductionData {
  final DateTime date;
  final int totalEggs;

  ProductionData({required this.date, required this.totalEggs});
}

class PredictionResult {
  final double tomorrowPrediction;
  final double weeklyPrediction;
  final double monthlyPrediction;
  final double dailyAverage;
  final List<ProductionData> last7DaysData;
  final double trendPercentage;

  PredictionResult({
    required this.tomorrowPrediction,
    required this.weeklyPrediction,
    required this.monthlyPrediction,
    required this.dailyAverage,
    required this.last7DaysData,
    required this.trendPercentage,
  });
}

class PredictionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ProductionData>> getLast7DaysProduction(String userId) async {
    try {
      DateTime today = DateTime.now();
      DateTime sevenDaysAgo = today.subtract(const Duration(days: 7));

      QuerySnapshot snapshot = await _firestore
          .collection('produccion_diaria')
          .where('userId', isEqualTo: userId)
          .get();

      List<ProductionData> productions = [];

      for (var doc in snapshot.docs) {
        EggProductionModel production = EggProductionModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        if (production.date.isAfter(sevenDaysAgo) &&
            production.date.isBefore(today.add(const Duration(days: 1)))) {
          productions.add(
            ProductionData(
              date: production.date,
              totalEggs: production.totalHuevos,
            ),
          );
        }
      }

      productions.sort((a, b) => a.date.compareTo(b.date));

      return productions;
    } catch (e) {
      return [];
    }
  }

  double calculateDailyAverage(List<ProductionData> data) {
    if (data.isEmpty) return 0;
    int total = data.map((d) => d.totalEggs).reduce((a, b) => a + b);
    return total / data.length;
  }

  double predictTomorrowProduction(List<ProductionData> data) {
    return calculateDailyAverage(data);
  }

  double predictWeeklyProduction(List<ProductionData> data) {
    return calculateDailyAverage(data) * 7;
  }

  double predictMonthlyProduction(List<ProductionData> data) {
    return calculateDailyAverage(data) * 30;
  }

  double calculateTrend(List<ProductionData> data) {
    if (data.length < 2) return 0;

    int firstHalf = data
        .take(data.length ~/ 2)
        .map((d) => d.totalEggs)
        .reduce((a, b) => a + b);
    int secondHalf = data
        .skip(data.length ~/ 2)
        .map((d) => d.totalEggs)
        .reduce((a, b) => a + b);

    double firstAvg = firstHalf / (data.length ~/ 2);
    double secondAvg = secondHalf / (data.length - data.length ~/ 2);

    if (firstAvg == 0) return 0;

    return ((secondAvg - firstAvg) / firstAvg) * 100;
  }

  Future<PredictionResult> getProductionPrediction(String userId) async {
    List<ProductionData> last7Days = await getLast7DaysProduction(userId);

    double dailyAverage = calculateDailyAverage(last7Days);
    double tomorrow = predictTomorrowProduction(last7Days);
    double weekly = predictWeeklyProduction(last7Days);
    double monthly = predictMonthlyProduction(last7Days);
    double trend = calculateTrend(last7Days);

    return PredictionResult(
      tomorrowPrediction: tomorrow,
      weeklyPrediction: weekly,
      monthlyPrediction: monthly,
      dailyAverage: dailyAverage,
      last7DaysData: last7Days,
      trendPercentage: trend,
    );
  }

  Future<int> getTodayProduction(String userId) async {
    try {
      DateTime today = DateTime.now();

      QuerySnapshot snapshot = await _firestore
          .collection('produccion_diaria')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        EggProductionModel production = EggProductionModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        if (production.date.year == today.year &&
            production.date.month == today.month &&
            production.date.day == today.day) {
          return production.totalHuevos;
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  String getTrendDescription(double trend) {
    if (trend > 5) {
      return 'Tendiendo al alza';
    } else if (trend < -5) {
      return 'Tendiendo a la baja';
    } else {
      return 'Estable';
    }
  }

  String getTrendEmoji(double trend) {
    if (trend > 5) {
      return '📈';
    } else if (trend < -5) {
      return '📉';
    } else {
      return '➡️';
    }
  }
}
