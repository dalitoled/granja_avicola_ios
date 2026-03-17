import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/hen_lot_model.dart';
import '../models/vaccination_model.dart';
import '../services/vaccination_service.dart';
import '../services/lot_service.dart';
import 'create_lot_screen.dart';

class RegisterVaccinationScreen extends StatefulWidget {
  const RegisterVaccinationScreen({super.key});

  @override
  State<RegisterVaccinationScreen> createState() =>
      _RegisterVaccinationScreenState();
}

class _RegisterVaccinationScreenState extends State<RegisterVaccinationScreen> {
  final VaccinationService _vaccinationService = VaccinationService();
  final LotService _lotService = LotService();
  final _formKey = GlobalKey<FormState>();

  DateTime _applicationDate = DateTime.now();
  DateTime? _nextDoseDate;
  final _vaccineNameController = TextEditingController();
  final _doseController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  List<HenLotModel> _lots = [];
  HenLotModel? _selectedLot;
  String _selectedMethod = 'Agua';

  final List<String> _methods = ['Agua', 'Inyección', 'Spray', 'Gota ocular'];
  final List<String> _vaccines = [
    'Newcastle',
    'Gumboro',
    'Bronquitis Infecciosa',
    'Encefalomielitis',
    'Viruela Aviar',
    'Coriza',
    'Mycoplasmosis',
    'Enfermedad de Marek',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _loadLots();
  }

  @override
  void dispose() {
    _vaccineNameController.dispose();
    _doseController.dispose();
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectApplicationDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _applicationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _applicationDate = picked);
    }
  }

  Future<void> _selectNextDoseDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _nextDoseDate ?? _applicationDate.add(const Duration(days: 7)),
      firstDate: _applicationDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() => _nextDoseDate = picked);
    }
  }

  Future<void> _saveVaccination() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un lote'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      VaccinationModel vaccination = VaccinationModel(
        userId: user.uid,
        lotId: _selectedLot!.id!,
        lotNumber: _selectedLot!.lotNumber,
        vaccineName: _vaccineNameController.text.trim(),
        applicationDate: _applicationDate,
        nextDoseDate: _nextDoseDate,
        dose: _doseController.text.trim(),
        method: _selectedMethod,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _vaccinationService.addVaccination(vaccination);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vacunación registrada'),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lots.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5DC),
        appBar: AppBar(
          title: const Text('Registrar Vacunación'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: _buildNoLotMessage(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Registrar Vacunación'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildLotCard(),
                const SizedBox(height: 16),
                _buildVaccineCard(),
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
              'Para registrar vacunación, primero debe crear un lote de gallinas.',
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

  Widget _buildLotCard() {
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_lots.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('No hay lotes activos'),
              )
            else
              DropdownButtonFormField<HenLotModel>(
                initialValue: _selectedLot,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _lots
                    .map(
                      (lot) => DropdownMenuItem(
                        value: lot,
                        child: Text(
                          'Lote ${lot.lotNumber} - ${lot.breed}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedLot = value),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaccineCard() {
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
                Icon(Icons.vaccines, color: Color(0xFF2E7D32)),
                SizedBox(width: 8),
                Text(
                  'Datos de Vacunación',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (txt) => txt.text.isEmpty
                  ? _vaccines
                  : _vaccines.where(
                      (v) => v.toLowerCase().contains(txt.text.toLowerCase()),
                    ),
              onSelected: (v) => _vaccineNameController.text = v,
              fieldViewBuilder: (ctx, ctrl, fn, _) => TextFormField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: 'Nombre de vacuna',
                  prefixIcon: const Icon(Icons.medical_services),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) => _vaccineNameController.text = v,
              ),
            ),
            const SizedBox(height: 16),
            _buildDateField(
              'Fecha aplicación',
              _applicationDate,
              _selectApplicationDate,
            ),
            const SizedBox(height: 16),
            _buildDateField(
              'Próxima dosis (opcional)',
              _nextDoseDate,
              _selectNextDoseDate,
              isOptional: true,
              onClear: () => setState(() => _nextDoseDate = null),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _doseController,
              decoration: InputDecoration(
                labelText: 'Dosis',
                prefixIcon: const Icon(Icons.format_list_numbered),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedMethod,
              decoration: InputDecoration(
                labelText: 'Método',
                prefixIcon: const Icon(Icons.list),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _methods
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedMethod = v!),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? date,
    VoidCallback onTap, {
    bool isOptional = false,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    date != null
                        ? DateFormat('dd/MM/yyyy').format(date)
                        : 'No seleccionada',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            if (isOptional && date != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: onClear,
              ),
            const Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
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
        onPressed: _isLoading ? null : _saveVaccination,
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
                    'Guardar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
