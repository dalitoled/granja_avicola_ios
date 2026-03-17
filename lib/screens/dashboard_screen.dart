import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/feed_consumption_model.dart';
import '../services/feed_service.dart';
import 'login_screen.dart';
import 'registro_produccion_screen.dart';
import 'historial_produccion_screen.dart';
import 'register_sale_screen.dart';
import 'sales_history_screen.dart';
import 'feed_consumption_screen.dart';
import 'feed_history_screen.dart';
import 'production_efficiency_screen.dart';
import 'lot_list_screen.dart';
import 'create_lot_screen.dart';
import 'register_mortality_screen.dart';
import 'mortality_history_screen.dart';
import 'register_vaccination_screen.dart';
import 'vaccination_history_screen.dart';
import 'vaccination_calendar_screen.dart';
import 'feed_inventory_screen.dart';
import 'expense_history_screen.dart';
import 'smart_dashboard_screen.dart';
import 'reports_screen.dart';
import 'farm_profile_screen.dart';
import '../services/alert_service.dart';
import '../models/alert_model.dart';
import 'farm_alerts_screen.dart';
import 'production_prediction_screen.dart';
import '../services/admin_service.dart';
import 'authorization_codes_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final FeedService _feedService = FeedService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AlertService _alertService = AlertService();
  final AdminService _adminService = AdminService();
  String _userEmail = '';
  int _todayEggs = 0;
  double _todayFeed = 0;
  double _todayFeedCost = 0;
  double _gramsPerEgg = 0;
  bool _isLoadingIndicators = true;
  bool _isAdmin = false;
  AlertSeverity _alertStatus = AlertSeverity.normal;
  int _alertCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTodayIndicators();
    _loadAlertStatus();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final isAdmin = await _adminService.isAdmin(user.uid);
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  Future<void> _loadAlertStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final status = await _alertService.getOverallStatus(user.uid);
    final count = await _alertService.getAlertCount(user.uid);
    if (mounted) {
      setState(() {
        _alertStatus = status;
        _alertCount = count;
      });
    }
  }

  Future<void> _loadUserData() async {
    User? user = await _authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _userEmail = user.email ?? '';
      });
    }
  }

  Future<void> _loadTodayIndicators() async {
    try {
      User? user = await _authService.getCurrentUser();
      if (user == null) return;

      DateTime today = DateTime.now();

      QuerySnapshot productionSnapshot = await _firestore
          .collection('produccion_diaria')
          .where('userId', isEqualTo: user.uid)
          .get();

      int todayEggs = 0;
      for (var doc in productionSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime docDate = DateTime.parse(data['date']);
        if (docDate.year == today.year &&
            docDate.month == today.month &&
            docDate.day == today.day) {
          todayEggs = data['totalHuevos'] ?? 0;
          break;
        }
      }

      FeedConsumptionModel? feed = await _feedService.getFeedConsumptionByDate(
        user.uid,
        today,
      );

      double feedKg = feed?.feedKg ?? 0;
      double feedCost = feed?.feedCost ?? 0;

      double gramsPerEgg = 0;

      if (todayEggs > 0) {
        gramsPerEgg = (feedKg * 1000) / todayEggs;
      }

      if (mounted) {
        setState(() {
          _todayEggs = todayEggs;
          _todayFeed = feedKg;
          _todayFeedCost = feedCost;
          _gramsPerEgg = gramsPerEgg;
          _isLoadingIndicators = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingIndicators = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro de que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.signOut();
              if (mounted && context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Granja Avícola'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: const Color(0xFF2E7D32),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 35,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bienvenido',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _userEmail.isNotEmpty
                                      ? _userEmail
                                      : 'Usuario',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildAlertIndicator(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildFarmStatusRow(),
                    ],
                  ),
                ),
              ),
              if (_isAdmin) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthorizationCodesScreen(),
                      ),
                    ),
                    icon: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.purple,
                    ),
                    label: const Text('Códigos de Autorización'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      side: const BorderSide(color: Colors.purple),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FarmProfileScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.agriculture, color: Color(0xFF2E7D32)),
                  label: const Text('Perfil de Granja'),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Menú Principal',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 16),

              // 1. CONFIGURACIÓN - Lotes (Base de todo)
              _buildSectionHeader('1. Configuración - Lotes', Icons.egg_alt),
              _buildCategoryRow([
                _buildMenuCardCompact(
                  icon: Icons.add_box,
                  title: 'Crear Lote',
                  color: const Color(0xFFE91E63),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateLotScreen(),
                    ),
                  ),
                ),
                _buildMenuCardCompact(
                  icon: Icons.list,
                  title: 'Control Lotes',
                  color: const Color(0xFFFF5722),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LotListScreen(),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // 2. SALUD - Vacunación (Antes que nada)
              _buildSectionHeader('2. Salud - Vacunación', Icons.vaccines),
              _buildCategoryRow([
                _buildMenuCardCompact(
                  icon: Icons.add,
                  title: 'Registrar',
                  color: const Color(0xFF00BCD4),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterVaccinationScreen(),
                    ),
                  ),
                ),
                _buildMenuCardCompact(
                  icon: Icons.history,
                  title: 'Historial',
                  color: const Color(0xFF009688),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VaccinationHistoryScreen(),
                    ),
                  ),
                ),
              ]),
              _buildCategoryRow([
                _buildMenuCardCompact(
                  icon: Icons.calendar_month,
                  title: 'Calendario',
                  color: const Color(0xFF3F51B5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VaccinationCalendarScreen(),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // 3. ALIMENTO - Inventario primero, luego Consumo
              _buildSectionHeader(
                '3. Alimento - Inventario',
                Icons.inventory_2,
              ),
              _buildCategoryRow([
                _buildMenuCardCompact(
                  icon: Icons.inventory_2,
                  title: 'Inventario',
                  color: const Color(0xFF607D8B),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeedInventoryScreen(),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // 4. CONSUMO DE ALIMENTO (Requiere inventario)
              _buildSectionHeader('4. Alimento - Consumo', Icons.restaurant),
              _buildCategoryRow([
                _buildMenuCardCompact(
                  icon: Icons.restaurant_menu,
                  title: 'Registrar',
                  color: const Color(0xFF795548),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeedConsumptionScreen(),
                    ),
                  ),
                ),
                _buildMenuCardCompact(
                  icon: Icons.history,
                  title: 'Historial',
                  color: const Color(0xFFA0522D),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeedHistoryScreen(),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // 5. PRODUCCIÓN (Requiere lotes y alimento)
              _buildSectionHeader('5. Producción de Huevos', Icons.egg),
              _buildCategoryRow([
                _buildMenuCardCompact(
                  icon: Icons.add_circle,
                  title: 'Registrar',
                  color: const Color(0xFFFF8C00),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistroProduccionScreen(),
                    ),
                  ),
                ),
                _buildMenuCardCompact(
                  icon: Icons.history,
                  title: 'Historial',
                  color: const Color(0xFF8BC34A),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistorialProduccionScreen(),
                    ),
                  ),
                ),
              ]),
              _buildCategoryRow([
                _buildMenuCardCompact(
                  icon: Icons.trending_up,
                  title: 'Eficiencia',
                  color: const Color(0xFF00BCD4),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductionEfficiencyScreen(),
                    ),
                  ),
                ),
                _buildMenuCardCompact(
                  icon: Icons.auto_graph,
                  title: 'Predicción',
                  color: const Color(0xFF3F51B5),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductionPredictionScreen(),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // 6. VENTAS (Después de producir)
              _buildSectionHeader('6. Ventas de Huevos', Icons.sell),
              _buildCategoryRow([
                _buildMenuCardCompact(
                  icon: Icons.add_shopping_cart,
                  title: 'Registrar',
                  color: const Color(0xFF4CAF50),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterSaleScreen(),
                    ),
                  ),
                ),
                _buildMenuCardCompact(
                  icon: Icons.point_of_sale,
                  title: 'Historial',
                  color: const Color(0xFF009688),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SalesHistoryScreen(),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // 7. MORTALIDAD
              _buildSectionHeader('7. Mortalidad', Icons.health_and_safety),
              _buildCategoryRow([
                _buildMenuCardCompact(
                  icon: Icons.warning,
                  title: 'Registrar',
                  color: const Color(0xFFB71C1C),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterMortalityScreen(),
                    ),
                  ),
                ),
                _buildMenuCardCompact(
                  icon: Icons.local_hospital,
                  title: 'Historial',
                  color: const Color(0xFF795548),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MortalityHistoryScreen(),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // 8. GESTIÓN
              _buildSectionHeader('8. Gestión - Gastos', Icons.business),
              _buildCategoryRow([
                _buildMenuCardCompact(
                  icon: Icons.receipt_long,
                  title: 'Gastos',
                  color: const Color(0xFFE53935),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpenseHistoryScreen(),
                    ),
                  ),
                ),
                _buildMenuCardCompact(
                  icon: Icons.analytics,
                  title: 'Reportes',
                  color: const Color(0xFF9C27B0),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReportsScreen(),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 20),

              // 9. MONITOREO - Dashboard y Alertas
              _buildSectionHeader('9. Monitoreo', Icons.monitor_heart),
              _buildCategoryRow([
                _buildMenuCardCompact(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  color: const Color(0xFF2E7D32),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SmartDashboardScreen(),
                    ),
                  ),
                ),
                _buildMenuCardCompact(
                  icon: Icons.notifications_active,
                  title: 'Alertas',
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FarmAlertsScreen(),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2E7D32), size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: children.map((child) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: child,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuCardCompact({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.8)],
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics, color: Color(0xFF2E7D32)),
                    SizedBox(width: 8),
                    Text(
                      'Indicadores de Hoy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () {
                    setState(() => _isLoadingIndicators = true);
                    _loadTodayIndicators();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingIndicators)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildIndicatorItem(
                          icon: Icons.egg,
                          label: 'Huevos',
                          value: '$_todayEggs',
                          color: const Color(0xFFFF8C00),
                        ),
                      ),
                      Expanded(
                        child: _buildIndicatorItem(
                          icon: Icons.restaurant,
                          label: 'Alimento',
                          value: '${_todayFeed.toStringAsFixed(1)} kg',
                          color: const Color(0xFF8B4513),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildIndicatorItem(
                          icon: Icons.attach_money,
                          label: 'Costo alimento',
                          value: 'Bs ${_todayFeedCost.toStringAsFixed(2)}',
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                      Expanded(
                        child: _buildIndicatorItem(
                          icon: Icons.trending_up,
                          label: 'g/huevo',
                          value: _gramsPerEgg > 0
                              ? '${_gramsPerEgg.toStringAsFixed(1)} g'
                              : 'N/A',
                          color: _gramsPerEgg <= 120
                              ? Colors.green
                              : (_gramsPerEgg <= 140
                                    ? Colors.orange
                                    : Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.7)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertIndicator() {
    Color color;
    IconData icon;
    String label;

    switch (_alertStatus) {
      case AlertSeverity.critical:
        color = Colors.red;
        icon = Icons.error;
        label = '$_alertCount';
        break;
      case AlertSeverity.warning:
        color = Colors.orange;
        icon = Icons.warning;
        label = '$_alertCount';
        break;
      case AlertSeverity.normal:
        color = Colors.green;
        icon = Icons.check_circle;
        label = '';
        break;
    }

    if (_alertStatus == AlertSeverity.normal) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FarmAlertsScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FarmAlertsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmStatusRow() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_alertStatus) {
      case AlertSeverity.critical:
        statusColor = Colors.red.shade100;
        statusText = 'Estado: Crítico - Revisar alertas';
        statusIcon = Icons.error_outline;
        break;
      case AlertSeverity.warning:
        statusColor = Colors.orange.shade100;
        statusText = 'Estado: Advertencia - Revisar alertas';
        statusIcon = Icons.warning_amber;
        break;
      case AlertSeverity.normal:
        statusColor = Colors.green.shade100;
        statusText = 'Estado: Normal - Todo en orden';
        statusIcon = Icons.check_circle_outline;
        break;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FarmAlertsScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              statusIcon,
              size: 18,
              color: _alertStatus == AlertSeverity.normal
                  ? Colors.green.shade700
                  : (_alertStatus == AlertSeverity.warning
                        ? Colors.orange.shade700
                        : Colors.red.shade700),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _alertStatus == AlertSeverity.normal
                      ? Colors.green.shade700
                      : (_alertStatus == AlertSeverity.warning
                            ? Colors.orange.shade700
                            : Colors.red.shade700),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
