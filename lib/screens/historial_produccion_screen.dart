import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/egg_production_model.dart';
import '../services/production_service.dart';

class HistorialProduccionScreen extends StatefulWidget {
  const HistorialProduccionScreen({super.key});

  @override
  State<HistorialProduccionScreen> createState() =>
      _HistorialProduccionScreenState();
}

class _HistorialProduccionScreenState extends State<HistorialProduccionScreen> {
  final ProductionService _productionService = ProductionService();
  List<EggProductionModel> _productions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProductions();
  }

  Future<void> _loadProductions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      List<EggProductionModel> productions = await _productionService
          .getProductionsByUser(user.uid);

      setState(() {
        _productions = productions;
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
        title: const Text('Historial de Producción'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProductions,
          ),
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
              onPressed: _loadProductions,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_productions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.egg_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay registros de producción',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra tu primera producción',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProductions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _productions.length,
        itemBuilder: (context, index) {
          return _buildProductionCard(_productions[index]);
        },
      ),
    );
  }

  Widget _buildProductionCard(EggProductionModel production) {
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
          child: const Icon(Icons.egg, color: Colors.white, size: 28),
        ),
        title: Text(
          DateFormat('dd/MM/yyyy', 'es_ES').format(production.date),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          production.displayTotal,
          style: const TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child:             Column(
              children: [
                _buildDetailRow('Extra', production.extra, production.extraMaples, production.extraMounts),
                _buildDetailRow('Especial', production.especial, production.especialMaples, production.especialMounts),
                _buildDetailRow('Primera', production.primera, production.primeraMaples, production.primeraMounts),
                _buildDetailRow('Segunda', production.segunda, production.segundaMaples, production.segundaMounts),
                _buildDetailRow('Tercera', production.tercera, production.terceraMaples, production.terceraMounts),
                _buildDetailRow('Cuarta', production.cuarta, production.cuartaMaples, production.cuartaMounts),
                _buildDetailRow('Quinta', production.quinta, production.quintaMaples, production.quintaMounts),
                _buildDetailRow('Sucios', production.sucios, production.suciosMaples, production.suciosMounts),
                _buildDetailRow('Rajados', production.rajados, production.rajadosMaples, production.rajadosMounts),
                _buildDetailRow('Descarte', production.descarte, production.descarteMaples, production.descarteMounts, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () => _showEditDialog(production),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editar'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF1976D2)),
              ),
              TextButton.icon(
                onPressed: () => _showDeleteConfirmation(production),
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Eliminar'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Registrado: ${DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(production.createdAt)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, int units, int maples, int mounts, {bool isLast = false}) {
    final fromMaples = maples * EggProductionModel.MAPLE_EGGS;
    final fromMounts = mounts * EggProductionModel.MOUNT_EGGS;
    final total = units + fromMaples + fromMounts;
    
    final hasMaples = maples > 0;
    final hasMounts = mounts > 0;
    final hasUnits = units > 0;
    
    String valueText;
    if (hasMounts && hasMaples && hasUnits) {
      valueText = '$mounts m ($fromMounts) + $maples m ($fromMaples) + $units = $total';
    } else if (hasMounts && hasMaples) {
      valueText = '$mounts m ($fromMounts) + $maples m ($fromMaples) = $total';
    } else if (hasMounts && hasUnits) {
      valueText = '$mounts m ($fromMounts) + $units = $total';
    } else if (hasMounts) {
      valueText = '$mounts m = $total';
    } else if (hasMaples && hasUnits) {
      valueText = '$maples m ($fromMaples) + $units = $total';
    } else if (hasMaples) {
      valueText = '$maples m = $total';
    } else {
      valueText = '$units';
    }
    
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              valueText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(EggProductionModel production) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar la producción del ${DateFormat('dd/MM/yyyy').format(production.date)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteProduction(production);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduction(EggProductionModel production) async {
    setState(() => _isLoading = true);
    try {
      await _productionService.deleteProduction(production.id!);
      await _loadProductions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producción eliminada'), backgroundColor: Colors.green),
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

  void _showEditDialog(EggProductionModel production) {
    showDialog(
      context: context,
      builder: (ctx) => EditProductionDialog(
        production: production,
        productionService: _productionService,
        onSave: () => _loadProductions(),
      ),
    );
  }
}

class EditProductionDialog extends StatefulWidget {
  final EggProductionModel production;
  final ProductionService productionService;
  final VoidCallback onSave;

  const EditProductionDialog({
    super.key,
    required this.production,
    required this.productionService,
    required this.onSave,
  });

  @override
  State<EditProductionDialog> createState() => _EditProductionDialogState();
}

class _EditProductionDialogState extends State<EditProductionDialog> {
  late TextEditingController _extraController;
  late TextEditingController _especialController;
  late TextEditingController _primeraController;
  late TextEditingController _segundaController;
  late TextEditingController _terceraController;
  late TextEditingController _cuartaController;
  late TextEditingController _quintaController;
  late TextEditingController _suciosController;
  late TextEditingController _rajadosController;
  late TextEditingController _descarteController;
  
  late TextEditingController _extraMaplesController;
  late TextEditingController _especialMaplesController;
  late TextEditingController _primeraMaplesController;
  late TextEditingController _segundaMaplesController;
  late TextEditingController _terceraMaplesController;
  late TextEditingController _cuartaMaplesController;
  late TextEditingController _quintaMaplesController;
  late TextEditingController _suciosMaplesController;
  late TextEditingController _rajadosMaplesController;
  late TextEditingController _descarteMaplesController;
  
  late TextEditingController _extraMountsController;
  late TextEditingController _especialMountsController;
  late TextEditingController _primeraMountsController;
  late TextEditingController _segundaMountsController;
  late TextEditingController _terceraMountsController;
  late TextEditingController _cuartaMountsController;
  late TextEditingController _quintaMountsController;
  late TextEditingController _suciosMountsController;
  late TextEditingController _rajadosMountsController;
  late TextEditingController _descarteMountsController;
  
  late DateTime _selectedDate;
  bool _isLoading = false;

  static const int MAPLE_EGGS = 30;
  static const int MOUNT_MAPLES = 10;
  static const int MOUNT_EGGS = MAPLE_EGGS * MOUNT_MAPLES;

  @override
  void initState() {
    super.initState();
    _extraController = TextEditingController(text: widget.production.extra.toString());
    _especialController = TextEditingController(text: widget.production.especial.toString());
    _primeraController = TextEditingController(text: widget.production.primera.toString());
    _segundaController = TextEditingController(text: widget.production.segunda.toString());
    _terceraController = TextEditingController(text: widget.production.tercera.toString());
    _cuartaController = TextEditingController(text: widget.production.cuarta.toString());
    _quintaController = TextEditingController(text: widget.production.quinta.toString());
    _suciosController = TextEditingController(text: widget.production.sucios.toString());
    _rajadosController = TextEditingController(text: widget.production.rajados.toString());
    _descarteController = TextEditingController(text: widget.production.descarte.toString());
    
    _extraMaplesController = TextEditingController(text: widget.production.extraMaples.toString());
    _especialMaplesController = TextEditingController(text: widget.production.especialMaples.toString());
    _primeraMaplesController = TextEditingController(text: widget.production.primeraMaples.toString());
    _segundaMaplesController = TextEditingController(text: widget.production.segundaMaples.toString());
    _terceraMaplesController = TextEditingController(text: widget.production.terceraMaples.toString());
    _cuartaMaplesController = TextEditingController(text: widget.production.cuartaMaples.toString());
    _quintaMaplesController = TextEditingController(text: widget.production.quintaMaples.toString());
    _suciosMaplesController = TextEditingController(text: widget.production.suciosMaples.toString());
    _rajadosMaplesController = TextEditingController(text: widget.production.rajadosMaples.toString());
    _descarteMaplesController = TextEditingController(text: widget.production.descarteMaples.toString());
    
    _extraMountsController = TextEditingController(text: widget.production.extraMounts.toString());
    _especialMountsController = TextEditingController(text: widget.production.especialMounts.toString());
    _primeraMountsController = TextEditingController(text: widget.production.primeraMounts.toString());
    _segundaMountsController = TextEditingController(text: widget.production.segundaMounts.toString());
    _terceraMountsController = TextEditingController(text: widget.production.terceraMounts.toString());
    _cuartaMountsController = TextEditingController(text: widget.production.cuartaMounts.toString());
    _quintaMountsController = TextEditingController(text: widget.production.quintaMounts.toString());
    _suciosMountsController = TextEditingController(text: widget.production.suciosMounts.toString());
    _rajadosMountsController = TextEditingController(text: widget.production.rajadosMounts.toString());
    _descarteMountsController = TextEditingController(text: widget.production.descarteMounts.toString());
    
    _selectedDate = widget.production.date;
  }

  @override
  void dispose() {
    _extraController.dispose();
    _especialController.dispose();
    _primeraController.dispose();
    _segundaController.dispose();
    _terceraController.dispose();
    _cuartaController.dispose();
    _quintaController.dispose();
    _suciosController.dispose();
    _rajadosController.dispose();
    _descarteController.dispose();
    
    _extraMaplesController.dispose();
    _especialMaplesController.dispose();
    _primeraMaplesController.dispose();
    _segundaMaplesController.dispose();
    _terceraMaplesController.dispose();
    _cuartaMaplesController.dispose();
    _quintaMaplesController.dispose();
    _suciosMaplesController.dispose();
    _rajadosMaplesController.dispose();
    _descarteMaplesController.dispose();
    
    _extraMountsController.dispose();
    _especialMountsController.dispose();
    _primeraMountsController.dispose();
    _segundaMountsController.dispose();
    _terceraMountsController.dispose();
    _cuartaMountsController.dispose();
    _quintaMountsController.dispose();
    _suciosMountsController.dispose();
    _rajadosMountsController.dispose();
    _descarteMountsController.dispose();
    
    super.dispose();
  }

  int get _total {
    int total = 0;
    total += (int.tryParse(_extraController.text) ?? 0) + (int.tryParse(_extraMaplesController.text) ?? 0) * MAPLE_EGGS + (int.tryParse(_extraMountsController.text) ?? 0) * MOUNT_EGGS;
    total += (int.tryParse(_especialController.text) ?? 0) + (int.tryParse(_especialMaplesController.text) ?? 0) * MAPLE_EGGS + (int.tryParse(_especialMountsController.text) ?? 0) * MOUNT_EGGS;
    total += (int.tryParse(_primeraController.text) ?? 0) + (int.tryParse(_primeraMaplesController.text) ?? 0) * MAPLE_EGGS + (int.tryParse(_primeraMountsController.text) ?? 0) * MOUNT_EGGS;
    total += (int.tryParse(_segundaController.text) ?? 0) + (int.tryParse(_segundaMaplesController.text) ?? 0) * MAPLE_EGGS + (int.tryParse(_segundaMountsController.text) ?? 0) * MOUNT_EGGS;
    total += (int.tryParse(_terceraController.text) ?? 0) + (int.tryParse(_terceraMaplesController.text) ?? 0) * MAPLE_EGGS + (int.tryParse(_terceraMountsController.text) ?? 0) * MOUNT_EGGS;
    total += (int.tryParse(_cuartaController.text) ?? 0) + (int.tryParse(_cuartaMaplesController.text) ?? 0) * MAPLE_EGGS + (int.tryParse(_cuartaMountsController.text) ?? 0) * MOUNT_EGGS;
    total += (int.tryParse(_quintaController.text) ?? 0) + (int.tryParse(_quintaMaplesController.text) ?? 0) * MAPLE_EGGS + (int.tryParse(_quintaMountsController.text) ?? 0) * MOUNT_EGGS;
    total += (int.tryParse(_suciosController.text) ?? 0) + (int.tryParse(_suciosMaplesController.text) ?? 0) * MAPLE_EGGS + (int.tryParse(_suciosMountsController.text) ?? 0) * MOUNT_EGGS;
    total += (int.tryParse(_rajadosController.text) ?? 0) + (int.tryParse(_rajadosMaplesController.text) ?? 0) * MAPLE_EGGS + (int.tryParse(_rajadosMountsController.text) ?? 0) * MOUNT_EGGS;
    total += (int.tryParse(_descarteController.text) ?? 0) + (int.tryParse(_descarteMaplesController.text) ?? 0) * MAPLE_EGGS + (int.tryParse(_descarteMountsController.text) ?? 0) * MOUNT_EGGS;
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
      EggProductionModel updated = EggProductionModel(
        id: widget.production.id,
        userId: widget.production.userId,
        date: _selectedDate,
        extra: int.tryParse(_extraController.text) ?? 0,
        especial: int.tryParse(_especialController.text) ?? 0,
        primera: int.tryParse(_primeraController.text) ?? 0,
        segunda: int.tryParse(_segundaController.text) ?? 0,
        tercera: int.tryParse(_terceraController.text) ?? 0,
        cuarta: int.tryParse(_cuartaController.text) ?? 0,
        quinta: int.tryParse(_quintaController.text) ?? 0,
        sucios: int.tryParse(_suciosController.text) ?? 0,
        rajados: int.tryParse(_rajadosController.text) ?? 0,
        descarte: int.tryParse(_descarteController.text) ?? 0,
        totalHuevos: _total,
        createdAt: widget.production.createdAt,
        extraMaples: int.tryParse(_extraMaplesController.text) ?? 0,
        especialMaples: int.tryParse(_especialMaplesController.text) ?? 0,
        primeraMaples: int.tryParse(_primeraMaplesController.text) ?? 0,
        segundaMaples: int.tryParse(_segundaMaplesController.text) ?? 0,
        terceraMaples: int.tryParse(_terceraMaplesController.text) ?? 0,
        cuartaMaples: int.tryParse(_cuartaMaplesController.text) ?? 0,
        quintaMaples: int.tryParse(_quintaMaplesController.text) ?? 0,
        suciosMaples: int.tryParse(_suciosMaplesController.text) ?? 0,
        rajadosMaples: int.tryParse(_rajadosMaplesController.text) ?? 0,
        descarteMaples: int.tryParse(_descarteMaplesController.text) ?? 0,
        extraMounts: int.tryParse(_extraMountsController.text) ?? 0,
        especialMounts: int.tryParse(_especialMountsController.text) ?? 0,
        primeraMounts: int.tryParse(_primeraMountsController.text) ?? 0,
        segundaMounts: int.tryParse(_segundaMountsController.text) ?? 0,
        terceraMounts: int.tryParse(_terceraMountsController.text) ?? 0,
        cuartaMounts: int.tryParse(_cuartaMountsController.text) ?? 0,
        quintaMounts: int.tryParse(_quintaMountsController.text) ?? 0,
        suciosMounts: int.tryParse(_suciosMountsController.text) ?? 0,
        rajadosMounts: int.tryParse(_rajadosMountsController.text) ?? 0,
        descarteMounts: int.tryParse(_descarteMountsController.text) ?? 0,
      );

      await widget.productionService.updateProduction(updated);

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producción actualizada'), backgroundColor: Colors.green),
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
      title: const Text('Editar Producción'),
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
            const SizedBox(height: 8),
            Text('1 maple = $MAPLE_EGGS | 1 montón = $MOUNT_MAPLES maples = $MOUNT_EGGS', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 12),
            _buildCategoryEdit('Extra', _extraMaplesController, _extraMountsController, _extraController),
            _buildCategoryEdit('Especial', _especialMaplesController, _especialMountsController, _especialController),
            _buildCategoryEdit('Primera', _primeraMaplesController, _primeraMountsController, _primeraController),
            _buildCategoryEdit('Segunda', _segundaMaplesController, _segundaMountsController, _segundaController),
            _buildCategoryEdit('Tercera', _terceraMaplesController, _terceraMountsController, _terceraController),
            _buildCategoryEdit('Cuarta', _cuartaMaplesController, _cuartaMountsController, _cuartaController),
            _buildCategoryEdit('Quinta', _quintaMaplesController, _quintaMountsController, _quintaController),
            _buildCategoryEdit('Sucios', _suciosMaplesController, _suciosMountsController, _suciosController),
            _buildCategoryEdit('Rajados', _rajadosMaplesController, _rajadosMountsController, _rajadosController),
            _buildCategoryEdit('Descarte', _descarteMaplesController, _descarteMountsController, _descarteController),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('$_total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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

  Widget _buildCategoryEdit(String label, TextEditingController maplesCtrl, TextEditingController mountsCtrl, TextEditingController unitsCtrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: TextField(
              controller: mountsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montón', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
              style: const TextStyle(fontSize: 12),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: maplesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Maples', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
              style: const TextStyle(fontSize: 12),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: unitsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Uds', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
              style: const TextStyle(fontSize: 12),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }
}
