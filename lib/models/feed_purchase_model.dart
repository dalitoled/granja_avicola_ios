class FeedPurchaseModel {
  final String? id;
  final String userId;
  final String feedType;
  final double quantityKg;
  final double pricePerKg;
  final double totalCost;
  final String supplier;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  FeedPurchaseModel({
    this.id,
    required this.userId,
    required this.feedType,
    required this.quantityKg,
    required this.pricePerKg,
    required this.totalCost,
    required this.supplier,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  factory FeedPurchaseModel.fromMap(Map<String, dynamic> map) {
    return FeedPurchaseModel(
      id: map['id'],
      userId: map['userId'] ?? '',
      feedType: map['feedType'] ?? '',
      quantityKg: (map['quantityKg'] ?? 0).toDouble(),
      pricePerKg: (map['pricePerKg'] ?? 0).toDouble(),
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      supplier: map['supplier'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'feedType': feedType,
      'quantityKg': quantityKg,
      'pricePerKg': pricePerKg,
      'totalCost': totalCost,
      'supplier': supplier,
      'date': date.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  FeedPurchaseModel copyWith({
    String? id,
    String? userId,
    String? feedType,
    double? quantityKg,
    double? pricePerKg,
    double? totalCost,
    String? supplier,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
  }) {
    return FeedPurchaseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      feedType: feedType ?? this.feedType,
      quantityKg: quantityKg ?? this.quantityKg,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      totalCost: totalCost ?? this.totalCost,
      supplier: supplier ?? this.supplier,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
