import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/hen_mortality_model.dart';
import '../models/hen_lot_model.dart';
import '../services/mortality_service.dart';
import '../services/lot_service.dart';

class MortalityHistoryScreen extends StatefulWidget {
  const MortalityHistoryScreen({super.key});

  @override
  State<MortalityHistoryScreen> createState() => _MortalityHistoryScreenState();
}

class _MortalityHistoryScreenState extends State<MortalityHistoryScreen> {
  final MortalityService _mortalityService = MortalityService();
  final LotService _lotService = LotService();
  List<HenMortalityModel> _records = [];
  List<HenLotModel> _lots = [];
  bool _isLoading = true;
  String? _error;
  int _totalDead = 0;
  int _initialHens = 0;
  int _currentHens = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      List<HenMortalityModel> records = await _mortalityService
          .getMortalityByUser(user.uid);
      List<HenLotModel> lots = await _lotService.getLotsByUser(user.uid);

      // Calculate totals
      int totalDead = 0;
      int initialTotal = 0;
      int currentTotal = 0;

      for (var lot in lots) {
        initialTotal += lot.initialHens;
        currentTotal += lot.currentHens;
      }

      for (var record in records) {
        totalDead += record.deadHens;
      }

      setState(() {
        _records = records;
        _lots = lots;
        _totalDead = totalDead;
        _initialHens = initialTotal;
        _currentHens = currentTotal;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double get _mortalityRate {
    if (_initialHens == 0) return 0;
    return (_totalDead / _initialHens) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Historial de Mortalidad'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildRecordsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
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
                Icon(Icons.analytics, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'Estadísticas de Mortalidad',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Iniciales',
                    '$_initialHens',
                    Icons.egg,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Actuales',
                    '$_currentHens',
                    Icons.egg_alt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Muertes',
                    '$_totalDead',
                    Icons.warning,
                    color: Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Tasa %',
                    '${_mortalityRate.toStringAsFixed(1)}%',
                    Icons.percent,
                    color: _mortalityRate > 10 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity( 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color ?? Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.grey,
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

  Widget _buildRecordsList() {
    if (_records.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
              const SizedBox(height: 16),
              Text(
                'No hay registros de mortalidad',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registros de Mortalidad',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        ..._records.map((record) => _buildRecordCard(record)),
      ],
    );
  }

  Widget _buildRecordCard(HenMortalityModel record) {
    Color causeColor;
    switch (record.cause) {
      case 'Enfermedad':
        causeColor = Colors.red;
        break;
      case 'Depredador':
        causeColor = Colors.orange;
        break;
      case 'Accidente':
        causeColor = Colors.blue;
        break;
      default:
        causeColor = Colors.grey;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.warning, color: Colors.white, size: 28),
        ),
        title: Text(
          'Lote ${record.lotNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(DateFormat('dd/MM/yyyy', 'es_ES').format(record.date)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: causeColor.withOpacity( 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${record.deadHens}',
            style: TextStyle(fontWeight: FontWeight.bold, color: causeColor),
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow('Causa', record.cause),
                if (record.notes != null && record.notes!.isNotEmpty)
                  _buildDetailRow('Notas', record.notes!),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () => _showDeleteConfirmation(record),
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Eliminar'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(HenMortalityModel record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar el registro del ${DateFormat('dd/MM/yyyy').format(record.date)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteRecord(record);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecord(HenMortalityModel record) async {
    setState(() => _isLoading = true);
    try {
      await _mortalityService.deleteMortality(record.id!);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro eliminado'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
