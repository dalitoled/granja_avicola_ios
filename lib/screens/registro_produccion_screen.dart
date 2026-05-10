import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/egg_production_model.dart';
import '../services/production_service.dart';
import '../services/lot_service.dart';

class RegistroProduccionScreen extends StatefulWidget {
  const RegistroProduccionScreen({super.key});

  @override
  State<RegistroProduccionScreen> createState() =>
      _RegistroProduccionScreenState();
}

class _RegistroProduccionScreenState extends State<RegistroProduccionScreen> {
  final ProductionService _productionService = ProductionService();
  final LotService _lotService = LotService();
  final _formKey = GlobalKey<FormState>();
  bool _hasActiveLots = false;
  bool _isLoadingLots = true;

  DateTime _selectedDate = DateTime.now();

  final Map<String, TextEditingController> _unitControllers = {
    'extra': TextEditingController(),
    'especial': TextEditingController(),
    'primera': TextEditingController(),
    'segunda': TextEditingController(),
    'tercera': TextEditingController(),
    'cuarta': TextEditingController(),
    'quinta': TextEditingController(),
    'sucios': TextEditingController(),
    'rajados': TextEditingController(),
    'descarte': TextEditingController(),
  };

  final Map<String, TextEditingController> _mapleControllers = {
    'extra': TextEditingController(),
    'especial': TextEditingController(),
    'primera': TextEditingController(),
    'segunda': TextEditingController(),
    'tercera': TextEditingController(),
    'cuarta': TextEditingController(),
    'quinta': TextEditingController(),
    'sucios': TextEditingController(),
    'rajados': TextEditingController(),
    'descarte': TextEditingController(),
  };

  final Map<String, TextEditingController> _mountControllers = {
    'extra': TextEditingController(),
    'especial': TextEditingController(),
    'primera': TextEditingController(),
    'segunda': TextEditingController(),
    'tercera': TextEditingController(),
    'cuarta': TextEditingController(),
    'quinta': TextEditingController(),
    'sucios': TextEditingController(),
    'rajados': TextEditingController(),
    'descarte': TextEditingController(),
  };

  bool _isLoading = false;
  int _totalHuevos = 0;

  final List<Map<String, dynamic>> _categories = [
    {'key': 'extra', 'label': 'Extra', 'color': const Color(0xFF4CAF50)},
    {'key': 'especial', 'label': 'Especial', 'color': const Color(0xFF8BC34A)},
    {'key': 'primera', 'label': 'Primera', 'color': const Color(0xFFCDDC39)},
    {'key': 'segunda', 'label': 'Segunda', 'color': const Color(0xFFFFEB3B)},
    {'key': 'tercera', 'label': 'Tercera', 'color': const Color(0xFFFFC107)},
    {'key': 'cuarta', 'label': 'Cuarta', 'color': const Color(0xFFFF9800)},
    {'key': 'quinta', 'label': 'Quinta', 'color': const Color(0xFFFF5722)},
    {'key': 'sucios', 'label': 'Sucios', 'color': const Color(0xFF795548)},
    {'key': 'rajados', 'label': 'Rajados', 'color': const Color(0xFF9E9E9E)},
    {'key': 'descarte', 'label': 'Descarte', 'color': const Color(0xFF607D8B)},
  ];

  static const int MAPLE_EGGS = 30;
  static const int MOUNT_MAPLES = 10;
  static const int MOUNT_EGGS = MAPLE_EGGS * MOUNT_MAPLES;

  @override
  void initState() {
    super.initState();
    for (var controller in _unitControllers.values) {
      controller.addListener(_calculateTotal);
    }
    for (var controller in _mapleControllers.values) {
      controller.addListener(_calculateTotal);
    }
    for (var controller in _mountControllers.values) {
      controller.addListener(_calculateTotal);
    }
    _checkActiveLots();
  }

