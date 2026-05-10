import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/hen_lot_model.dart';
import '../models/hen_mortality_model.dart';
import '../services/mortality_service.dart';
import '../services/lot_service.dart';
import 'create_lot_screen.dart';

class RegisterMortalityScreen extends StatefulWidget {
  const RegisterMortalityScreen({super.key});

  @override
  State<RegisterMortalityScreen> createState() =>
      _RegisterMortalityScreenState();
}

class _RegisterMortalityScreenState extends State<RegisterMortalityScreen> {
  final MortalityService _mortalityService = MortalityService();
  final LotService _lotService = LotService();
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  final _deadHensController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  List<HenLotModel> _lots = [];
  HenLotModel? _selectedLot;
  String _selectedCause = 'Enfermedad';

  final List<String> _causes = [
    'Enfermedad',
    'Depredador',
    'Accidente',
    'Desconocido',
  ];

  @override
  void initState() {
    super.initState();
    _loadLots();
  }

  @override
  void dispose() {
    _deadHensController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLots() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      List<HenLotModel> lots = await _lotService.getLotsByUser(user.uid);
      setState(() {
        _lots = lots.where((lot) => lot.currentHens > 0).toList();
        if (_lots.isNotEmpty) {
          _selectedLot = _lots.first;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar lotes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Future<void> _saveMortality() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un lote'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      int deadHens = int.tryParse(_deadHensController.text) ?? 0;

      if (deadHens > _selectedLot!.currentHens) {
        throw Exception('No puede registrar más muertes que gallinas actuales');
      }

      HenMortalityModel record = HenMortalityModel(
        userId: user.uid,
        lotId: _selectedLot!.id!,
        lotNumber: _selectedLot!.lotNumber,
        date: _selectedDate,
        deadHens: deadHens,
        cause: _selectedCause,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _mortalityService.addMortalityRecord(record);

      // Update lot current hens
      int newCurrentHens = _selectedLot!.currentHens - deadHens;
      HenLotModel updatedLot = _selectedLot!.copyWith(
        currentHens: newCurrentHens,
      );
      await _lotService.updateLot(updatedLot);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro de mortalidad guardado'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    if (_lots.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5DC),
        appBar: AppBar(
          title: const Text('Registrar Mortalidad'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: _buildNoLotMessage(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Registrar Mortalidad'),
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
                _buildLotSelectorCard(),
                const SizedBox(height: 16),
                _buildMortalityCard(),
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
              'Para registrar mortalidad, primero debe crear un lote de gallinas.',
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
                  _loadLots();
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

  Widget _buildLotSelectorCard() {
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
                Icon(Icons.egg_alt, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'Seleccionar Lote',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_lots.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No hay lotes activos',
                  textAlign: TextAlign.center,
                ),
              )
            else
              DropdownButtonFormField<HenLotModel>(
                value: _selectedLot,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _lots.map((lot) {
                  return DropdownMenuItem(
                    value: lot,
                    child: Text(
                      'Lote ${lot.lotNumber} - ${lot.breed} (${lot.currentHens})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLot = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor seleccione un lote';
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMortalityCard() {
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
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Datos de Mortalidad',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fecha',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy',
                            'es_ES',
                          ).format(_selectedDate),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    const Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deadHensController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Número de gallinas muertas',
                prefixIcon: const Icon(Icons.numbers),
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
                if (_selectedLot != null &&
                    int.tryParse(value)! > _selectedLot!.currentHens) {
                  return 'No puede ser mayor a ${_selectedLot!.currentHens}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCause,
              decoration: InputDecoration(
                labelText: 'Causa de muerte',
                prefixIcon: const Icon(Icons.help_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _causes.map((cause) {
                return DropdownMenuItem(value: cause, child: Text(cause));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCause = value!;
                });
              },
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
        onPressed: _isLoading ? null : _saveMortality,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
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
                    'Guardar Registro',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
