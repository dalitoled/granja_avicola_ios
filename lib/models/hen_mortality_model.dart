class HenMortalityModel {
  final String? id;
  final String userId;
  final String lotId;
  final String lotNumber;
  final DateTime date;
  final int deadHens;
  final String cause;
  final String? notes;
  final DateTime createdAt;

  HenMortalityModel({
    this.id,
    required this.userId,
    required this.lotId,
    required this.lotNumber,
    required this.date,
    required this.deadHens,
    required this.cause,
    this.notes,
    required this.createdAt,
  });

  factory HenMortalityModel.fromMap(Map<String, dynamic> map) {
    return HenMortalityModel(
      id: map['id'],
      userId: map['userId'] ?? '',
      lotId: map['lotId'] ?? '',
      lotNumber: map['lotNumber'] ?? '',
      date: DateTime.parse(map['date']),
      deadHens: map['deadHens'] ?? 0,
      cause: map['cause'] ?? '',
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'lotId': lotId,
      'lotNumber': lotNumber,
      'date': date.toIso8601String(),
      'deadHens': deadHens,
      'cause': cause,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
