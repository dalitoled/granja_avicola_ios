class VaccinationModel {
  final String? id;
  final String userId;
  final String lotId;
  final String lotNumber;
  final String vaccineName;
  final DateTime applicationDate;
  final DateTime? nextDoseDate;
  final String dose;
  final String method;
  final String? notes;
  final DateTime createdAt;

  VaccinationModel({
    this.id,
    required this.userId,
    required this.lotId,
    required this.lotNumber,
    required this.vaccineName,
    required this.applicationDate,
    this.nextDoseDate,
    required this.dose,
    required this.method,
    this.notes,
    required this.createdAt,
  });

  factory VaccinationModel.fromMap(Map<String, dynamic> map) {
    return VaccinationModel(
      id: map['id'],
      userId: map['userId'] ?? '',
      lotId: map['lotId'] ?? '',
      lotNumber: map['lotNumber'] ?? '',
      vaccineName: map['vaccineName'] ?? '',
      applicationDate: DateTime.parse(map['applicationDate'] as String),
      nextDoseDate: map['nextDoseDate'] != null
          ? DateTime.parse(map['nextDoseDate'])
          : null,
      dose: map['dose'] ?? '',
      method: map['method'] ?? '',
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
      'vaccineName': vaccineName,
      'applicationDate': applicationDate.toIso8601String(),
      'nextDoseDate': nextDoseDate?.toIso8601String(),
      'dose': dose,
      'method': method,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isUpcoming {
    if (nextDoseDate == null) return false;
    int daysUntilNext = nextDoseDate!.difference(DateTime.now()).inDays;
    return daysUntilNext >= 0 && daysUntilNext <= 3;
  }

  bool get isOverdue {
    if (nextDoseDate == null) return false;
    return nextDoseDate!.isBefore(DateTime.now());
  }

  int? get daysUntilNext {
    if (nextDoseDate == null) return null;
    return nextDoseDate!.difference(DateTime.now()).inDays;
  }
}
