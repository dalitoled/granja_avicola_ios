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

  double _getCalculatedTotal(EggSaleModel sale) {
    if (sale.isByMount) {
      return (sale.extraQuantity * sale.extraPrice / EggSaleModel.MOUNT_EGGS) +
          (sale.especialQuantity * sale.especialPrice / EggSaleModel.MOUNT_EGGS) +
          (sale.primeraQuantity * sale.primeraPrice / EggSaleModel.MOUNT_EGGS) +
          (sale.segundaQuantity * sale.segundaPrice / EggSaleModel.MOUNT_EGGS) +
          (sale.terceraQuantity * sale.terceraPrice / EggSaleModel.MOUNT_EGGS) +
          (sale.cuartaQuantity * sale.cuartaPrice / EggSaleModel.MOUNT_EGGS) +
          (sale.quintaQuantity * sale.quintaPrice / EggSaleModel.MOUNT_EGGS) +
          (sale.suciosQuantity * sale.suciosPrice / EggSaleModel.MOUNT_EGGS) +
          (sale.rajadosQuantity * sale.rajadosPrice / EggSaleModel.MOUNT_EGGS);
    }
    return sale.totalSale;
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
      {
        'label': 'Extra',
        'quantity': sale.extraQuantity,
        'price': sale.extraPrice,
      },
      {
        'label': 'Especial',
        'quantity': sale.especialQuantity,
        'price': sale.especialPrice,
      },
      {
        'label': 'Primera',
        'quantity': sale.primeraQuantity,
        'price': sale.primeraPrice,
      },
      {
        'label': 'Segunda',
        'quantity': sale.segundaQuantity,
        'price': sale.segundaPrice,
      },
      {
        'label': 'Tercera',
        'quantity': sale.terceraQuantity,
        'price': sale.terceraPrice,
      },
      {
        'label': 'Cuarta',
        'quantity': sale.cuartaQuantity,
        'price': sale.cuartaPrice,
      },
      {
        'label': 'Quinta',
        'quantity': sale.quintaQuantity,
        'price': sale.quintaPrice,
      },
      {
        'label': 'Sucios',
        'quantity': sale.suciosQuantity,
        'price': sale.suciosPrice,
      },
      {
        'label': 'Rajados',
        'quantity': sale.rajadosQuantity,
        'price': sale.rajadosPrice,
      },
    ];

    final isByMount = sale.isByMount;
    final mountLabel = isByMount ? 'montón(es)' : 'huevo(s)';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Detalle de la Venta${isByMount ? ' (Por Montones)' : ''}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...categories
              .where((c) => (c['quantity'] as int) >= 0)
              .map(
                (category) => _buildDetailRow(
                  category['label'] as String,
                  category['quantity'] as int,
                  category['price'] as double,
                  isByMount,
                ),
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
                  'Bs ${_getCalculatedTotal(sale).toStringAsFixed(2)}',
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

  Widget _buildDetailRow(String label, int quantity, double price, bool isByMount) {
    final displayQty = isByMount ? quantity / EggSaleModel.MOUNT_EGGS : quantity.toDouble();
    final displayUnit = isByMount ? 'montón' : 'huevo';
    final priceLabel = isByMount ? 'Bs/montón' : 'Bs/huevo';
    final subtotal = isByMount ? (quantity * price / EggSaleModel.MOUNT_EGGS) : (quantity * price);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${displayQty.toStringAsFixed(2)} $displayUnit x $priceLabel: ${price.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity( 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Bs ${subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
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
  late TextEditingController _extraQtyController;
  late TextEditingController _extraPriceController;
  late TextEditingController _especialQtyController;
  late TextEditingController _especialPriceController;
  late TextEditingController _primeraQtyController;
  late TextEditingController _primeraPriceController;
  late TextEditingController _segundaQtyController;
  late TextEditingController _segundaPriceController;
  late TextEditingController _terceraQtyController;
  late TextEditingController _terceraPriceController;
  late TextEditingController _cuartaQtyController;
  late TextEditingController _cuartaPriceController;
  late TextEditingController _quintaQtyController;
  late TextEditingController _quintaPriceController;
  late TextEditingController _suciosQtyController;
  late TextEditingController _suciosPriceController;
  late TextEditingController _rajadosQtyController;
  late TextEditingController _rajadosPriceController;
  late DateTime _selectedDate;
  late bool _isByMount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController(text: widget.sale.customer);
    _extraQtyController = TextEditingController(text: widget.sale.extraQuantity.toString());
    _extraPriceController = TextEditingController(text: widget.sale.extraPrice.toString());
    _especialQtyController = TextEditingController(text: widget.sale.especialQuantity.toString());
    _especialPriceController = TextEditingController(text: widget.sale.especialPrice.toString());
    _primeraQtyController = TextEditingController(text: widget.sale.primeraQuantity.toString());
    _primeraPriceController = TextEditingController(text: widget.sale.primeraPrice.toString());
    _segundaQtyController = TextEditingController(text: widget.sale.segundaQuantity.toString());
    _segundaPriceController = TextEditingController(text: widget.sale.segundaPrice.toString());
    _terceraQtyController = TextEditingController(text: widget.sale.terceraQuantity.toString());
    _terceraPriceController = TextEditingController(text: widget.sale.terceraPrice.toString());
    _cuartaQtyController = TextEditingController(text: widget.sale.cuartaQuantity.toString());
    _cuartaPriceController = TextEditingController(text: widget.sale.cuartaPrice.toString());
    _quintaQtyController = TextEditingController(text: widget.sale.quintaQuantity.toString());
    _quintaPriceController = TextEditingController(text: widget.sale.quintaPrice.toString());
    _suciosQtyController = TextEditingController(text: widget.sale.suciosQuantity.toString());
    _suciosPriceController = TextEditingController(text: widget.sale.suciosPrice.toString());
    _rajadosQtyController = TextEditingController(text: widget.sale.rajadosQuantity.toString());
    _rajadosPriceController = TextEditingController(text: widget.sale.rajadosPrice.toString());
    _selectedDate = widget.sale.date;
    _isByMount = widget.sale.isByMount;
  }

  @override
  void dispose() {
    _customerController.dispose();
    _extraQtyController.dispose();
    _extraPriceController.dispose();
    _especialQtyController.dispose();
    _especialPriceController.dispose();
    _primeraQtyController.dispose();
    _primeraPriceController.dispose();
    _segundaQtyController.dispose();
    _segundaPriceController.dispose();
    _terceraQtyController.dispose();
    _terceraPriceController.dispose();
    _cuartaQtyController.dispose();
    _cuartaPriceController.dispose();
    _quintaQtyController.dispose();
    _quintaPriceController.dispose();
    _suciosQtyController.dispose();
    _suciosPriceController.dispose();
    _rajadosQtyController.dispose();
    _rajadosPriceController.dispose();
    super.dispose();
  }

  double get _total {
    if (_isByMount) {
      return (_getQtyAsDouble(_extraQtyController) * _getPrice(_extraPriceController)) +
          (_getQtyAsDouble(_especialQtyController) * _getPrice(_especialPriceController)) +
          (_getQtyAsDouble(_primeraQtyController) * _getPrice(_primeraPriceController)) +
          (_getQtyAsDouble(_segundaQtyController) * _getPrice(_segundaPriceController)) +
          (_getQtyAsDouble(_terceraQtyController) * _getPrice(_terceraPriceController)) +
          (_getQtyAsDouble(_cuartaQtyController) * _getPrice(_cuartaPriceController)) +
          (_getQtyAsDouble(_quintaQtyController) * _getPrice(_quintaPriceController)) +
          (_getQtyAsDouble(_suciosQtyController) * _getPrice(_suciosPriceController)) +
          (_getQtyAsDouble(_rajadosQtyController) * _getPrice(_rajadosPriceController));
    }
    return (_getQty(_extraQtyController) * _getPrice(_extraPriceController)) +
        (_getQty(_especialQtyController) * _getPrice(_especialPriceController)) +
        (_getQty(_primeraQtyController) * _getPrice(_primeraPriceController)) +
        (_getQty(_segundaQtyController) * _getPrice(_segundaPriceController)) +
        (_getQty(_terceraQtyController) * _getPrice(_terceraPriceController)) +
        (_getQty(_cuartaQtyController) * _getPrice(_cuartaPriceController)) +
        (_getQty(_quintaQtyController) * _getPrice(_quintaPriceController)) +
        (_getQty(_suciosQtyController) * _getPrice(_suciosPriceController)) +
        (_getQty(_rajadosQtyController) * _getPrice(_rajadosPriceController));
  }

  int _getQty(TextEditingController controller) => int.tryParse(controller.text) ?? 0;
  double _getPrice(TextEditingController controller) => double.tryParse(controller.text) ?? 0;
  double _getQtyAsDouble(TextEditingController controller) => double.tryParse(controller.text) ?? 0;
  
  int _getQtyAsEggs(TextEditingController controller) {
    if (_isByMount) {
      return ((double.tryParse(controller.text) ?? 0) * EggSaleModel.MOUNT_EGGS).toInt();
    }
    return int.tryParse(controller.text) ?? 0;
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
        extraQuantity: _getQtyAsEggs(_extraQtyController),
        extraPrice: _getPrice(_extraPriceController),
        especialQuantity: _getQtyAsEggs(_especialQtyController),
        especialPrice: _getPrice(_especialPriceController),
        primeraQuantity: _getQtyAsEggs(_primeraQtyController),
        primeraPrice: _getPrice(_primeraPriceController),
        segundaQuantity: _getQtyAsEggs(_segundaQtyController),
        segundaPrice: _getPrice(_segundaPriceController),
        terceraQuantity: _getQtyAsEggs(_terceraQtyController),
        terceraPrice: _getPrice(_terceraPriceController),
        cuartaQuantity: _getQtyAsEggs(_cuartaQtyController),
        cuartaPrice: _getPrice(_cuartaPriceController),
        quintaQuantity: _getQtyAsEggs(_quintaQtyController),
        quintaPrice: _getPrice(_quintaPriceController),
        suciosQuantity: _getQtyAsEggs(_suciosQtyController),
        suciosPrice: _getPrice(_suciosPriceController),
        rajadosQuantity: _getQtyAsEggs(_rajadosQtyController),
        rajadosPrice: _getPrice(_rajadosPriceController),
        totalSale: _total,
        isByMount: _isByMount,
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
            SwitchListTile(
              title: const Text('Venta por montones'),
              subtitle: Text(_isByMount ? '1 mount = 300 huevos' : 'Venta por unidades'),
              value: _isByMount,
              onChanged: (value) => setState(() => _isByMount = value),
            ),
            const SizedBox(height: 12),
            _buildCategoryRow('Extra', _extraQtyController, _extraPriceController),
            _buildCategoryRow('Especial', _especialQtyController, _especialPriceController),
            _buildCategoryRow('Primera', _primeraQtyController, _primeraPriceController),
            _buildCategoryRow('Segunda', _segundaQtyController, _segundaPriceController),
            _buildCategoryRow('Tercera', _terceraQtyController, _terceraPriceController),
            _buildCategoryRow('Cuarta', _cuartaQtyController, _cuartaPriceController),
            _buildCategoryRow('Quinta', _quintaQtyController, _quintaPriceController),
            _buildCategoryRow('Sucios', _suciosQtyController, _suciosPriceController),
            _buildCategoryRow('Rajados', _rajadosQtyController, _rajadosPriceController),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity( 0.2),
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

  Widget _buildCategoryRow(String label, TextEditingController qtyController, TextEditingController priceController) {
    final unitLabel = _isByMount ? 'Cant (mount)' : 'Cant';
    final priceLabel = _isByMount ? 'Bs/mount' : 'Bs/huevo';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: unitLabel, isDense: true),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: priceLabel, isDense: true),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }
}
