import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/egg_sale_model.dart';
import '../services/sales_service.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final SalesService _salesService = SalesService();
  List<EggSaleModel> _sales = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      List<EggSaleModel> sales = await _salesService.getSalesByUser(user.uid);

      setState(() {
        _sales = sales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Historial de Ventas'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSales),
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
              onPressed: _loadSales,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sell_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay ventas registradas',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra tu primera venta',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSales,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sales.length,
        itemBuilder: (context, index) {
          return _buildSaleCard(_sales[index]);
        },
      ),
    );
  }

  Widget _buildSaleCard(EggSaleModel sale) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFFF8C00),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.sell, color: Colors.white, size: 28),
        ),
        title: Text(
          DateFormat('dd/MM/yyyy', 'es_ES').format(sale.date),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          sale.customer,
          style: const TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Text(
          'Bs ${sale.totalSale.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        children: [
          _buildDetailSection(sale),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () => _showEditDialog(sale),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editar'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF1976D2)),
              ),
              TextButton.icon(
                onPressed: () => _showDeleteConfirmation(sale),
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Eliminar'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Registrado: ${DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(sale.createdAt)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(EggSaleModel sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar la venta del ${DateFormat('dd/MM/yyyy').format(sale.date)} a ${sale.customer}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteSale(sale);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSale(EggSaleModel sale) async {
    setState(() => _isLoading = true);
    try {
      await _salesService.deleteSale(sale.id!);
      await _loadSales();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta eliminada'), backgroundColor: Colors.green),
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

  void _showEditDialog(EggSaleModel sale) {
    showDialog(
      context: context,
      builder: (ctx) => EditSaleDialog(
        sale: sale,
        salesService: _salesService,
        onSave: () => _loadSales(),
      ),
    );
  }

  Widget _buildDetailSection(EggSaleModel sale) {
    final categories = [
      {'label': 'Extra', 'key': 'extra'},
      {'label': 'Especial', 'key': 'especial'},
      {'label': 'Primera', 'key': 'primera'},
      {'label': 'Segunda', 'key': 'segunda'},
      {'label': 'Tercera', 'key': 'tercera'},
      {'label': 'Cuarta', 'key': 'cuarta'},
      {'label': 'Quinta', 'key': 'quinta'},
      {'label': 'Sucios', 'key': 'sucios'},
      {'label': 'Rajados', 'key': 'rajados'},
    ];

    final colorMap = {
      'extra': const Color(0xFF4CAF50),
      'especial': const Color(0xFF8BC34A),
      'primera': const Color(0xFFCDDC39),
      'segunda': const Color(0xFFFFEB3B),
      'tercera': const Color(0xFFFFC107),
      'cuarta': const Color(0xFFFF9800),
      'quinta': const Color(0xFFFF5722),
      'sucios': const Color(0xFF795548),
      'rajados': const Color(0xFF9E9E9E),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'Detalle de la Venta',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...categories.map(
            (category) {
              final key = category['key'] as String;
              final quantityDisplay = sale.getDisplayQuantity(key);
              if (quantityDisplay == '0') return const SizedBox.shrink();
              return _buildDetailRow(
                category['label'] as String,
                quantityDisplay,
                sale.getPrice(key),
                colorMap[key]!,
              );
            },
          ),
          const Divider(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Bs ${sale.totalSale.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String quantityDisplay, double price, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            quantityDisplay,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          Text(
            'Bs/u ${price.toStringAsFixed(2)}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class EditSaleDialog extends StatefulWidget {
  final EggSaleModel sale;
  final SalesService salesService;
  final VoidCallback onSave;

  const EditSaleDialog({
    super.key,
    required this.sale,
    required this.salesService,
    required this.onSave,
  });

  @override
  State<EditSaleDialog> createState() => _EditSaleDialogState();
}

class _EditSaleDialogState extends State<EditSaleDialog> {
  late TextEditingController _customerController;
  late Map<String, TextEditingController> _mountsControllers;
  late Map<String, TextEditingController> _maplesControllers;
  late Map<String, TextEditingController> _unitsControllers;
  late Map<String, TextEditingController> _priceControllers;
  late DateTime _selectedDate;
  bool _isLoading = false;

  static const int MOUNT_EGGS = 300;
  static const int MAPLE_EGGS = 30;

  final List<Map<String, dynamic>> _categories = [
    {'key': 'extra', 'label': 'Extra'},
    {'key': 'especial', 'label': 'Especial'},
    {'key': 'primera', 'label': 'Primera'},
    {'key': 'segunda', 'label': 'Segunda'},
    {'key': 'tercera', 'label': 'Tercera'},
    {'key': 'cuarta', 'label': 'Cuarta'},
    {'key': 'quinta', 'label': 'Quinta'},
    {'key': 'sucios', 'label': 'Sucios'},
    {'key': 'rajados', 'label': 'Rajados'},
  ];

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController(text: widget.sale.customer);
    _selectedDate = widget.sale.date;

    _mountsControllers = {};
    _maplesControllers = {};
    _unitsControllers = {};
    _priceControllers = {};

    for (var category in _categories) {
      String key = category['key'];
      _mountsControllers[key] = TextEditingController(
        text: _getFieldValue(key, 'mounts').toString(),
      );
      _maplesControllers[key] = TextEditingController(
        text: _getFieldValue(key, 'maples').toString(),
      );
      _unitsControllers[key] = TextEditingController(
        text: _getFieldValue(key, 'units').toString(),
      );
      _priceControllers[key] = TextEditingController(
        text: widget.sale.getPrice(key).toString(),
      );
    }
  }

  int _getFieldValue(String key, String type) {
    switch (key) {
      case 'extra': return type == 'mounts' ? widget.sale.extraMounts : (type == 'maples' ? widget.sale.extraMaples : widget.sale.extraUnits);
      case 'especial': return type == 'mounts' ? widget.sale.especialMounts : (type == 'maples' ? widget.sale.especialMaples : widget.sale.especialUnits);
      case 'primera': return type == 'mounts' ? widget.sale.primeraMounts : (type == 'maples' ? widget.sale.primeraMaples : widget.sale.primeraUnits);
      case 'segunda': return type == 'mounts' ? widget.sale.segundaMounts : (type == 'maples' ? widget.sale.segundaMaples : widget.sale.segundaUnits);
      case 'tercera': return type == 'mounts' ? widget.sale.terceraMounts : (type == 'maples' ? widget.sale.terceraMaples : widget.sale.terceraUnits);
      case 'cuarta': return type == 'mounts' ? widget.sale.cuartaMounts : (type == 'maples' ? widget.sale.cuartaMaples : widget.sale.cuartaUnits);
      case 'quinta': return type == 'mounts' ? widget.sale.quintaMounts : (type == 'maples' ? widget.sale.quintaMaples : widget.sale.quintaUnits);
      case 'sucios': return type == 'mounts' ? widget.sale.suciosMounts : (type == 'maples' ? widget.sale.suciosMaples : widget.sale.suciosUnits);
      case 'rajados': return type == 'mounts' ? widget.sale.rajadosMounts : (type == 'maples' ? widget.sale.rajadosMaples : widget.sale.rajadosUnits);
      default: return 0;
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    for (var c in _mountsControllers.values) c.dispose();
    for (var c in _maplesControllers.values) c.dispose();
    for (var c in _unitsControllers.values) c.dispose();
    for (var c in _priceControllers.values) c.dispose();
    super.dispose();
  }

  double get _total {
    double total = 0;
    for (var category in _categories) {
      String key = category['key'];
      int mounts = int.tryParse(_mountsControllers[key]!.text) ?? 0;
      int maples = int.tryParse(_maplesControllers[key]!.text) ?? 0;
      int units = int.tryParse(_unitsControllers[key]!.text) ?? 0;
      double price = double.tryParse(_priceControllers[key]!.text) ?? 0;
      total += (mounts * MOUNT_EGGS + maples * MAPLE_EGGS + units) * price;
    }
    return total;
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      EggSaleModel updated = widget.sale.copyWith(
        customer: _customerController.text,
        date: _selectedDate,
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
        totalSale: _total,
      );

      await widget.salesService.updateSale(updated);

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta actualizada'), backgroundColor: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Venta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Fecha'),
                child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customerController,
              decoration: const InputDecoration(labelText: 'Cliente'),
            ),
            const SizedBox(height: 12),
            const Text('M = Montones, Mz = Maples, U = Unidades', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            ..._categories.map((category) {
              String key = category['key'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(category['label'] as String, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                    ),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _mountsControllers[key],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'M', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _maplesControllers[key],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Mz', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _unitsControllers[key],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'U', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _priceControllers[key],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Bs/u', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Bs ${_total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}