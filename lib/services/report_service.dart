import 'package:cloud_firestore/cloud_firestore.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getDailyProduction(
    String userId,
    int days,
  ) async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(days: days));

      QuerySnapshot snapshot = await _firestore
          .collection('produccion_diaria')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .orderBy('date', descending: false)
          .get();

      List<Map<String, dynamic>> results = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        results.add({
          'date': DateTime.parse(data['date']),
          'totalHuevos': data['totalHuevos'] ?? 0,
          'extra': data['extra'] ?? 0,
          'especial': data['especial'] ?? 0,
          'primera': data['primera'] ?? 0,
          'segunda': data['segunda'] ?? 0,
          'tercera': data['tercera'] ?? 0,
          'cuarta': data['cuarta'] ?? 0,
          'quinta': data['quinta'] ?? 0,
          'sucios': data['sucios'] ?? 0,
          'rajados': data['rajados'] ?? 0,
          'descarte': data['descarte'] ?? 0,
        });
      }

      return results;
    } catch (e) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('produccion_diaria')
            .where('userId', isEqualTo: userId)
            .get();

        List<Map<String, dynamic>> results = [];
        DateTime startDate = DateTime.now().subtract(Duration(days: days));
        
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          DateTime date = DateTime.parse(data['date']);
          if (date.isBefore(startDate)) continue;
          
          results.add({
            'date': date,
            'totalHuevos': data['totalHuevos'] ?? 0,
            'extra': data['extra'] ?? 0,
            'especial': data['especial'] ?? 0,
            'primera': data['primera'] ?? 0,
            'segunda': data['segunda'] ?? 0,
            'tercera': data['tercera'] ?? 0,
            'cuarta': data['cuarta'] ?? 0,
            'quinta': data['quinta'] ?? 0,
            'sucios': data['sucios'] ?? 0,
            'rajados': data['rajados'] ?? 0,
            'descarte': data['descarte'] ?? 0,
          });
        }
        
        results.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        return results;
      } catch (fallback) {
        return [];
      }
    }
  }

  Future<List<Map<String, dynamic>>> getWeeklyProduction(
    String userId,
    int weeks,
  ) async {
    try {
      List<Map<String, dynamic>> dailyData = await getDailyProduction(
        userId,
        weeks * 7,
      );

      Map<String, Map<String, dynamic>> weeklyMap = {};
      for (var data in dailyData) {
        DateTime date = data['date'] as DateTime;
        int weekNumber = _getWeekNumber(date);
        int year = date.year;
        String key = '$year-$weekNumber';

        if (!weeklyMap.containsKey(key)) {
          weeklyMap[key] = {
            'week': weekNumber,
            'year': year,
            'totalHuevos': 0,
            'days': 0,
          };
        }

        weeklyMap[key]!['totalHuevos'] =
            (weeklyMap[key]!['totalHuevos'] as int) +
            (data['totalHuevos'] as int);
        weeklyMap[key]!['days'] = (weeklyMap[key]!['days'] as int) + 1;
      }

      return weeklyMap.values.toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyProduction(
    String userId,
    int months,
  ) async {
    try {
      List<Map<String, dynamic>> dailyData = await getDailyProduction(
        userId,
        months * 30,
      );

      Map<String, Map<String, dynamic>> monthlyMap = {};
      for (var data in dailyData) {
        DateTime date = data['date'] as DateTime;
        String key = '${date.year}-${date.month}';

        if (!monthlyMap.containsKey(key)) {
          monthlyMap[key] = {
            'month': date.month,
            'year': date.year,
            'totalHuevos': 0,
            'days': 0,
          };
        }

        monthlyMap[key]!['totalHuevos'] += data['totalHuevos'] as int;
        monthlyMap[key]!['days'] += 1;
      }

      return monthlyMap.values.toList();
    } catch (e) {
      return [];
    }
  }

  int _getWeekNumber(DateTime date) {
    int dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  Future<List<Map<String, dynamic>>> getFeedConsumptionReport(
    String userId,
    int days,
  ) async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(days: days));

      QuerySnapshot snapshot = await _firestore
          .collection('consumo_alimento')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .orderBy('date', descending: false)
          .get();

      List<Map<String, dynamic>> results = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        results.add({
          'date': DateTime.parse(data['date']),
          'feedKg': (data['feedKg'] ?? 0).toDouble(),
          'feedType': data['feedType'] ?? '',
          'feedCost': (data['feedCost'] ?? 0).toDouble(),
        });
      }

      return results;
    } catch (e) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('consumo_alimento')
            .where('userId', isEqualTo: userId)
            .get();

        List<Map<String, dynamic>> results = [];
        DateTime startDate = DateTime.now().subtract(Duration(days: days));
        
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          DateTime date = DateTime.parse(data['date']);
          if (date.isBefore(startDate)) continue;
          
          results.add({
            'date': date,
            'feedKg': (data['feedKg'] ?? 0).toDouble(),
            'feedType': data['feedType'] ?? '',
            'feedCost': (data['feedCost'] ?? 0).toDouble(),
          });
        }
        
        results.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        return results;
      } catch (fallback) {
        return [];
      }
    }
  }

  Future<Map<String, dynamic>> getFinancialReport(
    String userId,
    int days,
  ) async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(days: days));

      QuerySnapshot salesSnapshot = await _firestore
          .collection('ventas_huevos')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .get();

      QuerySnapshot expenseSnapshot = await _firestore
          .collection('gastos_granja')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .get();

      QuerySnapshot feedSnapshot = await _firestore
          .collection('consumo_alimento')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .get();

      double totalIncome = 0;
      double totalExpenses = 0;
      double feedCosts = 0;
      Map<String, double> incomeByDay = {};
      Map<String, double> expensesByDay = {};

      for (var doc in salesSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double amount = (data['totalSale'] ?? data['total'] ?? 0).toDouble();
        totalIncome += amount;

        DateTime date = DateTime.parse(data['date']);
        String key = '${date.year}-${date.month}-${date.day}';
        incomeByDay[key] = (incomeByDay[key] ?? 0) + amount;
      }

      for (var doc in expenseSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double amount = (data['amount'] ?? 0).toDouble();
        totalExpenses += amount;

        DateTime date = DateTime.parse(data['date']);
        String key = '${date.year}-${date.month}-${date.day}';
        expensesByDay[key] = (expensesByDay[key] ?? 0) + amount;
      }

      for (var doc in feedSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double feedCost = (data['feedCost'] ?? 0).toDouble();
        feedCosts += feedCost;
        totalExpenses += feedCost;

        DateTime date = DateTime.parse(data['date']);
        String key = '${date.year}-${date.month}-${date.day}';
        expensesByDay[key] = (expensesByDay[key] ?? 0) + feedCost;
      }

      return {
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'feedCosts': feedCosts,
        'profit': totalIncome - totalExpenses,
        'incomeByDay': incomeByDay,
        'expensesByDay': expensesByDay,
        'salesCount': salesSnapshot.docs.length,
        'expensesCount': expenseSnapshot.docs.length + feedSnapshot.docs.length,
      };
    } catch (e) {
      try {
        QuerySnapshot salesSnapshot = await _firestore
            .collection('ventas_huevos')
            .where('userId', isEqualTo: userId)
            .get();

        QuerySnapshot expenseSnapshot = await _firestore
            .collection('gastos_granja')
            .where('userId', isEqualTo: userId)
            .get();

        QuerySnapshot feedSnapshot = await _firestore
            .collection('consumo_alimento')
            .where('userId', isEqualTo: userId)
            .get();

        double totalIncome = 0;
        double totalExpenses = 0;
        double feedCosts = 0;
        Map<String, double> incomeByDay = {};
        Map<String, double> expensesByDay = {};
        DateTime startDate = DateTime.now().subtract(Duration(days: days));

        for (var doc in salesSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          DateTime date = DateTime.parse(data['date']);
          if (date.isBefore(startDate)) continue;
          
          double amount = (data['totalSale'] ?? data['total'] ?? 0).toDouble();
          totalIncome += amount;

          String key = '${date.year}-${date.month}-${date.day}';
          incomeByDay[key] = (incomeByDay[key] ?? 0) + amount;
        }

        for (var doc in expenseSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          DateTime date = DateTime.parse(data['date']);
          if (date.isBefore(startDate)) continue;
          
          double amount = (data['amount'] ?? 0).toDouble();
          totalExpenses += amount;

          String key = '${date.year}-${date.month}-${date.day}';
          expensesByDay[key] = (expensesByDay[key] ?? 0) + amount;
        }

        for (var doc in feedSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          DateTime date = DateTime.parse(data['date']);
          if (date.isBefore(startDate)) continue;
          
          double feedCost = (data['feedCost'] ?? 0).toDouble();
          feedCosts += feedCost;
          totalExpenses += feedCost;

          String key = '${date.year}-${date.month}-${date.day}';
          expensesByDay[key] = (expensesByDay[key] ?? 0) + feedCost;
        }

        return {
          'totalIncome': totalIncome,
          'totalExpenses': totalExpenses,
          'feedCosts': feedCosts,
          'profit': totalIncome - totalExpenses,
          'incomeByDay': incomeByDay,
          'expensesByDay': expensesByDay,
          'salesCount': salesSnapshot.docs.length,
          'expensesCount': expenseSnapshot.docs.length + feedSnapshot.docs.length,
        };
      } catch (fallbackError) {
        return {
          'totalIncome': 0.0,
          'totalExpenses': 0.0,
          'feedCosts': 0.0,
          'profit': 0.0,
          'incomeByDay': <String, double>{},
          'expensesByDay': <String, double>{},
          'salesCount': 0,
          'expensesCount': 0,
        };
      }
    }
  }

  Future<Map<String, dynamic>> getMortalityReport(
    String userId,
    int days,
  ) async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(days: days));

      QuerySnapshot snapshot = await _firestore
          .collection('mortalidad_gallinas')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .orderBy('date', descending: false)
          .get();

      int totalDeaths = 0;
      Map<String, int> deathsByDay = {};
      Map<String, int> deathsByWeek = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int deaths = int.tryParse(data['deadHens']?.toString() ?? '0') ?? 0;
        totalDeaths += deaths;

        DateTime date = DateTime.parse(data['date']);
        String dayKey = '${date.year}-${date.month}-${date.day}';
        deathsByDay[dayKey] = (deathsByDay[dayKey] ?? 0) + deaths;

        int weekNum = _getWeekNumber(date);
        String weekKey = '${date.year}-W$weekNum';
        deathsByWeek[weekKey] = (deathsByWeek[weekKey] ?? 0) + deaths;
      }

      QuerySnapshot lotSnapshot = await _firestore
          .collection('lotes_gallinas')
          .where('userId', isEqualTo: userId)
          .get();

      int totalHens = 0;
      for (var doc in lotSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalHens += int.tryParse(data['currentHens']?.toString() ?? '0') ?? 0;
      }

      double mortalityRate = totalHens > 0
          ? (totalDeaths / totalHens) * 100
          : 0;

      return {
        'totalDeaths': totalDeaths,
        'totalHens': totalHens,
        'mortalityRate': mortalityRate,
        'deathsByDay': deathsByDay,
        'deathsByWeek': deathsByWeek,
      };
    } catch (e) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('mortalidad_gallinas')
            .where('userId', isEqualTo: userId)
            .get();

        int totalDeaths = 0;
        Map<String, int> deathsByDay = {};
        Map<String, int> deathsByWeek = {};
        DateTime startDate = DateTime.now().subtract(Duration(days: days));

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          DateTime date = DateTime.parse(data['date']);
          if (date.isBefore(startDate)) continue;
          
          int deaths = int.tryParse(data['deadHens']?.toString() ?? '0') ?? 0;
          totalDeaths += deaths;

          String dayKey = '${date.year}-${date.month}-${date.day}';
          deathsByDay[dayKey] = (deathsByDay[dayKey] ?? 0) + deaths;

          int weekNum = _getWeekNumber(date);
          String weekKey = '${date.year}-W$weekNum';
          deathsByWeek[weekKey] = (deathsByWeek[weekKey] ?? 0) + deaths;
        }

        QuerySnapshot lotSnapshot = await _firestore
            .collection('lotes_gallinas')
            .where('userId', isEqualTo: userId)
            .get();

        int totalHens = 0;
        for (var doc in lotSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          totalHens += int.tryParse(data['currentHens']?.toString() ?? '0') ?? 0;
        }

        double mortalityRate = totalHens > 0
            ? (totalDeaths / totalHens) * 100
            : 0;

        return {
          'totalDeaths': totalDeaths,
          'totalHens': totalHens,
          'mortalityRate': mortalityRate,
          'deathsByDay': deathsByDay,
          'deathsByWeek': deathsByWeek,
        };
      } catch (fallback) {
        return {
          'totalDeaths': 0,
          'totalHens': 0,
          'mortalityRate': 0.0,
          'deathsByDay': <String, int>{},
          'deathsByWeek': <String, int>{},
        };
      }
    }
  }

  Future<Map<String, dynamic>> getProductionSummary(
    String userId,
    int days,
  ) async {
    try {
      List<Map<String, dynamic>> data = await getDailyProduction(userId, days);

      if (data.isEmpty) {
        return {'totalEggs': 0, 'averageEggs': 0, 'maxEggs': 0, 'minEggs': 0};
      }

      int totalEggs = 0;
      int maxEggs = 0;
      int minEggs = 999999;

      for (var item in data) {
        int eggs = item['totalHuevos'] as int;
        totalEggs += eggs;
        if (eggs > maxEggs) maxEggs = eggs;
        if (eggs < minEggs && eggs > 0) minEggs = eggs;
      }

      return {
        'totalEggs': totalEggs,
        'averageEggs': totalEggs ~/ data.length,
        'maxEggs': maxEggs,
        'minEggs': minEggs == 999999 ? 0 : minEggs,
      };
    } catch (e) {
      return {'totalEggs': 0, 'averageEggs': 0, 'maxEggs': 0, 'minEggs': 0};
    }
  }

  Future<Map<String, dynamic>> getFeedSummary(String userId, int days) async {
    try {
      List<Map<String, dynamic>> data = await getFeedConsumptionReport(
        userId,
        days,
      );

      if (data.isEmpty) {
        return {'totalFeedKg': 0.0, 'averageFeedKg': 0.0, 'totalCost': 0.0};
      }

      double totalFeedKg = 0;
      double totalCost = 0;

      for (var item in data) {
        totalFeedKg += item['feedKg'] as double;
        totalCost += item['feedCost'] as double;
      }

      return {
        'totalFeedKg': totalFeedKg,
        'averageFeedKg': totalFeedKg / data.length,
        'totalCost': totalCost,
      };
    } catch (e) {
      return {'totalFeedKg': 0.0, 'averageFeedKg': 0.0, 'totalCost': 0.0};
    }
  }
}
