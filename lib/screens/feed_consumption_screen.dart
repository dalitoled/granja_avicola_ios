import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/feed_consumption_model.dart';
import '../services/feed_service.dart';
import '../services/feed_inventory_service.dart';
import '../services/lot_service.dart';
import 'create_lot_screen.dart';

class FeedConsumptionScreen extends StatefulWidget {
  const FeedConsumptionScreen({super.key});

  @override
  State<FeedConsumptionScreen> createState() => _FeedConsumptionScreenState();
}

class _FeedConsumptionScreenState extends State<FeedConsumptionScreen> {
  final FeedService _feedService = FeedService();
  final FeedInventoryService _inventoryService = FeedInventoryService();
  final LotService _lotService = LotService();
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  final _hensCountController = TextEditingController();
  final _feedKgController = TextEditingController();
  final _feedTypeController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingPrice = false;
  bool _hasActiveLots = false;
  bool _isCheckingLots = true;
  double _feedCost = 0;
  double _currentPricePerKg = 0;

  final List<String> _feedTypes = [...FeedInventoryService.defaultFeedTypes];

  @override
  void initState() {
    super.initState();
    _feedKgController.addListener(_calculateFeedCost);
    _checkActiveLots();
  }

  @override
  void dispose() {
    _hensCountController.dispose();
    _feedKgController.dispose();
    _feedTypeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateFeedCost() {
    double feedKg = double.tryParse(_feedKgController.text) ?? 0;
    setState(() {
      _feedCost = feedKg * _currentPricePerKg;
    });
  }

  Future<void> _checkActiveLots() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    bool hasLots = await _lotService.hasActiveLots(user.uid);
    if (mounted) {
      setState(() {
        _hasActiveLots = hasLots;
        _isCheckingLots = false;
      });
    }
  }

  Future<void> _fetchPriceFromInventory(String feedType) async {
    if (feedType.isEmpty) return;

    setState(() => _isLoadingPrice = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final inventory = await _inventoryService.getInventoryByType(
        user.uid,
        feedType,
      );

      if (inventory != null && inventory.pricePerKg > 0) {
        setState(() {
          _currentPricePerKg = inventory.pricePerKg;
        });
        _calculateFeedCost();
      } else {
        final purchases = await _inventoryService.getPurchasesByType(
          user.uid,
          feedType,
        );
        if (purchases.isNotEmpty) {
          setState(() {
            _currentPricePerKg = purchases.first.pricePerKg;
          });
          _calculateFeedCost();
        } else {
          setState(() {
            _currentPricePerKg = 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching price: $e');
    } finally {
      setState(() => _isLoadingPrice = false);
    }
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

  Future<void> _saveFeedConsumption() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      double feedKg = double.tryParse(_feedKgController.text) ?? 0;
      double pricePerKg = _currentPricePerKg;
      double feedCost = feedKg * pricePerKg;

      FeedConsumptionModel feed = FeedConsumptionModel(
        userId: user.uid,
        date: _selectedDate,
        hensCount: int.tryParse(_hensCountController.text) ?? 0,
        feedKg: feedKg,
        feedType: _feedTypeController.text.trim(),
        pricePerKg: pricePerKg,
        feedCost: feedCost,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _feedService.addFeedConsumption(feed);

      try {
        await _inventoryService.subtractStock(user.uid, feed.feedType, feedKg);
      } catch (e) {
        debugPrint('Error al actualizar inventario: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consumo de alimento guardado exitosamente'),
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
    _hensCountController.clear();
    _feedKgController.clear();
    _feedTypeController.clear();
    _notesController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _feedCost = 0;
      _currentPricePerKg = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLots) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5DC),
        appBar: AppBar(
          title: const Text('Consumo de Alimento'),
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
          title: const Text('Consumo de Alimento'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: _buildNoLotMessage(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Consumo de Alimento'),
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
                _buildFeedDataCard(),
                const SizedBox(height: 24),
                _buildSaveButton(),
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
              'Para registrar consumo de alimento, primero debe crear un lote de gallinas.',
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
                  'Fecha',
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

  Widget _buildFeedDataCard() {
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
                Icon(Icons.restaurant, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'Datos del Alimento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hensCountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Número de gallinas',
                prefixIcon: const Icon(Icons.egg),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el número de gallinas';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _feedKgController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Alimento consumido (kg)',
                prefixIcon: const Icon(Icons.scale),
                suffixText: 'kg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese la cantidad de alimento';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _feedTypes;
                }
                return _feedTypes.where(
                  (type) => type.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              onSelected: (String selection) {
                _feedTypeController.text = selection;
                _fetchPriceFromInventory(selection);
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    _feedTypeController.text = controller.text;
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Tipo de alimento',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                        _feedTypeController.text = value;
                        if (value.isNotEmpty) {
                          _fetchPriceFromInventory(value);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el tipo de alimento';
                        }
                        return null;
                      },
                    );
                  },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isLoadingPrice
                        ? const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Cargando precio...'),
                            ],
                          )
                        : Text(
                            _currentPricePerKg > 0
                                ? 'Precio por kg: Bs ${_currentPricePerKg.toStringAsFixed(2)}'
                                : 'Precio no disponible. Seleccione un tipo de alimento.',
                            style: TextStyle(
                              fontSize: 14,
                              color: _currentPricePerKg > 0
                                  ? Colors.black87
                                  : Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity( 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E7D32)),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Costo del alimento:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      'Bs ${_feedCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notas (opcional)',
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
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
        onPressed: _isLoading ? null : _saveFeedConsumption,
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
                    'Guardar Consumo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
