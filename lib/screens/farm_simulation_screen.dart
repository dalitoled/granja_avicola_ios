import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/farm_simulation_service.dart';

class FarmSimulationScreen extends StatefulWidget {
  const FarmSimulationScreen({super.key});

  @override
  State<FarmSimulationScreen> createState() => _FarmSimulationScreenState();
}

class _FarmSimulationScreenState extends State<FarmSimulationScreen> {
  final FarmSimulationService _simulationService = FarmSimulationService();
  bool _isRunning = false;
  String _status = '';
  int _dataCount = 0;
  bool _hasExistingData = false;

  @override
  void initState() {
    super.initState();
    _checkExistingData();
  }

  Future<void> _checkExistingData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final hasData = await _simulationService.checkSimulationExists(user.uid);
    final count = await _simulationService.getSimulationDataCount(user.uid);

    if (mounted) {
      setState(() {
        _hasExistingData = hasData;
        _dataCount = count;
      });
    }
  }

  Future<void> _runSimulation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuario no autenticado')));
      return;
    }

    if (_hasExistingData) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Datos Existentes'),
          content: Text(
            'Ya existen $_dataCount registros de simulación. ¿Desea generar nuevos datos? Esto sobrescribirá los datos existentes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Generar Nuevos'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    setState(() {
      _isRunning = true;
      _status = 'Iniciando simulación...';
    });

    try {
      await _simulationService.createInitialLot();

      setState(() {
        _status = 'Generando datos de producción de huevos...';
      });

      await _simulationService.generateFarmSimulation(user.uid);

      setState(() {
        _status = 'Simulación completada!';
        _isRunning = false;
        _hasExistingData = true;
        _dataCount = 90;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulación completada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isRunning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulación de Granja'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildParametersCard(),
            const SizedBox(height: 24),
            _buildActionCard(),
            const SizedBox(height: 24),
            _buildStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: const Column(
          children: [
            Icon(Icons.science, size: 60, color: Colors.white),
            SizedBox(height: 12),
            Text(
              'Simulador de Granja Avícola',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Genera datos realistas de 90 días para probar la aplicación',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'Parámetros de Simulación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildParameterRow('Duración', '90 días'),
            _buildParameterRow('Gallinas iniciales', '1,000'),
            _buildParameterRow('Tasa de producción', '85% - 92%'),
            _buildParameterRow('Producción diaria', '850 - 920 huevos'),
            _buildParameterRow('Consumo alimento', '110 - 130 kg/día'),
            _buildParameterRow('Mortalidad', '1-2 gallinas cada 3-5 días'),
            _buildParameterRow('Precio alimento', '3.10 - 3.40 Bs/kg'),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_hasExistingData) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      '$_dataCount días de datos simulados',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runSimulation,
                icon: _isRunning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isRunning ? 'Generando...' : 'Ejecutar Simulación',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esto generará datos para las colecciones: producción, ventas, consumo, mortalidad, gastos e inventario',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_status.isEmpty) return const SizedBox.shrink();

    final isSuccess = _status.contains('completada');
    final isError = _status.contains('Error');

    Color statusColor;
    if (isSuccess) {
      statusColor = Colors.green;
    } else if (isError) {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle
                  : (isError ? Icons.error : Icons.info),
              color: statusColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
