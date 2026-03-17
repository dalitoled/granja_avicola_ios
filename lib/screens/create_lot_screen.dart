import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/hen_lot_model.dart';
import '../services/lot_service.dart';

class CreateLotScreen extends StatefulWidget {
  const CreateLotScreen({super.key});

  @override
  State<CreateLotScreen> createState() => _CreateLotScreenState();
}

class _CreateLotScreenState extends State<CreateLotScreen> {
  final LotService _lotService = LotService();
  final _formKey = GlobalKey<FormState>();

  DateTime _startDate = DateTime.now();
  final _lotNumberController = TextEditingController();
  final _breedController = TextEditingController();
  final _supplierController = TextEditingController();
  final _initialHensController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  final List<String> _breeds = [
    'Lohmann',
    'Hy-Line',
    'Isa Brown',
    'Hisex',
    'Rhode Island Red',
    'Leghorn',
    'Plymouth Rock',
    'Otro',
  ];

  @override
  void dispose() {
    _lotNumberController.dispose();
    _breedController.dispose();
    _supplierController.dispose();
    _initialHensController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _saveLot() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      int initialHens = int.tryParse(_initialHensController.text) ?? 0;

      HenLotModel lot = HenLotModel(
        userId: user.uid,
        lotNumber: _lotNumberController.text.trim(),
        breed: _breedController.text.trim(),
        supplier: _supplierController.text.trim().isEmpty
            ? null
            : _supplierController.text.trim(),
        startDate: _startDate,
        initialHens: initialHens,
        currentHens: initialHens,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _lotService.addLot(lot);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lote guardado exitosamente'),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Crear Lote'),
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
                _buildLotInfoCard(),
                const SizedBox(height: 24),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLotInfoCard() {
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
                  'Datos del Lote',
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
              controller: _lotNumberController,
              decoration: InputDecoration(
                labelText: 'Número de lote',
                prefixIcon: const Icon(Icons.tag),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el número de lote';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _breeds;
                }
                return _breeds.where(
                  (breed) => breed.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              onSelected: (String selection) {
                _breedController.text = selection;
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    _breedController.text = controller.text;
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Raza',
                        prefixIcon: const Icon(Icons.pets),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) => _breedController.text = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese la raza';
                        }
                        return null;
                      },
                    );
                  },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _supplierController,
              decoration: InputDecoration(
                labelText: 'Proveedor (opcional)',
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
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
                          'Fecha de ingreso',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy', 'es_ES').format(_startDate),
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
              controller: _initialHensController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Número inicial de gallinas',
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
                return null;
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
        onPressed: _isLoading ? null : _saveLot,
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
                    'Guardar Lote',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
