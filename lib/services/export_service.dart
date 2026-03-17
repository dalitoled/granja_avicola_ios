import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _localFile(String filename) async {
    final path = await _localPath;
    return File('$path/$filename');
  }

  Future<void> shareFile(File file, String subject) async {
    await Share.shareXFiles([XFile(file.path)], subject: subject);
  }

  // Production PDF Export
  Future<File> exportProductionPDF(String userId, int days) async {
    final pdf = pw.Document();
    final data = await _getProductionData(userId, days);
    final summary = await _getProductionSummary(userId, days);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader('Reporte de Producción'),
          pw.SizedBox(height: 10),
          pw.Text(
            'Período: ${dateFormat.format(startDate)} - ${dateFormat.format(now)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          _buildSummaryRow('Total Huevos', '${summary['totalEggs']}'),
          _buildSummaryRow('Promedio Diario', '${summary['averageEggs']}'),
          _buildSummaryRow('Producción Máxima', '${summary['maxEggs']}'),
          _buildSummaryRow('Producción Mínima', '${summary['minEggs']}'),
          pw.SizedBox(height: 20),
          pw.Text(
            'Detalle Diario',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: [
              'Fecha',
              'Total',
              'Pequeños',
              'Medianos',
              'Grandes',
              'Extra Grandes',
              'Descarte',
            ],
            data: data
                .map(
                  (e) => [
                    dateFormat.format(e['date']),
                    '${e['totalHuevos']}',
                    '${e['huevosPequeños']}',
                    '${e['huevosMedianos']}',
                    '${e['huevosGrandes']}',
                    '${e['huevosExtraGrandes']}',
                    '${e['huevosDescarte']}',
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    final file = await _localFile(
      'reporte_produccion_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Production Excel Export
  Future<File> exportProductionExcel(String userId, int days) async {
    final excel = Excel.createExcel();
    final data = await _getProductionData(userId, days);
    final summary = await _getProductionSummary(userId, days);
    final dateFormat = DateFormat('dd/MM/yyyy');

    final sheet = excel['Producción'];

    sheet.appendRow([TextCellValue('Reporte de Producción')]);
    sheet.appendRow([TextCellValue('Total Huevos: ${summary['totalEggs']}')]);
    sheet.appendRow([TextCellValue('Promedio: ${summary['averageEggs']}')]);
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('Fecha'),
      TextCellValue('Total'),
      TextCellValue('Pequeños'),
      TextCellValue('Medianos'),
      TextCellValue('Grandes'),
      TextCellValue('Extra Grandes'),
      TextCellValue('Descarte'),
    ]);

    for (var item in data) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(item['date'])),
        IntCellValue(item['totalHuevos'] as int),
        IntCellValue(item['huevosPequeños'] as int),
        IntCellValue(item['huevosMedianos'] as int),
        IntCellValue(item['huevosGrandes'] as int),
        IntCellValue(item['huevosExtraGrandes'] as int),
        IntCellValue(item['huevosDescarte'] as int),
      ]);
    }

    final file = await _localFile(
      'reporte_produccion_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    final bytes = excel.encode();
    await file.writeAsBytes(bytes!);
    return file;
  }

  // Feed PDF Export
  Future<File> exportFeedPDF(String userId, int days) async {
    final pdf = pw.Document();
    final data = await _getFeedData(userId, days);
    final summary = await _getFeedSummary(userId, days);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader('Reporte de Consumo de Alimento'),
          pw.SizedBox(height: 10),
          pw.Text(
            'Período: ${dateFormat.format(startDate)} - ${dateFormat.format(now)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          _buildSummaryRow(
            'Total Consumido',
            '${(summary['totalFeedKg'] as double).toStringAsFixed(1)} kg',
          ),
          _buildSummaryRow(
            'Promedio Diario',
            '${(summary['averageFeedKg'] as double).toStringAsFixed(1)} kg',
          ),
          _buildSummaryRow(
            'Costo Total',
            'Bs ${(summary['totalCost'] as double).toStringAsFixed(2)}',
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Detalle Diario',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Fecha', 'Cantidad (kg)', 'Tipo', 'Costo (Bs)'],
            data: data
                .map(
                  (e) => [
                    dateFormat.format(e['date']),
                    ((e['feedKg'] as double).toStringAsFixed(1)),
                    '${e['feedType']}',
                    ((e['feedCost'] as double).toStringAsFixed(2)),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.center,
            cellStyle: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    final file = await _localFile(
      'reporte_alimento_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Feed Excel Export
  Future<File> exportFeedExcel(String userId, int days) async {
    final excel = Excel.createExcel();
    final data = await _getFeedData(userId, days);
    final summary = await _getFeedSummary(userId, days);
    final dateFormat = DateFormat('dd/MM/yyyy');

    final sheet = excel['Alimento'];

    sheet.appendRow([TextCellValue('Reporte de Consumo de Alimento')]);
    sheet.appendRow([
      TextCellValue(
        'Total: ${(summary['totalFeedKg'] as double).toStringAsFixed(1)} kg',
      ),
    ]);
    sheet.appendRow([
      TextCellValue(
        'Costo: Bs ${(summary['totalCost'] as double).toStringAsFixed(2)}',
      ),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('Fecha'),
      TextCellValue('Cantidad (kg)'),
      TextCellValue('Tipo'),
      TextCellValue('Costo (Bs)'),
    ]);

    for (var item in data) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(item['date'])),
        TextCellValue((item['feedKg'] as double).toStringAsFixed(1)),
        TextCellValue('${item['feedType']}'),
        TextCellValue((item['feedCost'] as double).toStringAsFixed(2)),
      ]);
    }

    final file = await _localFile(
      'reporte_alimento_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    final bytes = excel.encode();
    await file.writeAsBytes(bytes!);
    return file;
  }

  // Financial PDF Export
  Future<File> exportFinancialPDF(String userId, int days) async {
    final pdf = pw.Document();
    final data = await _getFinancialData(userId, days);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader('Reporte Financiero'),
          pw.SizedBox(height: 10),
          pw.Text(
            'Período: ${dateFormat.format(startDate)} - ${dateFormat.format(now)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          _buildSummaryRow(
            'Total Ingresos',
            'Bs ${(data['totalIncome'] as double).toStringAsFixed(2)}',
          ),
          _buildSummaryRow(
            'Total Gastos',
            'Bs ${(data['totalExpenses'] as double).toStringAsFixed(2)}',
          ),
          _buildSummaryRow(
            'Ganancia Neta',
            'Bs ${(data['profit'] as double).toStringAsFixed(2)}',
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Resumen',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Concepto', 'Cantidad'],
            data: [
              ['Ventas Registradas', '${data['salesCount']}'],
              ['Gastos Registrados', '${data['expensesCount']}'],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.center,
          ),
        ],
      ),
    );

    final file = await _localFile(
      'reporte_financiero_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Financial Excel Export
  Future<File> exportFinancialExcel(String userId, int days) async {
    final excel = Excel.createExcel();
    final data = await _getFinancialData(userId, days);

    final sheet = excel['Financiero'];

    sheet.appendRow([TextCellValue('Reporte Financiero')]);
    sheet.appendRow([
      TextCellValue(
        'Ingresos: Bs ${(data['totalIncome'] as double).toStringAsFixed(2)}',
      ),
    ]);
    sheet.appendRow([
      TextCellValue(
        'Gastos: Bs ${(data['totalExpenses'] as double).toStringAsFixed(2)}',
      ),
    ]);
    sheet.appendRow([
      TextCellValue(
        'Ganancia: Bs ${(data['profit'] as double).toStringAsFixed(2)}',
      ),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('Ventas'),
      IntCellValue(data['salesCount'] as int),
    ]);
    sheet.appendRow([
      TextCellValue('Gastos'),
      IntCellValue(data['expensesCount'] as int),
    ]);

    final file = await _localFile(
      'reporte_financiero_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    final bytes = excel.encode();
    await file.writeAsBytes(bytes!);
    return file;
  }

  // Mortality PDF Export
  Future<File> exportMortalityPDF(String userId, int days) async {
    final pdf = pw.Document();
    final data = await _getMortalityData(userId, days);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader('Reporte de Mortalidad'),
          pw.SizedBox(height: 10),
          pw.Text(
            'Período: ${dateFormat.format(startDate)} - ${dateFormat.format(now)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          _buildSummaryRow('Total Muertes', '${data['totalDeaths']}'),
          _buildSummaryRow('Gallinas Activas', '${data['totalHens']}'),
          _buildSummaryRow(
            'Tasa de Mortalidad',
            '${(data['mortalityRate'] as double).toStringAsFixed(2)}%',
          ),
        ],
      ),
    );

    final file = await _localFile(
      'reporte_mortalidad_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Mortality Excel Export
  Future<File> exportMortalityExcel(String userId, int days) async {
    final excel = Excel.createExcel();
    final data = await _getMortalityData(userId, days);

    final sheet = excel['Mortalidad'];

    sheet.appendRow([TextCellValue('Reporte de Mortalidad')]);
    sheet.appendRow([TextCellValue('Total Muertes: ${data['totalDeaths']}')]);
    sheet.appendRow([TextCellValue('Gallinas Activas: ${data['totalHens']}')]);
    sheet.appendRow([
      TextCellValue(
        'Tasa: ${(data['mortalityRate'] as double).toStringAsFixed(2)}%',
      ),
    ]);

    final file = await _localFile(
      'reporte_mortalidad_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    final bytes = excel.encode();
    await file.writeAsBytes(bytes!);
    return file;
  }

  // Helper methods
  pw.Widget _buildHeader(String title) {
    return pw.Container(
      decoration: const pw.BoxDecoration(color: PdfColors.green),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Center(
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12)),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Data fetching methods
  Future<List<Map<String, dynamic>>> _getProductionData(
    String userId,
    int days,
  ) async {
    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(Duration(days: days));

    QuerySnapshot snapshot = await _firestore
        .collection('produccion_diaria')
        .where('userId', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> results = [];
    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      DateTime docDate = DateTime.parse(data['date']);
      if (docDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          docDate.isBefore(endDate.add(const Duration(days: 1)))) {
        results.add({
          'date': docDate,
          'totalHuevos': data['totalHuevos'] ?? 0,
          'huevosPequeños': data['huevosPequeños'] ?? 0,
          'huevosMedianos': data['huevosMedianos'] ?? 0,
          'huevosGrandes': data['huevosGrandes'] ?? 0,
          'huevosExtraGrandes': data['huevosExtraGrandes'] ?? 0,
          'huevosDescarte': data['huevosDescarte'] ?? 0,
        });
      }
    }
    results.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );
    return results;
  }

  Future<Map<String, dynamic>> _getProductionSummary(
    String userId,
    int days,
  ) async {
    List<Map<String, dynamic>> data = await _getProductionData(userId, days);
    if (data.isEmpty) {
      return {'totalEggs': 0, 'averageEggs': 0, 'maxEggs': 0, 'minEggs': 0};
    }

    int total = 0, max = 0, min = 999999;
    for (var item in data) {
      int eggs = item['totalHuevos'] as int;
      total += eggs;
      if (eggs > max) max = eggs;
      if (eggs < min && eggs > 0) min = eggs;
    }

    return {
      'totalEggs': total,
      'averageEggs': total ~/ data.length,
      'maxEggs': max,
      'minEggs': min == 999999 ? 0 : min,
    };
  }

  Future<List<Map<String, dynamic>>> _getFeedData(
    String userId,
    int days,
  ) async {
    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(Duration(days: days));

    QuerySnapshot snapshot = await _firestore
        .collection('consumo_alimento')
        .where('userId', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> results = [];
    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      DateTime docDate = DateTime.parse(data['date']);
      if (docDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          docDate.isBefore(endDate.add(const Duration(days: 1)))) {
        results.add({
          'date': docDate,
          'feedKg': (data['feedKg'] ?? 0).toDouble(),
          'feedType': data['feedType'] ?? '',
          'feedCost': (data['feedCost'] ?? 0).toDouble(),
        });
      }
    }
    results.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );
    return results;
  }

  Future<Map<String, dynamic>> _getFeedSummary(String userId, int days) async {
    List<Map<String, dynamic>> data = await _getFeedData(userId, days);
    if (data.isEmpty) {
      return {'totalFeedKg': 0.0, 'averageFeedKg': 0.0, 'totalCost': 0.0};
    }

    double totalKg = 0, totalCost = 0;
    for (var item in data) {
      totalKg += item['feedKg'] as double;
      totalCost += item['feedCost'] as double;
    }

    return {
      'totalFeedKg': totalKg,
      'averageFeedKg': totalKg / data.length,
      'totalCost': totalCost,
    };
  }

  Future<Map<String, dynamic>> _getFinancialData(
    String userId,
    int days,
  ) async {
    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(Duration(days: days));

    QuerySnapshot salesSnapshot = await _firestore
        .collection('ventas_huevos')
        .where('userId', isEqualTo: userId)
        .get();

    QuerySnapshot expenseSnapshot = await _firestore
        .collection('gastos_granja')
        .where('userId', isEqualTo: userId)
        .get();

    double totalIncome = 0, totalExpenses = 0;
    int salesCount = 0, expensesCount = 0;

    for (var doc in salesSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      DateTime docDate = DateTime.parse(data['date']);
      if (docDate.isAfter(startDate.subtract(const Duration(days: 1)))) {
        totalIncome += (data['total'] ?? 0).toDouble();
        salesCount++;
      }
    }
    for (var doc in expenseSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      DateTime docDate = DateTime.parse(data['date']);
      if (docDate.isAfter(startDate.subtract(const Duration(days: 1)))) {
        totalExpenses += (data['amount'] ?? 0).toDouble();
        expensesCount++;
      }
    }

    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'profit': totalIncome - totalExpenses,
      'salesCount': salesCount,
      'expensesCount': expensesCount,
    };
  }

  Future<Map<String, dynamic>> _getMortalityData(
    String userId,
    int days,
  ) async {
    DateTime endDate = DateTime.now();
    DateTime startDate = endDate.subtract(Duration(days: days));

    QuerySnapshot snapshot = await _firestore
        .collection('mortalidad_gallinas')
        .where('userId', isEqualTo: userId)
        .get();

    int totalDeaths = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      DateTime docDate = DateTime.parse(data['date']);
      if (docDate.isAfter(startDate.subtract(const Duration(days: 1)))) {
        totalDeaths += (data['deadHens'] ?? 0) as int;
      }
    }

    QuerySnapshot lotSnapshot = await _firestore
        .collection('lotes_gallinas')
        .where('userId', isEqualTo: userId)
        .get();

    int totalHens = 0;
    for (var doc in lotSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['status'] == 'Activo') {
        totalHens += (data['currentHens'] ?? 0) as int;
      }
    }

    double mortalityRate = totalHens > 0
        ? (totalDeaths / totalHens) * 100
        : 0.0;

    return {
      'totalDeaths': totalDeaths,
      'totalHens': totalHens,
      'mortalityRate': mortalityRate,
    };
  }
}
