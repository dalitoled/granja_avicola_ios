import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/egg_production_model.dart';
import '../services/production_service.dart';
import '../services/lot_service.dart';
import 'create_lot_screen.dart';

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

  final Map<String, TextEditingController> _controllers = {
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

  @override
  void initState() {
    super.initState();
    for (var controller in _controllers.values) {
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
    for (var controller in _controllers.values) {
      controller.removeListener(_calculateTotal);
      controller.dispose();
    }
    super.dispose();
  }

  void _calculateTotal() {
    int total = 0;
    for (var controller in _controllers.values) {
      final value = int.tryParse(controller.text) ?? 0;
      total += value;
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

  Future<void> _saveProduction() async {
    if (!_formKey.currentState!.validate()) return;

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
        extra: int.tryParse(_controllers['extra']!.text) ?? 0,
        especial: int.tryParse(_controllers['especial']!.text) ?? 0,
        primera: int.tryParse(_controllers['primera']!.text) ?? 0,
        segunda: int.tryParse(_controllers['segunda']!.text) ?? 0,
        tercera: int.tryParse(_controllers['tercera']!.text) ?? 0,
        cuarta: int.tryParse(_controllers['cuarta']!.text) ?? 0,
        quinta: int.tryParse(_controllers['quinta']!.text) ?? 0,
        sucios: int.tryParse(_controllers['sucios']!.text) ?? 0,
        rajados: int.tryParse(_controllers['rajados']!.text) ?? 0,
        descarte: int.tryParse(_controllers['descarte']!.text) ?? 0,
        totalHuevos: _totalHuevos,
        createdAt: DateTime.now(),
      );

      await _productionService.addProduction(production);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producción guardada exitosamente'),
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
    for (var controller in _controllers.values) {
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
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Color(0xFF2E7D32),
                            ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                    'es_ES',
                                  ).format(_selectedDate),
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
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.egg, color: Color(0xFF2E7D32)),
                            SizedBox(width: 8),
                            Text(
                              'Categorías de Huevos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return _buildInputField(
                              category['key'],
                              category['label'],
                              category['color'],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  color: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProduction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Guardar Producción',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoLotMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'No hay lotes activos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Para registrar producción, primero debe crear un lote de gallinas.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateLotScreen()),
                ).then((_) {
                  _checkActiveLots();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear Lote'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String key, String label, Color color) {
    return TextFormField(
      controller: _controllers[key],
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return null;
        }
        return null;
      },
    );
  }
}
