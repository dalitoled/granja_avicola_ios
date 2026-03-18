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
          'Total: ${production.totalHuevos} huevos',
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
            child: Column(
              children: [
                _buildDetailRow('Extra', production.extra),
                _buildDetailRow('Especial', production.especial),
                _buildDetailRow('Primera', production.primera),
                _buildDetailRow('Segunda', production.segunda),
                _buildDetailRow('Tercera', production.tercera),
                _buildDetailRow('Cuarta', production.cuarta),
                _buildDetailRow('Quinta', production.quinta),
                _buildDetailRow('Sucios', production.sucios),
                _buildDetailRow('Rajados', production.rajados),
                _buildDetailRow('Descarte', production.descarte, isLast: true),
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

  Widget _buildDetailRow(String label, int value, {bool isLast = false}) {
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity( 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.toString(),
              style: const TextStyle(
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
  late DateTime _selectedDate;
  bool _isLoading = false;

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
    super.dispose();
  }

  int get _total {
    return (int.tryParse(_extraController.text) ?? 0) +
        (int.tryParse(_especialController.text) ?? 0) +
        (int.tryParse(_primeraController.text) ?? 0) +
        (int.tryParse(_segundaController.text) ?? 0) +
        (int.tryParse(_terceraController.text) ?? 0) +
        (int.tryParse(_cuartaController.text) ?? 0) +
        (int.tryParse(_quintaController.text) ?? 0) +
        (int.tryParse(_suciosController.text) ?? 0) +
        (int.tryParse(_rajadosController.text) ?? 0) +
        (int.tryParse(_descarteController.text) ?? 0);
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
            const SizedBox(height: 12),
            _buildField('Extra', _extraController),
            _buildField('Especial', _especialController),
            _buildField('Primera', _primeraController),
            _buildField('Segunda', _segundaController),
            _buildField('Tercera', _terceraController),
            _buildField('Cuarta', _cuartaController),
            _buildField('Quinta', _quintaController),
            _buildField('Sucios', _suciosController),
            _buildField('Rajados', _rajadosController),
            _buildField('Descarte', _descarteController),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00).withOpacity( 0.2),
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

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
