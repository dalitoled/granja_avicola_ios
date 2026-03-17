import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/vaccination_model.dart';
import '../services/vaccination_service.dart';

class VaccinationHistoryScreen extends StatefulWidget {
  const VaccinationHistoryScreen({super.key});

  @override
  State<VaccinationHistoryScreen> createState() =>
      _VaccinationHistoryScreenState();
}

class _VaccinationHistoryScreenState extends State<VaccinationHistoryScreen> {
  final VaccinationService _vaccinationService = VaccinationService();
  List<VaccinationModel> _vaccinations = [];
  bool _isLoading = true;
  String? _selectedLotFilter;

  @override
  void initState() {
    super.initState();
    _loadVaccinations();
  }

  Future<void> _loadVaccinations() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      List<VaccinationModel> vaccinations = await _vaccinationService
          .getVaccinationsByUser(user.uid);
      setState(() {
        _vaccinations = vaccinations;
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

  List<VaccinationModel> get _filteredVaccinations {
    if (_selectedLotFilter == null) return _vaccinations;
    return _vaccinations.where((v) => v.lotId == _selectedLotFilter).toList();
  }

  List<String> get _lotNumbers {
    return _vaccinations.map((v) => v.lotId).toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Historial de Vacunación'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (_lotNumbers.isNotEmpty)
            PopupMenuButton<String?>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) => setState(() => _selectedLotFilter = value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('Todos los lotes'),
                ),
                ..._lotNumbers.map((lotId) {
                  final lot = _vaccinations.firstWhere((v) => v.lotId == lotId);
                  return PopupMenuItem(
                    value: lotId,
                    child: Text('Lote ${lot.lotNumber}'),
                  );
                }),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredVaccinations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.vaccines, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No hay vaccaciones registradas',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadVaccinations,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredVaccinations.length,
                itemBuilder: (context, index) {
                  final vaccination = _filteredVaccinations[index];
                  return _buildVaccinationCard(vaccination);
                },
              ),
            ),
    );
  }

  Widget _buildVaccinationCard(VaccinationModel vaccination) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.vaccines, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    Text(
                      vaccination.vaccineName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Lote ${vaccination.lotNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.calendar_today,
                    'Aplicación',
                    DateFormat(
                      'dd/MM/yyyy',
                    ).format(vaccination.applicationDate),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.format_list_numbered,
                    'Dosis',
                    vaccination.dose,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.list,
                    'Método',
                    vaccination.method,
                  ),
                ),
                if (vaccination.nextDoseDate != null)
                  Expanded(
                    child: _buildInfoItem(
                      Icons.event,
                      'Próxima',
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format(vaccination.nextDoseDate!),
                      color: vaccination.isOverdue
                          ? Colors.red
                          : (vaccination.isUpcoming ? Colors.orange : null),
                    ),
                  ),
              ],
            ),
              if (vaccination.notes != null && vaccination.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vaccination.notes!,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(vaccination),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(VaccinationModel vaccination) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar la vacunación de ${vaccination.vaccineName} del lote ${vaccination.lotNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteVaccination(vaccination);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVaccination(VaccinationModel vaccination) async {
    setState(() => _isLoading = true);
    try {
      await _vaccinationService.deleteVaccination(vaccination.id!);
      await _loadVaccinations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vacunación eliminada'), backgroundColor: Colors.green),
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

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ],
    );
  }
}
