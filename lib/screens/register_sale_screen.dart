import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/egg_sale_model.dart';
import '../services/sales_service.dart';
import '../services/lot_service.dart';
import 'create_lot_screen.dart';

class RegisterSaleScreen extends StatefulWidget {
  const RegisterSaleScreen({super.key});

  @override
  State<RegisterSaleScreen> createState() => _RegisterSaleScreenState();
}

class _RegisterSaleScreenState extends State<RegisterSaleScreen> {
  final SalesService _salesService = SalesService();
  final LotService _lotService = LotService();
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  final _customerController = TextEditingController();

  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};

  bool _isLoading = false;
  bool _isCheckingLots = true;
  double _totalSale = 0;
  bool _isByMount = false;

  static const double MOUNT_EGGS = 300;

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
  ];

  @override
  void initState() {
    super.initState();
    _checkActiveLots();
    for (var category in _categories) {
      _quantityControllers[category['key']] = TextEditingController();
      _priceControllers[category['key']] = TextEditingController();
      _quantityControllers[category['key']]!.addListener(_calculateTotal);
      _priceControllers[category['key']]!.addListener(_calculateTotal);
    }
  }

  Future<void> _checkActiveLots() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    bool hasLots = await _lotService.hasActiveLots(user.uid);
    if (!hasLots && mounted) {
      setState(() => _isCheckingLots = false);
    } else {
      if (mounted) {
        setState(() => _isCheckingLots = false);
      }
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _calculateTotal() {
    double total = 0;
    for (var category in _categories) {
      String key = category['key'];
      double quantity = double.tryParse(_quantityControllers[key]!.text) ?? 0;
      double price = double.tryParse(_priceControllers[key]!.text) ?? 0;
      
      total += quantity * price;
    }
    setState(() {
      _totalSale = total;
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

  double _getSubtotal(String key) {
    double quantity = double.tryParse(_quantityControllers[key]!.text) ?? 0;
    double price = double.tryParse(_priceControllers[key]!.text) ?? 0;
    return quantity * price;
  }

  double _getQuantity(String key) {
    double quantity = double.tryParse(_quantityControllers[key]!.text) ?? 0;
    return quantity;
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      EggSaleModel sale = EggSaleModel(
        userId: user.uid,
        date: _selectedDate,
        customer: _customerController.text.trim(),
        extraQuantity: _isByMount ? (_getQuantity('extra') * MOUNT_EGGS).toInt() : _getQuantity('extra').toInt(),
        extraPrice: double.tryParse(_priceControllers['extra']!.text) ?? 0,
        especialQuantity: _isByMount ? (_getQuantity('especial') * MOUNT_EGGS).toInt() : _getQuantity('especial').toInt(),
        especialPrice: double.tryParse(_priceControllers['especial']!.text) ?? 0,
        primeraQuantity: _isByMount ? (_getQuantity('primera') * MOUNT_EGGS).toInt() : _getQuantity('primera').toInt(),
        primeraPrice: double.tryParse(_priceControllers['primera']!.text) ?? 0,
        segundaQuantity: _isByMount ? (_getQuantity('segunda') * MOUNT_EGGS).toInt() : _getQuantity('segunda').toInt(),
        segundaPrice: double.tryParse(_priceControllers['segunda']!.text) ?? 0,
        terceraQuantity: _isByMount ? (_getQuantity('tercera') * MOUNT_EGGS).toInt() : _getQuantity('tercera').toInt(),
        terceraPrice: double.tryParse(_priceControllers['tercera']!.text) ?? 0,
        cuartaQuantity: _isByMount ? (_getQuantity('cuarta') * MOUNT_EGGS).toInt() : _getQuantity('cuarta').toInt(),
        cuartaPrice: double.tryParse(_priceControllers['cuarta']!.text) ?? 0,
        quintaQuantity: _isByMount ? (_getQuantity('quinta') * MOUNT_EGGS).toInt() : _getQuantity('quinta').toInt(),
        quintaPrice: double.tryParse(_priceControllers['quinta']!.text) ?? 0,
        suciosQuantity: _isByMount ? (_getQuantity('sucios') * MOUNT_EGGS).toInt() : _getQuantity('sucios').toInt(),
        suciosPrice: double.tryParse(_priceControllers['sucios']!.text) ?? 0,
        rajadosQuantity: _isByMount ? (_getQuantity('rajados') * MOUNT_EGGS).toInt() : _getQuantity('rajados').toInt(),
        rajadosPrice: double.tryParse(_priceControllers['rajados']!.text) ?? 0,
        totalSale: _totalSale,
        createdAt: DateTime.now(),
        isByMount: _isByMount,
      );

      final calculatedTotal = sale.calculateTotal();

      await _salesService.addSale(sale.copyWith(totalSale: calculatedTotal));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venta guardada exitosamente'),
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
    _customerController.clear();
    for (var controller in _quantityControllers.values) {
      controller.clear();
    }
    for (var controller in _priceControllers.values) {
      controller.clear();
    }
    setState(() {
      _selectedDate = DateTime.now();
      _totalSale = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLots) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5DC),
        appBar: AppBar(
          title: const Text('Registrar Venta'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Registrar Venta'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: _lotService.hasActiveLots(FirebaseAuth.instance.currentUser!.uid),
          builder: (context, snapshot) {
            final hasLots = snapshot.data ?? false;
            if (!hasLots) {
              return _buildNoLotMessage();
            }
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateCard(),
                    const SizedBox(height: 16),
                    _buildCustomerCard(),
                    const SizedBox(height: 16),
                    _buildCategoriesCard(),
                    const SizedBox(height: 16),
                    _buildTotalCard(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            );
          },
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
              'Para registrar ventas, primero debe crear un lote de gallinas.',
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
                  setState(() {});
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
                  'Fecha de Venta',
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

  Widget _buildCustomerCard() {
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
                Icon(Icons.person, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'Datos del Cliente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerController,
              decoration: InputDecoration(
                labelText: 'Nombre del cliente',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingrese el nombre del cliente';
                }
                return null;
              },
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
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tipo de registro:', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Unidades', style: TextStyle(fontSize: 12)),
                        selected: !_isByMount,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _isByMount = false;
                              _calculateTotal();
                            });
                          }
                        },
                        selectedColor: const Color(0xFF2E7D32),
                        labelStyle: TextStyle(
                          color: !_isByMount ? Colors.white : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                      ChoiceChip(
                        label: const Text('Montones', style: TextStyle(fontSize: 12)),
                        selected: _isByMount,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _isByMount = true;
                              _calculateTotal();
                            });
                          }
                        },
                        selectedColor: const Color(0xFF2E7D32),
                        labelStyle: TextStyle(
                          color: _isByMount ? Colors.white : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_isByMount)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '1 montón = 10 maples de 30 huevos = $MOUNT_EGGS huevos',
                        style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ..._categories.map((category) => _buildCategoryRow(category)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(Map<String, dynamic> category) {
    String key = category['key'];
    String label = category['label'];
    Color color = category['color'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantityControllers[key],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: _isByMount ? 'Montones' : 'Cant.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextFormField(
                  controller: _priceControllers[key],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _isByMount ? 'Precio/Montón' : 'Precio und.',
                    prefixText: 'Bs ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bs ${_getSubtotal(key).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
              'Total Venta:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Bs ${_totalSale.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 28,
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
        onPressed: _isLoading ? null : _saveSale,
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
                    'Guardar Venta',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