  Future<void> _checkActiveLots() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    bool hasLots = await _lotService.hasActiveLots(user.uid);
    if (mounted) {
      setState(() {
        _hasActiveLots = hasLots;
        _isLoadingLots = false;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _unitControllers.values) {
      controller.removeListener(_calculateTotal);
      controller.dispose();
    }
    for (var controller in _mapleControllers.values) {
      controller.removeListener(_calculateTotal);
      controller.dispose();
    }
    for (var controller in _mountControllers.values) {
      controller.removeListener(_calculateTotal);
      controller.dispose();
    }
    super.dispose();
  }

  void _calculateTotal() {
    int total = 0;
    for (var key in _unitControllers.keys) {
      final units = int.tryParse(_unitControllers[key]!.text) ?? 0;
      final maples = int.tryParse(_mapleControllers[key]!.text) ?? 0;
      final mounts = int.tryParse(_mountControllers[key]!.text) ?? 0;
      total += units + (maples * MAPLE_EGGS) + (mounts * MOUNT_EGGS);
    }
    setState(() {
      _totalHuevos = total;
    });
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  int _getUnits(String key) => int.tryParse(_unitControllers[key]!.text) ?? 0;
  int _getMaples(String key) => int.tryParse(_mapleControllers[key]!.text) ?? 0;
  int _getMounts(String key) => int.tryParse(_mountControllers[key]!.text) ?? 0;

  Future<void> _saveProduction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_totalHuevos == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes ingresar al menos algunos huevos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      EggProductionModel production = EggProductionModel(
        userId: user.uid,
        date: _selectedDate,
        extra: _getUnits('extra'),
        especial: _getUnits('especial'),
        primera: _getUnits('primera'),
        segunda: _getUnits('segunda'),
        tercera: _getUnits('tercera'),
        cuarta: _getUnits('cuarta'),
        quinta: _getUnits('quinta'),
        sucios: _getUnits('sucios'),
        rajados: _getUnits('rajados'),
        descarte: _getUnits('descarte'),
        totalHuevos: _totalHuevos,
        createdAt: DateTime.now(),
        extraMaples: _getMaples('extra'),
        especialMaples: _getMaples('especial'),
        primeraMaples: _getMaples('primera'),
        segundaMaples: _getMaples('segunda'),
        terceraMaples: _getMaples('tercera'),
        cuartaMaples: _getMaples('cuarta'),
        quintaMaples: _getMaples('quinta'),
        suciosMaples: _getMaples('sucios'),
        rajadosMaples: _getMaples('rajados'),
        descarteMaples: _getMaples('descarte'),
        extraMounts: _getMounts('extra'),
        especialMounts: _getMounts('especial'),
        primeraMounts: _getMounts('primera'),
        segundaMounts: _getMounts('segunda'),
        terceraMounts: _getMounts('tercera'),
        cuartaMounts: _getMounts('cuarta'),
        quintaMounts: _getMounts('quinta'),
        suciosMounts: _getMounts('sucios'),
        rajadosMounts: _getMounts('rajados'),
        descarteMounts: _getMounts('descarte'),
      );

      await _productionService.addProduction(production);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producción guardada: $_totalHuevos huevos'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    for (var controller in _unitControllers.values) {
      controller.clear();
    }
    for (var controller in _mapleControllers.values) {
      controller.clear();
    }
    for (var controller in _mountControllers.values) {
      controller.clear();
    }
    setState(() {
      _selectedDate = DateTime.now();
      _totalHuevos = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLots) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5DC),
        appBar: AppBar(
          title: const Text('Registro de Producción'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasActiveLots) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5DC),
        appBar: AppBar(
          title: const Text('Registro de Producción'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: _buildNoLotMessage(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Registro de Producción'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateCard(),
                const SizedBox(height: 16),
                _buildCategoriesCard(),
                const SizedBox(height: 16),
                _buildTotalCard(),
                const SizedBox(height: 24),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateCard() {
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
                Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'Fecha de Producción',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy', 'es_ES').format(_selectedDate),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesCard() {
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
                Icon(Icons.egg, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Huevos por Categoría',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ingresa mounts y/o unidades para cada categoría',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '1 maple = $MAPLE_EGGS huevos | 1 monton = $MOUNT_MAPLES maples = $MOUNT_EGGS huevos',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            ..._categories.map((cat) => _buildCategoryRow(
              cat['key'] as String,
              cat['label'] as String,
              cat['color'] as Color,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(String key, String label, Color color) {
    final units = _getUnits(key);
    final maples = _getMaples(key);
    final mounts = _getMounts(key);
    final total = units + (maples * MAPLE_EGGS) + (mounts * MOUNT_EGGS);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total huevos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _mountControllers[key],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Montón',
                    labelStyle: TextStyle(
                      color: color,
                      fontSize: 10,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _mapleControllers[key],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Maples',
                    labelStyle: TextStyle(
                      color: color,
                      fontSize: 10,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '+',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _unitControllers[key],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Unidades',
                    labelStyle: TextStyle(
                      color: color,
                      fontSize: 10,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          if (maples > 0 || mounts > 0 || units > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _buildCalculationText(maples, mounts, units),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _buildCalculationText(int maples, int mounts, int units) {
    final fromMaples = maples * MAPLE_EGGS;
    final fromMounts = mounts * MOUNT_EGGS;
    final parts = <String>[];
    if (mounts > 0) parts.add('$mounts×$MOUNT_EGGS=$fromMounts');
    if (maples > 0) parts.add('$maples×$MAPLE_EGGS=$fromMaples');
    if (units > 0) parts.add('$units');
    return parts.join(' + ');
  }

  Widget _buildTotalCard() {
    return Card(
      elevation: 4,
      color: const Color(0xFF2E7D32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total de Huevos:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              _totalHuevos.toString(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProduction,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Guardar Producción',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildNoLotMessage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 80,
            color: Colors.orange[700],
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay lotes activos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Para registrar producción, necesitas tener al menos un lote de gallinas activo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver al Dashboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
