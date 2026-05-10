import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/egg_sale_model.dart';
import '../services/sales_service.dart';
import '../services/lot_service.dart';
import '../utils/responsive.dart';
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

  final Map<String, TextEditingController> _mountsControllers = {};
  final Map<String, TextEditingController> _maplesControllers = {};
  final Map<String, TextEditingController> _unitsControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};

  bool _isLoading = false;
  bool _isCheckingLots = true;
  double _totalSale = 0;

  static const int MOUNT_EGGS = 300;
  static const int MAPLE_EGGS = 30;

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
      String key = category['key'];
      _mountsControllers[key] = TextEditingController();
      _maplesControllers[key] = TextEditingController();
      _unitsControllers[key] = TextEditingController();
      _priceControllers[key] = TextEditingController();
      
      _mountsControllers[key]!.addListener(_calculateTotal);
      _maplesControllers[key]!.addListener(_calculateTotal);
      _unitsControllers[key]!.addListener(_calculateTotal);
      _priceControllers[key]!.addListener(_calculateTotal);
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
    for (var controller in _mountsControllers.values) {
      controller.dispose();
    }
    for (var controller in _maplesControllers.values) {
      controller.dispose();
    }
    for (var controller in _unitsControllers.values) {
      controller.dispose();
    }
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _getTotalUnits(String key) {
    int mounts = int.tryParse(_mountsControllers[key]!.text) ?? 0;
    int maples = int.tryParse(_maplesControllers[key]!.text) ?? 0;
    int units = int.tryParse(_unitsControllers[key]!.text) ?? 0;
    return mounts * MOUNT_EGGS + maples * MAPLE_EGGS + units;
  }

  void _calculateTotal() {
    double total = 0;
    for (var category in _categories) {
      String key = category['key'];
      int totalUnits = _getTotalUnits(key);
      double price = double.tryParse(_priceControllers[key]!.text) ?? 0;
      total += totalUnits * price;
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
    int totalUnits = _getTotalUnits(key);
    double price = double.tryParse(_priceControllers[key]!.text) ?? 0;
    return totalUnits * price;
  }

  String _getQuantityDisplay(String key) {
    int mounts = int.tryParse(_mountsControllers[key]!.text) ?? 0;
    int maples = int.tryParse(_maplesControllers[key]!.text) ?? 0;
    int units = int.tryParse(_unitsControllers[key]!.text) ?? 0;
    
    int totalUnits = mounts * MOUNT_EGGS + maples * MAPLE_EGGS + units;
    
    List<String> parts = [];
    if (mounts > 0) parts.add('$mounts Mo');
    if (maples > 0) parts.add('$maples Ma');
    if (units > 0) parts.add('$units U');
    
    return parts.isEmpty ? '0 ($totalUnits u)' : '${parts.join(' + ')} ($totalUnits u)';
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
        extraMounts: int.tryParse(_mountsControllers['extra']!.text) ?? 0,
        extraMaples: int.tryParse(_maplesControllers['extra']!.text) ?? 0,
        extraUnits: int.tryParse(_unitsControllers['extra']!.text) ?? 0,
        extraPrice: double.tryParse(_priceControllers['extra']!.text) ?? 0,
        especialMounts: int.tryParse(_mountsControllers['especial']!.text) ?? 0,
        especialMaples: int.tryParse(_maplesControllers['especial']!.text) ?? 0,
        especialUnits: int.tryParse(_unitsControllers['especial']!.text) ?? 0,
        especialPrice: double.tryParse(_priceControllers['especial']!.text) ?? 0,
        primeraMounts: int.tryParse(_mountsControllers['primera']!.text) ?? 0,
        primeraMaples: int.tryParse(_maplesControllers['primera']!.text) ?? 0,
        primeraUnits: int.tryParse(_unitsControllers['primera']!.text) ?? 0,
        primeraPrice: double.tryParse(_priceControllers['primera']!.text) ?? 0,
        segundaMounts: int.tryParse(_mountsControllers['segunda']!.text) ?? 0,
        segundaMaples: int.tryParse(_maplesControllers['segunda']!.text) ?? 0,
        segundaUnits: int.tryParse(_unitsControllers['segunda']!.text) ?? 0,
        segundaPrice: double.tryParse(_priceControllers['segunda']!.text) ?? 0,
        terceraMounts: int.tryParse(_mountsControllers['tercera']!.text) ?? 0,
        terceraMaples: int.tryParse(_maplesControllers['tercera']!.text) ?? 0,
        terceraUnits: int.tryParse(_unitsControllers['tercera']!.text) ?? 0,
        terceraPrice: double.tryParse(_priceControllers['tercera']!.text) ?? 0,
        cuartaMounts: int.tryParse(_mountsControllers['cuarta']!.text) ?? 0,
        cuartaMaples: int.tryParse(_maplesControllers['cuarta']!.text) ?? 0,
        cuartaUnits: int.tryParse(_unitsControllers['cuarta']!.text) ?? 0,
        cuartaPrice: double.tryParse(_priceControllers['cuarta']!.text) ?? 0,
        quintaMounts: int.tryParse(_mountsControllers['quinta']!.text) ?? 0,
        quintaMaples: int.tryParse(_maplesControllers['quinta']!.text) ?? 0,
        quintaUnits: int.tryParse(_unitsControllers['quinta']!.text) ?? 0,
        quintaPrice: double.tryParse(_priceControllers['quinta']!.text) ?? 0,
        suciosMounts: int.tryParse(_mountsControllers['sucios']!.text) ?? 0,
        suciosMaples: int.tryParse(_maplesControllers['sucios']!.text) ?? 0,
        suciosUnits: int.tryParse(_unitsControllers['sucios']!.text) ?? 0,
        suciosPrice: double.tryParse(_priceControllers['sucios']!.text) ?? 0,
        rajadosMounts: int.tryParse(_mountsControllers['rajados']!.text) ?? 0,
        rajadosMaples: int.tryParse(_maplesControllers['rajados']!.text) ?? 0,
        rajadosUnits: int.tryParse(_unitsControllers['rajados']!.text) ?? 0,
        rajadosPrice: double.tryParse(_priceControllers['rajados']!.text) ?? 0,
        totalSale: _totalSale,
        createdAt: DateTime.now(),
      );

      await _salesService.addSale(sale);

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
    for (var key in _mountsControllers.keys) {
      _mountsControllers[key]!.clear();
      _maplesControllers[key]!.clear();
      _unitsControllers[key]!.clear();
      _priceControllers[key]!.clear();
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
                padding: Responsive.responsivePadding(context),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.cardRadius(context))),
      child: Padding(
        padding: EdgeInsets.all(Responsive.responsiveValue(context, mobile: 12, tablet: 16, desktop: 20)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.cardRadius(context))),
      child: Padding(
        padding: EdgeInsets.all(Responsive.responsiveValue(context, mobile: 12, tablet: 16, desktop: 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: const Color(0xFF2E7D32), size: Responsive.subtitleSize(context)),
                SizedBox(width: Responsive.responsiveValue(context, mobile: 6, tablet: 8, desktop: 12)),
                Text(
                  'Datos del Cliente',
                  style: TextStyle(
                    fontSize: Responsive.subtitleSize(context),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.responsiveValue(context, mobile: 8, tablet: 12, desktop: 16)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.cardRadius(context))),
      child: Padding(
        padding: EdgeInsets.all(Responsive.responsiveValue(context, mobile: 12, tablet: 16, desktop: 20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.egg, color: const Color(0xFF2E7D32), size: Responsive.subtitleSize(context)),
                SizedBox(width: Responsive.responsiveValue(context, mobile: 6, tablet: 8, desktop: 12)),
                Text(
                  'Categorías de Huevos',
                  style: TextStyle(
                    fontSize: Responsive.subtitleSize(context),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.responsiveValue(context, mobile: 8, tablet: 12, desktop: 16)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(Responsive.responsiveValue(context, mobile: 8, tablet: 12, desktop: 16)),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info, color: Color(0xFF2E7D32), size: 18),
                      SizedBox(width: Responsive.responsiveValue(context, mobile: 4, tablet: 8, desktop: 12)),
                      Expanded(
                        child: Text(
                          '1 Montón = 10 Maples = 300 huevos | 1 Maple = 30 huevos',
                          style: TextStyle(fontSize: Responsive.smallSize(context), color: const Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
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
      margin: EdgeInsets.only(bottom: Responsive.responsiveValue(context, mobile: 12, tablet: 16, desktop: 20)),
      padding: EdgeInsets.all(Responsive.responsiveValue(context, mobile: 10, tablet: 14, desktop: 16)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Responsive.cardRadius(context)),
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
                  fontSize: Responsive.subtitleSize(context),
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                _getQuantityDisplay(key),
                style: TextStyle(
                  fontSize: Responsive.smallSize(context),
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: Responsive.isMobile(context) ? 55 : 70,
                child: TextFormField(
                  controller: _mountsControllers[key],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(fontSize: Responsive.smallSize(context)),
                  decoration: InputDecoration(
                    labelText: 'Mo',
                    hintText: '0',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  ),
                ),
              ),
              SizedBox(width: Responsive.isMobile(context) ? 3 : 6),
              SizedBox(
                width: Responsive.isMobile(context) ? 55 : 70,
                child: TextFormField(
                  controller: _maplesControllers[key],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(fontSize: Responsive.smallSize(context)),
                  decoration: InputDecoration(
                    labelText: 'Ma',
                    hintText: '0',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  ),
                ),
              ),
              SizedBox(width: Responsive.isMobile(context) ? 3 : 6),
              SizedBox(
                width: Responsive.isMobile(context) ? 55 : 70,
                child: TextFormField(
                  controller: _unitsControllers[key],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(fontSize: Responsive.smallSize(context)),
                  decoration: InputDecoration(
                    labelText: 'U',
                    hintText: '0',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  ),
                ),
              ),
              SizedBox(width: Responsive.isMobile(context) ? 4 : 8),
              Expanded(
                child: TextFormField(
                  controller: _priceControllers[key],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: Responsive.smallSize(context)),
                  decoration: InputDecoration(
                    labelText: 'Bs/u',
                    prefixText: 'Bs ',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
              SizedBox(width: Responsive.isMobile(context) ? 4 : 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.isMobile(context) ? 6 : 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bs ${_getSubtotal(key).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.smallSize(context),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.cardRadius(context))),
      child: Padding(
        padding: EdgeInsets.all(Responsive.responsiveValue(context, mobile: 16, tablet: 20, desktop: 24)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Venta:',
              style: TextStyle(
                fontSize: Responsive.subtitleSize(context),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Bs ${_totalSale.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: Responsive.titleSize(context),
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
      height: Responsive.responsiveValue(context, mobile: 50, tablet: 56, desktop: 60),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveSale,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8C00),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.cardRadius(context)),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, size: Responsive.responsiveValue(context, mobile: 20, tablet: 24, desktop: 28)),
                  SizedBox(width: Responsive.responsiveValue(context, mobile: 6, tablet: 8, desktop: 12)),
                  Text(
                    'Guardar Venta',
                    style: TextStyle(
                      fontSize: Responsive.subtitleSize(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}