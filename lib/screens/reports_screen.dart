import 'package:flutter/material.dart';
import 'production_report_screen.dart';
import 'feed_report_screen.dart';
import 'financial_report_screen.dart';
import 'mortality_report_screen.dart';
import 'export_reports_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('Reportes y Análisis'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.9,
          children: [
            _buildReportCard(
              context: context,
              icon: Icons.egg,
              title: 'Producción',
              description: 'Producción de huevos',
              color: const Color(0xFFFF8C00),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductionReportScreen(),
                ),
              ),
            ),
            _buildReportCard(
              context: context,
              icon: Icons.restaurant,
              title: 'Alimento',
              description: 'Consumo y conversión',
              color: const Color(0xFF8B4513),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FeedReportScreen(),
                ),
              ),
            ),
            _buildReportCard(
              context: context,
              icon: Icons.attach_money,
              title: 'Financiero',
              description: 'Ingresos y gastos',
              color: const Color(0xFF2E7D32),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FinancialReportScreen(),
                ),
              ),
            ),
            _buildReportCard(
              context: context,
              icon: Icons.warning,
              title: 'Mortalidad',
              description: 'Tasas de mortalidad',
              color: const Color(0xFFE53935),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MortalityReportScreen(),
                ),
              ),
            ),
            _buildReportCard(
              context: context,
              icon: Icons.download,
              title: 'Exportar',
              description: 'PDF y Excel',
              color: const Color(0xFF607D8B),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExportReportsScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity( 0.7)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 50, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
