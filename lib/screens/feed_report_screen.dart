import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/report_service.dart';

class FeedReportScreen extends StatefulWidget {
  const FeedReportScreen({super.key});

  @override
  State<FeedReportScreen> createState() => _FeedReportScreenState();
}

class _FeedReportScreenState extends State<FeedReportScreen> {
  final ReportService _reportService = ReportService();

  bool _isLoading = true;
  int _selectedDays = 7;
  List<Map<String, dynamic>> _feedData = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      List<Map<String, dynamic>> data = await _reportService
          .getFeedConsumptionReport(user.uid, _selectedDays);
      Map<String, dynamic> summary = await _reportService.getFeedSummary(
        user.uid,
        _selectedDays,
      );

      if (mounted) {
        setState(() {
          _feedData = data;
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Reporte de Alimento'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedDays = value;
                _isLoading = true;
              });
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Últimos 7 días')),
              const PopupMenuItem(value: 14, child: Text('Últimos 14 días')),
              const PopupMenuItem(value: 30, child: Text('Últimos 30 días')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 16),
                    _buildChart(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            label: 'Total Consumido',
            value: '${(_summary['totalFeedKg'] ?? 0).toStringAsFixed(1)} kg',
            icon: Icons.scale,
            color: const Color(0xFF8B4513),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            label: 'Promedio/Día',
            value: '${(_summary['averageFeedKg'] ?? 0).toStringAsFixed(1)} kg',
            icon: Icons.trending_up,
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            label: 'Costo Total',
            value: 'Bs ${(_summary['totalCost'] ?? 0).toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: const Color(0xFFFF8C00),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_feedData.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No hay datos de consumo',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < _feedData.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (_feedData[i]['feedKg'] as double),
              color: const Color(0xFF8B4513),
              width: 16,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, color: Color(0xFF8B4513)),
                SizedBox(width: 8),
                Text(
                  'Consumo Diario',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < _feedData.length) {
                              DateTime date =
                                  _feedData[value.toInt()]['date'] as DateTime;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat('dd').format(date),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
