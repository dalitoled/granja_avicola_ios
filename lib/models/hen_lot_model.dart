class HenLotModel {
  final String? id;
  final String userId;
  final String lotNumber;
  final String breed;
  final String? supplier;
  final DateTime startDate;
  final int initialHens;
  final int currentHens;
  final String? notes;
  final DateTime createdAt;

  HenLotModel({
    this.id,
    required this.userId,
    required this.lotNumber,
    required this.breed,
    this.supplier,
    required this.startDate,
    required this.initialHens,
    required this.currentHens,
    this.notes,
    required this.createdAt,
  });

  factory HenLotModel.fromMap(Map<String, dynamic> map) {
    return HenLotModel(
      id: map['id'],
      userId: map['userId'] ?? '',
      lotNumber: map['lotNumber'] ?? '',
      breed: map['breed'] ?? '',
      supplier: map['supplier'],
      startDate: DateTime.parse(map['startDate']),
      initialHens: map['initialHens'] ?? 0,
      currentHens: map['currentHens'] ?? 0,
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'lotNumber': lotNumber,
      'breed': breed,
      'supplier': supplier,
      'startDate': startDate.toIso8601String(),
      'initialHens': initialHens,
      'currentHens': currentHens,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  int get ageInWeeks {
    return DateTime.now().difference(startDate).inDays ~/ 7;
  }

  String get status {
    if (currentHens == 0) {
      return 'Inactivo';
    }
    int mortality = initialHens - currentHens;
    double mortalityRate = (mortality / initialHens) * 100;
    if (mortalityRate > 20) {
      return 'Alta mortalidad';
    }
    return 'Activo';
  }

  HenLotModel copyWith({
    String? id,
    String? userId,
    String? lotNumber,
    String? breed,
    String? supplier,
    DateTime? startDate,
    int? initialHens,
    int? currentHens,
    String? notes,
    DateTime? createdAt,
  }) {
    return HenLotModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lotNumber: lotNumber ?? this.lotNumber,
      breed: breed ?? this.breed,
      supplier: supplier ?? this.supplier,
      startDate: startDate ?? this.startDate,
      initialHens: initialHens ?? this.initialHens,
      currentHens: currentHens ?? this.currentHens,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
