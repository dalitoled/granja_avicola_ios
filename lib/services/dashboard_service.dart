import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feed_inventory_model.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getTodayProduction(String userId) async {
    try {
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      QuerySnapshot snapshot = await _firestore
          .collection('produccion_diaria')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalHuevos': 0,
          'extra': 0,
          'especial': 0,
          'primera': 0,
          'segunda': 0,
          'tercera': 0,
        };
      }

      Map<String, dynamic> data =
          snapshot.docs.first.data() as Map<String, dynamic>;
      return {
        'totalHuevos': data['totalHuevos'] ?? 0,
        'extra': data['extra'] ?? 0,
        'especial': data['especial'] ?? 0,
        'primera': data['primera'] ?? 0,
        'segunda': data['segunda'] ?? 0,
        'tercera': data['tercera'] ?? 0,
      };
    } catch (e) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('produccion_diaria')
            .where('userId', isEqualTo: userId)
            .get();

        DateTime today = DateTime.now();
        DateTime startOfDay = DateTime(today.year, today.month, today.day);

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          DateTime date = DateTime.parse(data['date']);
          if (date.year == startOfDay.year && 
              date.month == startOfDay.month && 
              date.day == startOfDay.day) {
            return {
              'totalHuevos': data['totalHuevos'] ?? 0,
              'extra': data['extra'] ?? 0,
              'especial': data['especial'] ?? 0,
              'primera': data['primera'] ?? 0,
              'segunda': data['segunda'] ?? 0,
              'tercera': data['tercera'] ?? 0,
            };
          }
        }

        return {
          'totalHuevos': 0,
          'extra': 0,
          'especial': 0,
          'primera': 0,
          'segunda': 0,
          'tercera': 0,
        };
      } catch (fallback) {
        return {
          'totalHuevos': 0,
          'extra': 0,
          'especial': 0,
          'primera': 0,
          'segunda': 0,
          'tercera': 0,
        };
      }
    }
  }

  Future<double> getTodayFeedConsumption(String userId) async {
    try {
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      QuerySnapshot snapshot = await _firestore
          .collection('consumo_alimento')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .get();

      if (snapshot.docs.isEmpty) return 0;

      double totalFeed = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalFeed += (data['feedKg'] ?? 0).toDouble();
      }
      return totalFeed;
    } catch (e) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('consumo_alimento')
            .where('userId', isEqualTo: userId)
            .get();

        DateTime today = DateTime.now();
        DateTime startOfDay = DateTime(today.year, today.month, today.day);

        double totalFeed = 0;
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          DateTime date = DateTime.parse(data['date']);
          if (date.year == startOfDay.year && 
              date.month == startOfDay.month && 
              date.day == startOfDay.day) {
            totalFeed += (data['feedKg'] ?? 0).toDouble();
          }
        }

        return totalFeed;
      } catch (fallback) {
        return 0;
      }
    }
  }

  Future<double> getFeedConversion(String userId) async {
    try {
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      QuerySnapshot productionSnapshot = await _firestore
          .collection('produccion_diaria')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .get();

      QuerySnapshot feedSnapshot = await _firestore
          .collection('consumo_alimento')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .get();

      int totalEggs = 0;
      double feedKg = 0;

      if (productionSnapshot.docs.isNotEmpty) {
        for (var doc in productionSnapshot.docs) {
          Map<String, dynamic> prodData = doc.data() as Map<String, dynamic>;
          totalEggs += (prodData['totalHuevos'] ?? 0) as int;
        }
      }

      if (feedSnapshot.docs.isNotEmpty) {
        for (var doc in feedSnapshot.docs) {
          Map<String, dynamic> feedData = doc.data() as Map<String, dynamic>;
          feedKg += (feedData['feedKg'] ?? 0).toDouble();
        }
      }

      if (totalEggs == 0) return 0;
      return feedKg / totalEggs;
    } catch (e) {
      try {
        QuerySnapshot productionSnapshot = await _firestore
            .collection('produccion_diaria')
            .where('userId', isEqualTo: userId)
            .get();

        QuerySnapshot feedSnapshot = await _firestore
            .collection('consumo_alimento')
            .where('userId', isEqualTo: userId)
            .get();

        DateTime today = DateTime.now();
        DateTime startOfDay = DateTime(today.year, today.month, today.day);

        int totalEggs = 0;
        double feedKg = 0;

        for (var doc in productionSnapshot.docs) {
          Map<String, dynamic> prodData = doc.data() as Map<String, dynamic>;
          DateTime date = DateTime.parse(prodData['date']);
          if (date.year == startOfDay.year && 
              date.month == startOfDay.month && 
              date.day == startOfDay.day) {
            totalEggs += (prodData['totalHuevos'] ?? 0) as int;
          }
        }

        for (var doc in feedSnapshot.docs) {
          Map<String, dynamic> feedData = doc.data() as Map<String, dynamic>;
          DateTime date = DateTime.parse(feedData['date']);
          if (date.year == startOfDay.year && 
              date.month == startOfDay.month && 
              date.day == startOfDay.day) {
            feedKg += (feedData['feedKg'] ?? 0).toDouble();
          }
        }

        if (totalEggs == 0) return 0;
        return feedKg / totalEggs;
      } catch (fallback) {
        return 0;
      }
    }
  }

  Future<Map<String, dynamic>> getFlockStatus(String userId) async {
    try {
      QuerySnapshot lotSnapshot = await _firestore
          .collection('lotes_gallinas')
          .where('userId', isEqualTo: userId)
          .get();

      int totalHens = 0;
      int totalLots = lotSnapshot.docs.length;

      for (var doc in lotSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int current = int.tryParse(data['currentHens']?.toString() ?? '0') ?? 0;
        if (current > 0) {
          totalHens += current;
        }
      }

      int totalDeaths = await getTodayMortality(userId);
      double mortalityRate = totalHens > 0
          ? (totalDeaths / totalHens) * 100
          : 0;

      return {
        'totalHens': totalHens,
        'totalLots': totalLots,
        'todayDeaths': totalDeaths,
        'mortalityRate': mortalityRate,
      };
    } catch (e) {
      try {
        QuerySnapshot lotSnapshot = await _firestore
            .collection('lotes_gallinas')
            .where('userId', isEqualTo: userId)
            .get();

        int totalHens = 0;
        int totalLots = lotSnapshot.docs.length;

        for (var doc in lotSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          int current = int.tryParse(data['currentHens']?.toString() ?? '0') ?? 0;
          if (current > 0) {
            totalHens += current;
          }
        }

        return {
          'totalHens': totalHens,
          'totalLots': totalLots,
          'todayDeaths': 0,
          'mortalityRate': 0,
        };
      } catch (fallback) {
        return {
          'totalHens': 0,
          'totalLots': 0,
          'todayDeaths': 0,
          'mortalityRate': 0,
        };
      }
    }
  }

  Future<int> getTodayMortality(String userId) async {
    try {
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      QuerySnapshot snapshot = await _firestore
          .collection('mortalidad_gallinas')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .get();

      int totalDeaths = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalDeaths += (data['deadHens'] ?? 0) as int;
      }

      return totalDeaths;
    } catch (e) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('mortalidad_gallinas')
            .where('userId', isEqualTo: userId)
            .get();

        DateTime today = DateTime.now();
        DateTime startOfDay = DateTime(today.year, today.month, today.day);

        int totalDeaths = 0;
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data['date'] != null) {
            DateTime date = DateTime.parse(data['date']);
            if (date.year == startOfDay.year && 
                date.month == startOfDay.month && 
                date.day == startOfDay.day) {
              totalDeaths += int.tryParse(data['deadHens']?.toString() ?? '0') ?? 0;
            }
          }
        }

        return totalDeaths;
      } catch (fallback) {
        return 0;
      }
    }
  }

  Future<double> getTodayIncome(String userId) async {
    try {
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      QuerySnapshot snapshot = await _firestore
          .collection('ventas_huevos')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .get();

      double totalIncome = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalIncome += (data['totalSale'] ?? data['total'] ?? 0).toDouble();
      }

      return totalIncome;
    } catch (e) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('ventas_huevos')
            .where('userId', isEqualTo: userId)
            .get();

        DateTime today = DateTime.now();
        DateTime startOfDay = DateTime(today.year, today.month, today.day);

        double totalIncome = 0;
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          DateTime date = DateTime.parse(data['date']);
          if (date.year == startOfDay.year && 
              date.month == startOfDay.month && 
              date.day == startOfDay.day) {
            totalIncome += (data['totalSale'] ?? data['total'] ?? 0).toDouble();
          }
        }

        return totalIncome;
      } catch (fallback) {
        return 0;
      }
    }
  }

  Future<double> getTodayExpenses(String userId) async {
    try {
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      QuerySnapshot snapshot = await _firestore
          .collection('gastos_granja')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .get();

      double totalExpenses = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalExpenses += (data['amount'] ?? 0).toDouble();
      }

      return totalExpenses;
    } catch (e) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('gastos_granja')
            .where('userId', isEqualTo: userId)
            .get();

        DateTime today = DateTime.now();
        DateTime startOfDay = DateTime(today.year, today.month, today.day);

        double totalExpenses = 0;
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          DateTime date = DateTime.parse(data['date']);
          if (date.year == startOfDay.year && 
              date.month == startOfDay.month && 
              date.day == startOfDay.day) {
            totalExpenses += (data['amount'] ?? 0).toDouble();
          }
        }

        return totalExpenses;
      } catch (fallback) {
        return 0;
      }
    }
  }

  Future<double> getTodayProfit(String userId) async {
    double income = await getTodayIncome(userId);
    double expenses = await getTodayExpenses(userId);
    double feedCosts = await getTodayFeedCost(userId);
    return income - (expenses + feedCosts);
  }

  Future<double> getTodayFeedCost(String userId) async {
    try {
      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      QuerySnapshot snapshot = await _firestore
          .collection('consumo_alimento')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .get();

      double totalCost = 0;
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalCost += (data['feedCost'] ?? 0).toDouble();
      }

      return totalCost;
    } catch (e) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('consumo_alimento')
            .where('userId', isEqualTo: userId)
            .get();

        DateTime today = DateTime.now();
        DateTime startOfDay = DateTime(today.year, today.month, today.day);

        double totalCost = 0;
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          DateTime date = DateTime.parse(data['date']);
          if (date.year == startOfDay.year && 
              date.month == startOfDay.month && 
              date.day == startOfDay.day) {
            totalCost += (data['feedCost'] ?? 0).toDouble();
          }
        }

        return totalCost;
      } catch (fallback) {
        return 0;
      }
    }
  }

  Future<List<FeedInventoryModel>> getFeedInventory(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('inventario_alimento')
          .where('userId', isEqualTo: userId)
          .get();

      List<FeedInventoryModel> inventory = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return FeedInventoryModel.fromMap(data);
      }).toList();

      return inventory;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingVaccinations(
    String userId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('plan_vacunacion')
          .where('userId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> upcoming = [];
      DateTime now = DateTime.now();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data['nextDoseDate'] != null) {
          DateTime nextDose = DateTime.parse(data['nextDoseDate']);
          int daysUntil = nextDose.difference(now).inDays;

          if (daysUntil >= 0 && daysUntil <= 7) {
            upcoming.add({
              'vaccineName': data['vaccineName'],
              'lotNumber': data['lotNumber'],
              'nextDoseDate': nextDose,
              'daysUntil': daysUntil,
            });
          }
        }
      }

      upcoming.sort(
        (a, b) => (a['daysUntil'] as int).compareTo(b['daysUntil'] as int),
      );
      return upcoming;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getDashboardData(String userId) async {
    final results = await Future.wait([
      getTodayProduction(userId),
      getTodayFeedConsumption(userId),
      getFeedConversion(userId),
      getFlockStatus(userId),
      getTodayIncome(userId),
      getTodayExpenses(userId),
      getTodayProfit(userId),
      getFeedInventory(userId),
      getUpcomingVaccinations(userId),
      getTodayFeedCost(userId),
    ]);

    return {
      'production': results[0],
      'feedConsumption': results[1],
      'feedConversion': results[2],
      'flockStatus': results[3],
      'income': results[4],
      'expenses': results[5],
      'profit': results[6],
      'feedInventory': results[7],
      'upcomingVaccinations': results[8],
      'feedCost': results[9],
    };
  }
}
