import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FarmSimulationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  static const int SIMULATION_DAYS = 7;
  static const int INITIAL_HENS = 1000;
  static const double MIN_PRODUCTION_RATE = 0.85;
  static const double MAX_PRODUCTION_RATE = 0.92;

  static const double MIN_FEED_CONSUMPTION = 110;
  static const double MAX_FEED_CONSUMPTION = 130;
  static const double MIN_FEED_PRICE = 3.10;
  static const double MAX_FEED_PRICE = 3.40;

  static const double MIN_EGGS_SOLD = 750;
  static const double MAX_EGGS_SOLD = 900;
  static const double MIN_EGG_PRICE = 0.75;
  static const double MAX_EGG_PRICE = 1.00;

  static const double MORTALITY_PROBABILITY = 0.25;
  static const int MORTALITY_MIN = 1;
  static const int MORTALITY_MAX = 2;

  static const double EXPENSE_PROBABILITY = 0.15;
  static const double MIN_EXPENSE = 50;
  static const double MAX_EXPENSE = 400;

  static const double INITIAL_FEED_STOCK = 2000;
  static const double FEED_PURCHASE_AMOUNT = 2000;
  static const int FEED_PURCHASE_INTERVAL = 15;

  String? _userId;
  int _currentHens = INITIAL_HENS;
  double _currentFeedStock = INITIAL_FEED_STOCK;
  double _currentFeedPrice = 3.20;

  Future<void> generateFarmSimulation(String userId) async {
    _userId = userId;
    _currentHens = INITIAL_HENS;
    _currentFeedStock = INITIAL_FEED_STOCK;
    _currentFeedPrice = 3.20;

    DateTime today = DateTime.now();

    for (int dayOffset = SIMULATION_DAYS - 1; dayOffset >= 0; dayOffset--) {
      DateTime simulationDate = today.subtract(Duration(days: dayOffset));
      int dayNumber = SIMULATION_DAYS - dayOffset;

      await _generateDailyProduction(simulationDate, dayNumber);
      await _generateFeedConsumption(simulationDate);
      await _generateEggSales(simulationDate, dayNumber);
      await _generateMortality(simulationDate, dayNumber);
      await _generateExpenses(simulationDate, dayNumber);
      await _updateFeedInventory(simulationDate, dayNumber);
      await _generateVaccinations(simulationDate, dayNumber);

      _handleSpecialEvents(dayNumber);

      if (dayOffset % 10 == 0) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    await _setInitialInventory();
  }

  void _handleSpecialEvents(int dayNumber) {
    switch (dayNumber) {
      case 25:
        break;
      case 40:
        break;
      case 55:
        _currentFeedPrice = 3.50;
        break;
      case 70:
        break;
      case 85:
        break;
    }
  }

  int _getDailyProductionTarget(int dayNumber) {
    int baseProduction =
        (_currentHens * (MIN_PRODUCTION_RATE + MAX_PRODUCTION_RATE) / 2)
            .round();

    if (dayNumber == 25) {
      baseProduction = 820;
    } else if (dayNumber == 70) {
      baseProduction = 920;
    }

    int variation = _random.nextInt(31) - 15;
    return (baseProduction + variation).clamp(850, 920);
  }

  Map<String, int> _distributeEggs(int totalEggs) {
    return {
      'extra': (totalEggs * 0.12).round(),
      'especial': (totalEggs * 0.25).round(),
      'primera': (totalEggs * 0.30).round(),
      'segunda': (totalEggs * 0.18).round(),
      'tercera': (totalEggs * 0.08).round(),
      'cuarta': (totalEggs * 0.04).round(),
      'quinta': (totalEggs * 0.02).round(),
      'sucios': (totalEggs * 0.007).round(),
      'rajados': (totalEggs * 0.002).round(),
      'descarte': (totalEggs * 0.001).round(),
    };
  }

  Future<void> _generateDailyProduction(DateTime date, int dayNumber) async {
    int totalEggs = _getDailyProductionTarget(dayNumber);
    Map<String, int> distribution = _distributeEggs(totalEggs);

    await _firestore.collection('produccion_diaria').add({
      'userId': _userId,
      'date': date.toIso8601String(),
      'extra': distribution['extra'],
      'especial': distribution['especial'],
      'primera': distribution['primera'],
      'segunda': distribution['segunda'],
      'tercera': distribution['tercera'],
      'cuarta': distribution['cuarta'],
      'quinta': distribution['quinta'],
      'sucios': distribution['sucios'],
      'rajados': distribution['rajados'],
      'descarte': distribution['descarte'],
      'totalHuevos': totalEggs,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _generateFeedConsumption(DateTime date) async {
    double feedKg =
        MIN_FEED_CONSUMPTION +
        _random.nextDouble() * (MAX_FEED_CONSUMPTION - MIN_FEED_CONSUMPTION);
    feedKg = feedKg + (_random.nextDouble() * 4 - 2);

    double pricePerKg = _currentFeedPrice + (_random.nextDouble() * 0.1 - 0.05);
    double feedCost = feedKg * pricePerKg;

    _currentFeedStock -= feedKg;

    await _firestore.collection('consumo_alimento').add({
      'userId': _userId,
      'date': date.toIso8601String(),
      'feedKg': double.parse(feedKg.toStringAsFixed(2)),
      'pricePerKg': double.parse(pricePerKg.toStringAsFixed(2)),
      'feedCost': double.parse(feedCost.toStringAsFixed(2)),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _generateEggSales(DateTime date, int dayNumber) async {
    int eggsSold =
        (MIN_EGGS_SOLD + _random.nextDouble() * (MAX_EGGS_SOLD - MIN_EGGS_SOLD))
            .round();

    if (dayNumber == 25) {
      eggsSold = 700;
    } else if (dayNumber == 70) {
      eggsSold = 880;
    }

    double avgPrice =
        MIN_EGG_PRICE + _random.nextDouble() * (MAX_EGG_PRICE - MIN_EGG_PRICE);
    double totalIncome = eggsSold * avgPrice;

    await _firestore.collection('ventas_huevos').add({
      'userId': _userId,
      'date': date.toIso8601String(),
      'eggsSold': eggsSold,
      'pricePerEgg': double.parse(avgPrice.toStringAsFixed(2)),
      'totalIncome': double.parse(totalIncome.toStringAsFixed(2)),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _generateMortality(DateTime date, int dayNumber) async {
    if (_random.nextDouble() > MORTALITY_PROBABILITY) return;

    if (dayNumber % 3 != 0 && dayNumber % 4 != 0 && dayNumber % 5 != 0) return;

    int deadHens =
        MORTALITY_MIN + _random.nextInt(MORTALITY_MAX - MORTALITY_MIN + 1);
    deadHens = deadHens.clamp(1, _currentHens ~/ 10);

    _currentHens -= deadHens;

    List<String> causes = ['Disease', 'Accident', 'Unknown', 'Stress'];
    String cause = causes[_random.nextInt(causes.length)];

    await _firestore.collection('mortalidad_gallinas').add({
      'userId': _userId,
      'lotId': 'lot_1',
      'lotNumber': 'Lote 1',
      'date': date.toIso8601String(),
      'deadHens': deadHens,
      'cause': cause,
      'notes': '',
      'createdAt': DateTime.now().toIso8601String(),
    });

    await _firestore.collection('lotes').doc('lot_1').set({
      'userId': _userId,
      'lotNumber': 'Lote 1',
      'initialCount': INITIAL_HENS,
      'currentCount': _currentHens,
      'startDate': DateTime.now()
          .subtract(const Duration(days: 120))
          .toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> _generateExpenses(DateTime date, int dayNumber) async {
    if (_random.nextDouble() > EXPENSE_PROBABILITY) return;

    List<Map<String, dynamic>> expenseCategories = [
      {'category': 'Electricity', 'min': 80, 'max': 200},
      {'category': 'Medicine', 'min': 50, 'max': 300},
      {'category': 'Maintenance', 'min': 100, 'max': 400},
      {'category': 'Transport', 'min': 50, 'max': 250},
    ];

    Map<String, dynamic> category =
        expenseCategories[_random.nextInt(expenseCategories.length)];
    double amount =
        category['min'] +
        _random.nextDouble() * (category['max'] - category['min']);

    String description = _getExpenseDescription(category['category']);

    await _firestore.collection('gastos_granja').add({
      'userId': _userId,
      'date': date.toIso8601String(),
      'category': category['category'],
      'description': description,
      'amount': double.parse(amount.toStringAsFixed(2)),
      'paymentMethod': 'Cash',
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  String _getExpenseDescription(String category) {
    switch (category) {
      case 'Electricity':
        return 'Electricidad del mes';
      case 'Medicine':
        List<String> meds = [
          'Vitaminas',
          'Antibióticos',
          'Desparasitante',
          'Vacunas',
        ];
        return meds[_random.nextInt(meds.length)];
      case 'Maintenance':
        List<String> maint = [
          'Limpieza de gallinero',
          'Reparación de bebederos',
          'Mantenimiento general',
        ];
        return maint[_random.nextInt(maint.length)];
      case 'Transport':
        return 'Transporte de huevos';
      default:
        return 'Gasto operativo';
    }
  }

  Future<void> _updateFeedInventory(DateTime date, int dayNumber) async {
    if (dayNumber % FEED_PURCHASE_INTERVAL == 0) {
      _currentFeedStock += FEED_PURCHASE_AMOUNT;

      await _firestore.collection('inventario_alimento').add({
        'userId': _userId,
        'feedType': 'Concentrado',
        'stockKg': double.parse(_currentFeedStock.toStringAsFixed(2)),
        'movementType': 'purchase',
        'quantity': FEED_PURCHASE_AMOUNT,
        'date': date.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    if (_currentFeedStock < 500) {
      _currentFeedStock += FEED_PURCHASE_AMOUNT;
      await _firestore.collection('inventario_alimento').add({
        'userId': _userId,
        'feedType': 'Concentrado',
        'stockKg': double.parse(_currentFeedStock.toStringAsFixed(2)),
        'movementType': 'purchase',
        'quantity': FEED_PURCHASE_AMOUNT,
        'date': date.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _generateVaccinations(DateTime date, int dayNumber) async {
    Map<int, Map<String, String>> vaccinationSchedule = {
      15: {'name': 'Newcastle', 'dose': '1ra'},
      30: {'name': 'Infectious Bronchitis', 'dose': '1ra'},
      60: {'name': 'Newcastle', 'dose': 'Refuerzo'},
    };

    if (vaccinationSchedule.containsKey(dayNumber)) {
      Map<String, String> vaccine = vaccinationSchedule[dayNumber]!;
      DateTime nextDoseDate = date.add(const Duration(days: 30));

      await _firestore.collection('plan_vacunacion').add({
        'userId': _userId,
        'lotId': 'lot_1',
        'lotNumber': 'Lote 1',
        'vaccineName': vaccine['name'],
        'applicationDate': date.toIso8601String(),
        'nextDoseDate': nextDoseDate.toIso8601String(),
        'dose': vaccine['dose'],
        'method': 'Agua',
        'notes': '',
        'status': 'completed',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _setInitialInventory() async {
    await _firestore.collection('inventario_alimento').add({
      'userId': _userId,
      'feedType': 'Concentrado',
      'stockKg': double.parse(_currentFeedStock.toStringAsFixed(2)),
      'minimumStock': 500,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> createInitialLot() async {
    await _firestore.collection('lotes').doc('lot_1').set({
      'userId': _userId,
      'lotNumber': 'Lote 1',
      'initialCount': INITIAL_HENS,
      'currentCount': _currentHens,
      'breed': 'Lohmann',
      'startDate': DateTime.now()
          .subtract(const Duration(days: 120))
          .toIso8601String(),
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> checkSimulationExists(String userId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('produccion_diaria')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<int> getSimulationDataCount(String userId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('produccion_diaria')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.length;
  }
}
