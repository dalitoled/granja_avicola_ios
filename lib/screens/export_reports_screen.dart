import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/export_service.dart';

class ExportReportsScreen extends StatefulWidget {
  const ExportReportsScreen({super.key});

  @override
  State<ExportReportsScreen> createState() => _ExportReportsScreenState();
}

class _ExportReportsScreenState extends State<ExportReportsScreen> {
  final ExportService _exportService = ExportService();

  bool _isLoading = false;
  String? _selectedReport;
  String _selectedFormat = 'PDF';
  int _selectedDays = 30;

  final List<Map<String, dynamic>> _reportTypes = [
    {
      'id': 'production',
      'title': 'Producción',
      'icon': Icons.egg,
      'color': const Color(0xFFFF8C00),
    },
    {
      'id': 'feed',
      'title': 'Alimento',
      'icon': Icons.restaurant,
      'color': const Color(0xFF8B4513),
    },
    {
      'id': 'financial',
      'title': 'Financiero',
      'icon': Icons.attach_money,
      'color': const Color(0xFF2E7D32),
    },
    {
      'id': 'mortality',
      'title': 'Mortalidad',
      'icon': Icons.warning,
      'color': const Color(0xFFE53935),
    },
  ];

  final List<Map<String, dynamic>> _periods = [
    {'days': 7, 'label': '7 días'},
    {'days': 14, 'label': '14 días'},
    {'days': 30, 'label': '30 días'},
    {'days': 90, 'label': '90 días'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Exportar Reportes'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportTypeSection(),
            const SizedBox(height: 24),
            _buildPeriodSection(),
            const SizedBox(height: 24),
            _buildFormatSection(),
            const SizedBox(height: 24),
            _buildExportButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seleccionar Reporte',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3,
          children: _reportTypes.map((report) {
            final isSelected = _selectedReport == report['id'];
            return InkWell(
              onTap: () => setState(() => _selectedReport = report['id']),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected ? report['color'] : Colors.white,
                  border: Border.all(
                    color: isSelected ? report['color'] : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      report['icon'],
                      size: 32,
                      color: isSelected ? Colors.white : report['color'],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPeriodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Período',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _periods.map((period) {
            final isSelected = _selectedDays == period['days'];
            return ChoiceChip(
              label: Text(period['label']),
              selected: isSelected,
              selectedColor: const Color(0xFF2E7D32),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedDays = period['days']);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFormatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Formato',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildFormatOption('PDF', Icons.picture_as_pdf)),
            const SizedBox(width: 12),
            Expanded(child: _buildFormatOption('Excel', Icons.table_chart)),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatOption(String format, IconData icon) {
    final isSelected = _selectedFormat == format;
    return InkWell(
      onTap: () => setState(() => _selectedFormat = format),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              format,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _selectedReport == null || _isLoading ? null : _exportReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8C00),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.download),
        label: Text(
          _isLoading ? 'Generando...' : 'Generar Reporte',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _exportReport() async {
    if (_selectedReport == null) return;

    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      File file;
      String fileName;

      switch (_selectedReport) {
        case 'production':
          if (_selectedFormat == 'PDF') {
            file = await _exportService.exportProductionPDF(
              user.uid,
              _selectedDays,
            );
            fileName = 'Reporte de Producción';
          } else {
            file = await _exportService.exportProductionExcel(
              user.uid,
              _selectedDays,
            );
            fileName = 'Reporte de Producción';
          }
          break;
        case 'feed':
          if (_selectedFormat == 'PDF') {
            file = await _exportService.exportFeedPDF(user.uid, _selectedDays);
            fileName = 'Reporte de Alimento';
          } else {
            file = await _exportService.exportFeedExcel(
              user.uid,
              _selectedDays,
            );
            fileName = 'Reporte de Alimento';
          }
          break;
        case 'financial':
          if (_selectedFormat == 'PDF') {
            file = await _exportService.exportFinancialPDF(
              user.uid,
              _selectedDays,
            );
            fileName = 'Reporte Financiero';
          } else {
            file = await _exportService.exportFinancialExcel(
              user.uid,
              _selectedDays,
            );
            fileName = 'Reporte Financiero';
          }
          break;
        case 'mortality':
          if (_selectedFormat == 'PDF') {
            file = await _exportService.exportMortalityPDF(
              user.uid,
              _selectedDays,
            );
            fileName = 'Reporte de Mortalidad';
          } else {
            file = await _exportService.exportMortalityExcel(
              user.uid,
              _selectedDays,
            );
            fileName = 'Reporte de Mortalidad';
          }
          break;
        default:
          throw Exception('Reporte no válido');
      }

      await _exportService.shareFile(file, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte generado exitosamente'),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
