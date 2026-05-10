import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feed_inventory_model.dart';
import '../services/feed_inventory_service.dart';
import 'register_feed_purchase_screen.dart';
import 'feed_purchase_history_screen.dart';

class FeedInventoryScreen extends StatefulWidget {
  const FeedInventoryScreen({super.key});

  @override
  State<FeedInventoryScreen> createState() => _FeedInventoryScreenState();
}

class _FeedInventoryScreenState extends State<FeedInventoryScreen> {
  final FeedInventoryService _inventoryService = FeedInventoryService();
  List<FeedInventoryModel> _inventory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      List<FeedInventoryModel> inventory = await _inventoryService.getInventory(
        user.uid,
      );

      if (inventory.isEmpty) {
        await _inventoryService.initializeInventory(user.uid);
        inventory = await _inventoryService.getInventory(user.uid);
      }

      setState(() {
        _inventory = inventory;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<FeedInventoryModel> get _lowStockItems =>
      _inventory.where((item) => item.isLowStock).toList();

  double get _totalStock =>
      _inventory.fold(0, (sum, item) => sum + item.stockKg);

  Future<void> _initializeDefaultTypes() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _inventoryService.initializeInventory(user.uid);
      await _loadInventory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipos de alimento por defecto inicializados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Inventario de Alimento'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Agregar tipo de alimento',
            onPressed: _showAddFeedTypeDialog,
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Inicializar tipos por defecto',
            onPressed: _initializeDefaultTypes,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de Compras',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FeedPurchaseHistoryScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadInventory();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF8C00),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Comprar'),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegisterFeedPurchaseScreen(),
            ),
          );
          if (result == true) _loadInventory();
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInventory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    if (_lowStockItems.isNotEmpty) ...[
                      _buildLowStockAlert(),
                      const SizedBox(height: 16),
                    ],
                    _buildInventoryList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
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
                Icon(Icons.inventory_2, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'Resumen de Inventario',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.scale,
                    label: 'Total Stock',
                    value: '${_totalStock.toStringAsFixed(1)} kg',
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.category,
                    label: 'Tipos',
                    value: '${_inventory.length}',
                    color: const Color(0xFF1976D2),
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.warning,
                    label: 'Stock Bajo',
                    value: '${_lowStockItems.length}',
                    color: _lowStockItems.isNotEmpty ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockAlert() {
    return Card(
      color: Colors.red.shade50,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Alerta de Stock Bajo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._lowStockItems.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right, color: Colors.red.shade700),
                    Expanded(
                      child: Text(
                        '${item.feedType}: ${item.stockKg.toStringAsFixed(1)} kg (mín: ${item.minimumStock.toStringAsFixed(1)} kg)',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalle por Tipo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _inventory.length,
          itemBuilder: (context, index) {
            return _buildInventoryCard(_inventory[index]);
          },
        ),
      ],
    );
  }

  Widget _buildInventoryCard(FeedInventoryModel item) {
    Color statusColor = item.isLowStock ? Colors.red : const Color(0xFF2E7D32);
    String statusText = item.isLowStock ? 'Stock Bajo' : 'Normal';
    IconData statusIcon = item.isLowStock ? Icons.warning : Icons.check_circle;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showEditDialog(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.restaurant, color: statusColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.feedType,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(children: [Expanded(child: _buildStockBar(item))]),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stock actual: ${item.stockKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Mínimo: ${item.minimumStock.toStringAsFixed(1)} kg',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showDeleteInventoryConfirmation(item),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Eliminar'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteInventoryConfirmation(FeedInventoryModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar "${item.feedType}" del inventario? Esto también eliminará su historial de compras.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteFeedType(item);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAddFeedTypeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Tipo de Alimento'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre del tipo',
            hintText: 'Ej: Pre-starter, Developer, etc.',
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingrese un nombre válido'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (_inventory.any(
                (item) => item.feedType.toLowerCase() == text.toLowerCase(),
              )) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Este tipo de alimento ya existe'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
                return;
              }

              try {
                User? user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                await _inventoryService.updateStock(
                  user.uid,
                  text,
                  0.0,
                  50.0,
                  0.0,
                );

                if (mounted) {
                  Navigator.pop(context);
                  _loadInventory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tipo "$text" agregado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(FeedInventoryModel item) {
    final stockController = TextEditingController(text: item.stockKg.toString());
    final minimumStockController = TextEditingController(text: item.minimumStock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(item.feedType)),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _showDeleteInventoryConfirmation(item);
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock (kg)',
                prefixIcon: Icon(Icons.scale),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: minimumStockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock mínimo (kg)',
                prefixIcon: Icon(Icons.warning),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                User? user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                double newStock = double.tryParse(stockController.text) ?? 0;
                double newMinimum = double.tryParse(minimumStockController.text) ?? 50;

                await _inventoryService.updateStock(
                  user.uid,
                  item.feedType,
                  newStock,
                  newMinimum,
                  item.pricePerKg,
                );

                if (mounted) {
                  Navigator.pop(context);
                  _loadInventory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Inventario actualizado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBar(FeedInventoryModel item) {
    double percentage = item.stockPercentage;
    Color barColor = item.isLowStock ? Colors.red : const Color(0xFF2E7D32);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: barColor,
                fontSize: 12,
              ),
            ),
            Text(
              'Meta: ${item.minimumStock.toStringAsFixed(0)} kg',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.clamp(0, 100) / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Future<void> _deleteFeedType(FeedInventoryModel item) async {
    setState(() => _isLoading = true);
    try {
      await _inventoryService.deleteFeedType(item.userId, item.feedType);
      await _loadInventory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.feedType} eliminado del inventario'), backgroundColor: Colors.green),
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
}
