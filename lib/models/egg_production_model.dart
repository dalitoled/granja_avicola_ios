class EggProductionModel {
  final String? id;
  final String userId;
  final DateTime date;
  final int extra;
  final int especial;
  final int primera;
  final int segunda;
  final int tercera;
  final int cuarta;
  final int quinta;
  final int sucios;
  final int rajados;
  final int descarte;
  final int totalHuevos;
  final DateTime createdAt;

  EggProductionModel({
    this.id,
    required this.userId,
    required this.date,
    required this.extra,
    required this.especial,
    required this.primera,
    required this.segunda,
    required this.tercera,
    required this.cuarta,
    required this.quinta,
    required this.sucios,
    required this.rajados,
    required this.descarte,
    required this.totalHuevos,
    required this.createdAt,
  });

  factory EggProductionModel.fromMap(Map<String, dynamic> map) {
    return EggProductionModel(
      id: map['id'],
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date']),
      extra: map['extra'] ?? 0,
      especial: map['especial'] ?? 0,
      primera: map['primera'] ?? 0,
      segunda: map['segunda'] ?? 0,
      tercera: map['tercera'] ?? 0,
      cuarta: map['cuarta'] ?? 0,
      quinta: map['quinta'] ?? 0,
      sucios: map['sucios'] ?? 0,
      rajados: map['rajados'] ?? 0,
      descarte: map['descarte'] ?? 0,
      totalHuevos: map['totalHuevos'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'extra': extra,
      'especial': especial,
      'primera': primera,
      'segunda': segunda,
      'tercera': tercera,
      'cuarta': cuarta,
      'quinta': quinta,
      'sucios': sucios,
      'rajados': rajados,
      'descarte': descarte,
      'totalHuevos': totalHuevos,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  int calculateTotal() {
    return extra +
        especial +
        primera +
        segunda +
        tercera +
        cuarta +
        quinta +
        sucios +
        rajados +
        descarte;
  }
}
