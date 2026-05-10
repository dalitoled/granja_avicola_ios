import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/feed_consumption_model.dart';
import '../services/feed_service.dart';
import '../services/feed_inventory_service.dart';

class FeedHistoryScreen extends StatefulWidget {
  const FeedHistoryScreen({super.key});

  @override
  State<FeedHistoryScreen> createState() => _FeedHistoryScreenState();
}

class _FeedHistoryScreenState extends State<FeedHistoryScreen> {
  final FeedService _feedService = FeedService();
  final FeedInventoryService _inventoryService = FeedInventoryService();
  List<FeedConsumptionModel> _feedList = [];
  Map<String, double> _feedPrices = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeedHistory();
  }

  Future<void> _loadFeedHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      List<FeedConsumptionModel> feedList = await _feedService
          .getFeedConsumptionByUser(user.uid);

      Map<String, double> prices = {};
      Set<String> feedTypes = feedList.map((f) => f.feedType).toSet();

      for (String feedType in feedTypes) {
        try {
          final purchases = await _inventoryService.getPurchasesByType(
            user.uid,
            feedType,
          );
          if (purchases.isNotEmpty) {
            prices[feedType] = purchases.first.pricePerKg;
          }
        } catch (e) {
          debugPrint('Error fetching price for $feedType: $e');
        }
      }

      setState(() {
        _feedList = feedList;
        _feedPrices = prices;
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
        title: const Text('Historial de Alimento'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedHistory,
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
              onPressed: _loadFeedHistory,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_feedList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay registros de alimento',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra el primer consumo de alimento',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeedHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _feedList.length,
        itemBuilder: (context, index) {
          return _buildFeedCard(_feedList[index]);
        },
      ),
    );
  }

  Widget _buildFeedCard(FeedConsumptionModel feed) {
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
            color: const Color(0xFF8B4513),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.restaurant, color: Colors.white, size: 28),
        ),
        title: Text(
          DateFormat('dd/MM/yyyy', 'es_ES').format(feed.date),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(
          feed.feedType,
          style: const TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Text(
          '${feed.feedKg} kg',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
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
                _buildDetailRow('Gallinas', '${feed.hensCount}'),
                _buildDetailRow('Alimento consumido', '${feed.feedKg} kg'),
                _buildDetailRow(
                  'Precio por kg',
                  _feedPrices.containsKey(feed.feedType)
                      ? 'Bs ${_feedPrices[feed.feedType]!.toStringAsFixed(2)}'
                      : 'Bs ${feed.pricePerKg.toStringAsFixed(2)}',
                ),
                _buildDetailRow(
                  'Costo total',
                  'Bs ${((_feedPrices[feed.feedType] ?? feed.pricePerKg) * feed.feedKg).toStringAsFixed(2)}',
                  isHighlighted: true,
                ),
                _buildDetailRow('Tipo de alimento', feed.feedType),
                if (feed.notes != null && feed.notes!.isNotEmpty)
                  _buildDetailRow('Notas', feed.notes!),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () => _showEditDialog(feed),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editar'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF1976D2)),
              ),
              TextButton.icon(
                onPressed: () => _showDeleteConfirmation(feed),
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Eliminar'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Registrado: ${DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(feed.createdAt)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isLast = false,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF2E7D32).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.white : const Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(FeedConsumptionModel feed) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar el registro del ${DateFormat('dd/MM/yyyy').format(feed.date)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteFeed(feed);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFeed(FeedConsumptionModel feed) async {
    setState(() => _isLoading = true);
    try {
      await _feedService.deleteFeedConsumption(feed.id!);
      await _loadFeedHistory();
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

  void _showEditDialog(FeedConsumptionModel feed) {
    showDialog(
      context: context,
      builder: (ctx) => EditFeedDialog(
        feed: feed,
        feedService: _feedService,
        onSave: () => _loadFeedHistory(),
      ),
    );
  }
}

class EditFeedDialog extends StatefulWidget {
  final FeedConsumptionModel feed;
  final FeedService feedService;
  final VoidCallback onSave;

  const EditFeedDialog({
    super.key,
    required this.feed,
    required this.feedService,
    required this.onSave,
  });

  @override
  State<EditFeedDialog> createState() => _EditFeedDialogState();
}

class _EditFeedDialogState extends State<EditFeedDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hensController;
  late TextEditingController _feedKgController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _hensController = TextEditingController(text: widget.feed.hensCount.toString());
    _feedKgController = TextEditingController(text: widget.feed.feedKg.toString());
    _notesController = TextEditingController(text: widget.feed.notes ?? '');
    _selectedDate = widget.feed.date;
  }

  @override
  void dispose() {
    _hensController.dispose();
    _feedKgController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _totalCost {
    double kg = double.tryParse(_feedKgController.text) ?? 0;
    return kg * widget.feed.pricePerKg;
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      FeedConsumptionModel updated = FeedConsumptionModel(
        id: widget.feed.id,
        userId: widget.feed.userId,
        date: _selectedDate,
        hensCount: int.parse(_hensController.text),
        feedKg: double.parse(_feedKgController.text),
        feedType: widget.feed.feedType,
        pricePerKg: widget.feed.pricePerKg,
        feedCost: _totalCost,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: widget.feed.createdAt,
      );

      await widget.feedService.updateFeedConsumption(updated);

      if (mounted) {
        Navigator.pop(context);
        widget.onSave();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro actualizado'), backgroundColor: Colors.green),
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
      title: const Text('Editar Consumo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _hensController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Número de gallinas'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _feedKgController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Alimento (kg)'),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Fecha'),
                  child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notas (opcional)'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Costo:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Bs ${_totalCost.toStringAsFixed(2)}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
            ],
          ),
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
