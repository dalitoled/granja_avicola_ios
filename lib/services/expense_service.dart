import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/farm_expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> categories = [
    'Alimento',
    'Medicina',
    'Vacunas',
    'Electricidad',
    'Agua',
    'Transporte',
    'Mantenimiento',
    'Mano de obra',
    'Otro',
  ];

  static const List<String> paymentMethods = [
    'Efectivo',
    'Transferencia',
    'Tarjeta',
  ];

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Alimento':
        return Icons.restaurant;
      case 'Medicina':
        return Icons.medical_services;
      case 'Vacunas':
        return Icons.vaccines;
      case 'Electricidad':
        return Icons.electric_bolt;
      case 'Agua':
        return Icons.water_drop;
      case 'Transporte':
        return Icons.local_shipping;
      case 'Mantenimiento':
        return Icons.build;
      case 'Mano de obra':
        return Icons.person;
      default:
        return Icons.receipt;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Alimento':
        return const Color(0xFF8B4513);
      case 'Medicina':
        return const Color(0xFFE91E63);
      case 'Vacunas':
        return const Color(0xFF00BCD4);
      case 'Electricidad':
        return const Color(0xFFFFC107);
      case 'Agua':
        return const Color(0xFF2196F3);
      case 'Transporte':
        return const Color(0xFF9C27B0);
      case 'Mantenimiento':
        return const Color(0xFF607D8B);
      case 'Mano de obra':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF795548);
    }
  }

  Future<String> addExpense(FarmExpenseModel expense) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('gastos_granja')
          .add({
            'userId': expense.userId,
            'date': expense.date.toIso8601String(),
            'category': expense.category,
            'description': expense.description,
            'amount': expense.amount,
            'paymentMethod': expense.paymentMethod,
            'notes': expense.notes,
            'createdAt': expense.createdAt.toIso8601String(),
          });

      return docRef.id;
    } catch (e) {
      throw 'Error al registrar gasto: $e';
    }
  }

  Future<List<FarmExpenseModel>> getExpensesByUser(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('gastos_granja')
          .where('userId', isEqualTo: userId)
          .get();

      List<FarmExpenseModel> expenses = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return FarmExpenseModel.fromMap(data);
      }).toList();

      expenses.sort((a, b) => b.date.compareTo(a.date));
      return expenses;
    } catch (e) {
      throw 'Error al obtener gastos: $e';
    }
  }

  Future<List<FarmExpenseModel>> getExpensesByDate(
    String userId,
    DateTime date,
  ) async {
    try {
      List<FarmExpenseModel> allExpenses = await getExpensesByUser(userId);

      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      return allExpenses.where((expense) {
        return expense.date.isAfter(
              startOfDay.subtract(const Duration(seconds: 1)),
            ) &&
            expense.date.isBefore(endOfDay);
      }).toList();
    } catch (e) {
      throw 'Error al obtener gastos por fecha: $e';
    }
  }

  Future<List<FarmExpenseModel>> getMonthlyExpenses(
    String userId,
    int year,
    int month,
  ) async {
    try {
      List<FarmExpenseModel> allExpenses = await getExpensesByUser(userId);

      DateTime startOfMonth = DateTime(year, month, 1);
      DateTime endOfMonth = DateTime(year, month + 1, 1);

      return allExpenses.where((expense) {
        return expense.date.isAfter(
              startOfMonth.subtract(const Duration(seconds: 1)),
            ) &&
            expense.date.isBefore(endOfMonth);
      }).toList();
    } catch (e) {
      throw 'Error al obtener gastos mensuales: $e';
    }
  }

  Future<List<FarmExpenseModel>> getExpensesByCategory(
    String userId,
    String category,
  ) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('gastos_granja')
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .orderBy('date', descending: true)
          .get();

      List<FarmExpenseModel> expenses = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return FarmExpenseModel.fromMap(data);
      }).toList();

      return expenses;
    } catch (e) {
      throw 'Error al obtener gastos por categoría: $e';
    }
  }

  Future<double> getTotalExpensesByUser(String userId) async {
    try {
      List<FarmExpenseModel> expenses = await getExpensesByUser(userId);
      double total = 0;
      for (var expense in expenses) {
        total += expense.amount;
      }
      return total;
    } catch (e) {
      throw 'Error al obtener total de gastos: $e';
    }
  }

  Future<double> getTodayExpenses(String userId) async {
    try {
      List<FarmExpenseModel> expenses = await getExpensesByDate(
        userId,
        DateTime.now(),
      );
      double total = 0;
      for (var expense in expenses) {
        total += expense.amount;
      }
      return total;
    } catch (e) {
      throw 'Error al obtener gastos de hoy: $e';
    }
  }

  Future<double> getMonthlyExpensesTotal(
    String userId,
    int year,
    int month,
  ) async {
    try {
      List<FarmExpenseModel> expenses = await getMonthlyExpenses(
        userId,
        year,
        month,
      );
      double total = 0;
      for (var expense in expenses) {
        total += expense.amount;
      }
      return total;
    } catch (e) {
      throw 'Error al obtener gastos del mes: $e';
    }
  }

  Future<Map<String, double>> getExpensesByCategories(
    String userId, {
    int? year,
    int? month,
  }) async {
    try {
      List<FarmExpenseModel> expenses;

      if (year != null && month != null) {
        expenses = await getMonthlyExpenses(userId, year, month);
      } else {
        expenses = await getExpensesByUser(userId);
      }

      Map<String, double> categoryTotals = {};
      for (var expense in expenses) {
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }

      return categoryTotals;
    } catch (e) {
      throw 'Error al obtener gastos por categoría: $e';
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await _firestore.collection('gastos_granja').doc(expenseId).delete();
    } catch (e) {
      throw 'Error al eliminar gasto: $e';
    }
  }

  Future<void> updateExpense(FarmExpenseModel expense) async {
    try {
      await _firestore.collection('gastos_granja').doc(expense.id).update({
        'date': expense.date.toIso8601String(),
        'category': expense.category,
        'description': expense.description,
        'amount': expense.amount,
        'paymentMethod': expense.paymentMethod,
        'notes': expense.notes,
      });
    } catch (e) {
      throw 'Error al actualizar gasto: $e';
    }
  }
}
