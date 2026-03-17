import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/vaccination_model.dart';
import '../services/vaccination_service.dart';

class VaccinationCalendarScreen extends StatefulWidget {
  const VaccinationCalendarScreen({super.key});

  @override
  State<VaccinationCalendarScreen> createState() =>
      _VaccinationCalendarScreenState();
}

class _VaccinationCalendarScreenState extends State<VaccinationCalendarScreen> {
  final VaccinationService _vaccinationService = VaccinationService();
  List<VaccinationModel> _upcomingVaccinations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUpcomingVaccinations();
  }

  Future<void> _loadUpcomingVaccinations() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      List<VaccinationModel> upcoming = await _vaccinationService
          .getAllFutureVaccinations(user.uid);
      setState(() {
        _upcomingVaccinations = upcoming;
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

  List<VaccinationModel> get _overdueVaccinations {
    return _upcomingVaccinations.where((v) => v.isOverdue).toList();
  }

  List<VaccinationModel> get _dueSoonVaccinations {
    return _upcomingVaccinations
        .where((v) => v.isUpcoming && !v.isOverdue)
        .toList();
  }

  List<VaccinationModel> get _futureVaccinations {
    return _upcomingVaccinations
        .where((v) => !v.isUpcoming && !v.isOverdue)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Calendario de Vacunas'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUpcomingVaccinations,
              child: _upcomingVaccinations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay próximas vacunas',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Registre vacunas con fechas de próxima dosis',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_overdueVaccinations.isNotEmpty) ...[
                            _buildSectionHeader(
                              'Atrasadas',
                              Colors.red,
                              _overdueVaccinations.length,
                            ),
                            const SizedBox(height: 8),
                            ..._overdueVaccinations.map(
                              (v) => _buildVaccinationCard(v, isOverdue: true),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_dueSoonVaccinations.isNotEmpty) ...[
                            _buildSectionHeader(
                              'Próximas (3 días)',
                              Colors.orange,
                              _dueSoonVaccinations.length,
                            ),
                            const SizedBox(height: 8),
                            ..._dueSoonVaccinations.map(
                              (v) => _buildVaccinationCard(v, isDueSoon: true),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_futureVaccinations.isNotEmpty) ...[
                            _buildSectionHeader(
                              'Próximas',
                              const Color(0xFF2E7D32),
                              _futureVaccinations.length,
                            ),
                            const SizedBox(height: 8),
                            ..._futureVaccinations.map(
                              (v) => _buildVaccinationCard(v),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVaccinationCard(
    VaccinationModel vaccination, {
    bool isOverdue = false,
    bool isDueSoon = false,
  }) {
    Color statusColor = isOverdue
        ? Colors.red
        : (isDueSoon ? Colors.orange : const Color(0xFF2E7D32));
    String daysText = '';
    if (vaccination.daysUntilNext != null) {
      if (vaccination.daysUntilNext! < 0) {
        daysText = 'Hace ${-vaccination.daysUntilNext!} días';
      } else if (vaccination.daysUntilNext == 0) {
        daysText = 'Hoy';
      } else if (vaccination.daysUntilNext == 1) {
        daysText = 'Mañana';
      } else {
        daysText = 'En ${vaccination.daysUntilNext} días';
      }
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: statusColor, width: 4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    vaccination.vaccineName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                  child: Text(
                    daysText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.egg_alt, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Lote ${vaccination.lotNumber}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.format_list_numbered,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Dosis: ${vaccination.dose}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (vaccination.nextDoseDate != null)
              Row(
                children: [
                  Icon(Icons.event, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    'Próxima dosis: ${DateFormat('dd/MM/yyyy').format(vaccination.nextDoseDate!)}',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
