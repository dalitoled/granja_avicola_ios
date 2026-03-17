enum AlertSeverity { normal, warning, critical }

class AlertModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final AlertSeverity severity;
  final String type;

  AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.severity,
    required this.type,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => AlertSeverity.warning,
      ),
      type: map['type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'severity': severity.name,
      'type': type,
    };
  }

  static AlertModel lowProduction({
    required int todayProduction,
    required double weeklyAverage,
  }) {
    final percentage = weeklyAverage > 0
        ? (todayProduction / weeklyAverage * 100)
        : 0;
    return AlertModel(
      id: 'low_production_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Producción Baja',
      description:
          'La producción de hoy ($todayProduction huevos) está por debajo del 85% del promedio semanal (${weeklyAverage.toStringAsFixed(0)} huevos). Producción actual: ${percentage.toStringAsFixed(1)}%',
      date: DateTime.now(),
      severity: percentage < 70
          ? AlertSeverity.critical
          : AlertSeverity.warning,
      type: 'low_production',
    );
  }

  static AlertModel highMortality({
    required int deaths,
    required int threshold,
  }) {
    final isCritical = deaths > threshold * 1.5;
    return AlertModel(
      id: 'high_mortality_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Mortalidad Alta',
      description:
          'Se han registrado $deaths muertes en los últimos 3 días. Umbral: $threshold. ${isCritical ? '¡Situación crítica!' : 'Revisar inmediatamente.'}',
      date: DateTime.now(),
      severity: isCritical ? AlertSeverity.critical : AlertSeverity.warning,
      type: 'high_mortality',
    );
  }

  static AlertModel lowFeedStock({
    required double currentStock,
    required double minimumStock,
  }) {
    final isCritical = currentStock <= minimumStock * 0.5;
    return AlertModel(
      id: 'low_feed_stock_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Stock de Alimento Bajo',
      description:
          'El inventario de alimento está en ${currentStock.toStringAsFixed(1)} kg. Stock mínimo recomendado: ${minimumStock.toStringAsFixed(1)} kg. ${isCritical ? '¡Pedido urgente!' : 'Considerar reordenar.'}',
      date: DateTime.now(),
      severity: isCritical ? AlertSeverity.critical : AlertSeverity.warning,
      type: 'low_feed_stock',
    );
  }

  static AlertModel upcomingVaccine({
    required String vaccineName,
    required DateTime nextDate,
    required int daysUntil,
  }) {
    final isCritical = daysUntil <= 1;
    return AlertModel(
      id: 'vaccine_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Vacuna Pendiente',
      description:
          '$vaccineName programada para el ${_formatDate(nextDate)}. ${daysUntil == 0 ? '¡Es hoy!' : 'Faltan $daysUntil día(s).'}',
      date: DateTime.now(),
      severity: isCritical ? AlertSeverity.critical : AlertSeverity.warning,
      type: 'upcoming_vaccine',
    );
  }

  static AlertModel normal({required String message}) {
    return AlertModel(
      id: 'normal_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Todo Normal',
      description: message,
      date: DateTime.now(),
      severity: AlertSeverity.normal,
      type: 'normal',
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
