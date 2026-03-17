import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/dashboard_service.dart';
import '../models/feed_inventory_model.dart';
import 'registro_produccion_screen.dart';
import 'feed_consumption_screen.dart';
import 'register_sale_screen.dart';
import 'register_expense_screen.dart';

class SmartDashboardScreen extends StatefulWidget {
  const SmartDashboardScreen({super.key});

  @override
  State<SmartDashboardScreen> createState() => _SmartDashboardScreenState();
}

class _SmartDashboardScreenState extends State<SmartDashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  Map<String, dynamic> _data = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Map<String, dynamic> data = await _dashboardService.getDashboardData(
        user.uid,
      );
      if (mounted) {
        setState(() {
          _data = data;
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
        title: const Text('Dashboard Inteligente'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
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
                    _buildAlertsSection(),
                    const SizedBox(height: 16),
                    _buildQuickActionsSection(),
                    const SizedBox(height: 16),
                    _buildFlockStatusSection(),
                    const SizedBox(height: 16),
                    _buildProductionSection(),
                    const SizedBox(height: 16),
                    _buildFeedSection(),
                    const SizedBox(height: 16),
                    _buildFinanceSection(),
                    const SizedBox(height: 16),
                    _buildInventorySection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAlertsSection() {
    List<Widget> alerts = [];

    if (_data['feedInventory'] != null) {
      List<FeedInventoryModel> inventory =
          _data['feedInventory'] as List<FeedInventoryModel>;
      List<FeedInventoryModel> lowStock = inventory
          .where((i) => i.isLowStock)
          .toList();

      if (lowStock.isNotEmpty) {
        alerts.add(
          _buildAlertCard(
            icon: Icons.warning_amber,
            title: 'Stock de Alimento Bajo',
            message: '${lowStock.length} tipo(s) necesitan reposición',
            color: Colors.orange,
          ),
        );
      }
    }

    if (_data['upcomingVaccinations'] != null) {
      List<Map<String, dynamic>> vaccinations =
          _data['upcomingVaccinations'] as List<Map<String, dynamic>>;

      if (vaccinations.isNotEmpty) {
        alerts.add(
          _buildAlertCard(
            icon: Icons.vaccines,
            title: 'Vacunas Pendientes',
            message: '${vaccinations.length} vacuna(s) en los próximos 7 días',
            color: Colors.red,
          ),
        );
      }
    }

    if (_data['flockStatus'] != null) {
      Map<String, dynamic> flock = _data['flockStatus'] as Map<String, dynamic>;
      double mortalityRate = (flock['mortalityRate'] ?? 0).toDouble();

      if (mortalityRate > 1) {
        alerts.add(
          _buildAlertCard(
            icon: Icons.trending_up,
            title: 'Mortalidad Alta',
            message: 'Tasa de mortalidad: ${mortalityRate.toStringAsFixed(1)}%',
            color: Colors.red,
          ),
        );
      }
    }

    if (alerts.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Todo en orden',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: alerts);
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.egg,
                label: 'Producción',
                color: const Color(0xFFFF8C00),
                onTap: () => _navigateTo(const RegistroProduccionScreen()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.restaurant,
                label: 'Alimento',
                color: const Color(0xFF8B4513),
                onTap: () => _navigateTo(const FeedConsumptionScreen()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.sell,
                label: 'Venta',
                color: const Color(0xFF4CAF50),
                onTap: () => _navigateTo(const RegisterSaleScreen()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.receipt_long,
                label: 'Gasto',
                color: const Color(0xFFE53935),
                onTap: () => _navigateTo(const RegisterExpenseScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) => _loadData());
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlockStatusSection() {
    Map<String, dynamic> flock = _data['flockStatus'] ?? {};
    int totalHens = flock['totalHens'] ?? 0;
    int totalLots = flock['totalLots'] ?? 0;
    int todayDeaths = flock['todayDeaths'] ?? 0;
    double mortalityRate = (flock['mortalityRate'] ?? 0).toDouble();

    return _buildSection(
      title: 'Estado del Lote',
      icon: Icons.egg_alt,
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              label: 'Gallinas Vivas',
              value: '$totalHens',
              icon: Icons.pets,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricCard(
              label: 'Lotes',
              value: '$totalLots',
              icon: Icons.folder,
              color: const Color(0xFF1976D2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricCard(
              label: 'Muertes Hoy',
              value: '$todayDeaths',
              icon: Icons.warning,
              color: mortalityRate > 1 ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionSection() {
    Map<String, dynamic> production = _data['production'] ?? {};
    int totalEggs = production['totalHuevos'] ?? 0;

    return _buildSection(
      title: 'Producción de Hoy',
      icon: Icons.egg,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildMetricCard(
                  label: 'Total Huevos',
                  value: '$totalEggs',
                  icon: Icons.egg,
                  color: const Color(0xFFFF8C00),
                  isLarge: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMiniMetric(label: 'Extra', value: '${production['extra'] ?? 0}', color: const Color(0xFF2E7D32)),
              _buildMiniMetric(label: 'Especial', value: '${production['especial'] ?? 0}', color: const Color(0xFF4CAF50)),
              _buildMiniMetric(label: '1ra', value: '${production['primera'] ?? 0}', color: const Color(0xFF8BC34A)),
              _buildMiniMetric(label: '2da', value: '${production['segunda'] ?? 0}', color: const Color(0xFFCDDC39)),
              _buildMiniMetric(label: '3ra', value: '${production['tercera'] ?? 0}', color: const Color(0xFFFFEB3B)),
              _buildMiniMetric(label: '4ta', value: '${production['cuarta'] ?? 0}', color: const Color(0xFFFFC107)),
              _buildMiniMetric(label: '5ta', value: '${production['quinta'] ?? 0}', color: const Color(0xFFFF9800)),
              _buildMiniMetric(label: 'Sucios', value: '${production['sucios'] ?? 0}', color: const Color(0xFF795548)),
              _buildMiniMetric(label: 'Rajados', value: '${production['rajados'] ?? 0}', color: const Color(0xFF9E9E9E)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedSection() {
    double feedConsumption = (_data['feedConsumption'] ?? 0).toDouble();
    double feedConversion = (_data['feedConversion'] ?? 0).toDouble();

    return _buildSection(
      title: 'Consumo de Alimento',
      icon: Icons.restaurant,
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              label: 'Consumido',
              value: '${feedConsumption.toStringAsFixed(1)} kg',
              icon: Icons.scale,
              color: const Color(0xFF8B4513),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricCard(
              label: 'Conversión',
              value: feedConversion > 0
                  ? '${feedConversion.toStringAsFixed(2)} kg/huevo'
                  : 'N/A',
              icon: Icons.trending_up,
              color: feedConversion > 0 && feedConversion < 0.15
                  ? Colors.green
                  : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceSection() {
    double income = (_data['income'] ?? 0).toDouble();
    double expenses = (_data['expenses'] ?? 0).toDouble();
    double feedCost = (_data['feedCost'] ?? 0).toDouble();
    double profit = (_data['profit'] ?? 0).toDouble();

    return _buildSection(
      title: 'Resumen Financiero',
      icon: Icons.attach_money,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  label: 'Ingresos',
                  value: 'Bs ${income.toStringAsFixed(2)}',
                  icon: Icons.arrow_upward,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  label: 'Gastos',
                  value: 'Bs ${expenses.toStringAsFixed(2)}',
                  icon: Icons.arrow_downward,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  label: 'Ganancia',
                  value: 'Bs ${profit.toStringAsFixed(2)}',
                  icon: profit >= 0 ? Icons.thumb_up : Icons.thumb_down,
                  color: profit >= 0 ? const Color(0xFF2E7D32) : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF8B4513)),
            ),
            child: Row(
              children: [
                const Icon(Icons.restaurant, color: Color(0xFF8B4513), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Costo de Alimento',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B4513),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Bs ${feedCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySection() {
    List<FeedInventoryModel> inventory = _data['feedInventory'] ?? [];
    double totalStock = inventory.fold(0.0, (sum, item) => sum + item.stockKg);
    int lowStockCount = inventory.where((i) => i.isLowStock).length;

    return _buildSection(
      title: 'Inventario de Alimento',
      icon: Icons.inventory_2,
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              label: 'Stock Total',
              value: '${totalStock.toStringAsFixed(1)} kg',
              icon: Icons.warehouse,
              color: const Color(0xFF607D8B),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildMetricCard(
              label: 'Stock Bajo',
              value: '$lowStockCount',
              icon: Icons.warning,
              color: lowStockCount > 0 ? Colors.orange : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF2E7D32), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isLarge = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(isLarge ? 16 : 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: isLarge ? 32 : 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isLarge ? 24 : 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
