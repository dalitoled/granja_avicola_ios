class FeedInventoryModel {
  final String? id;
  final String userId;
  final String feedType;
  final double stockKg;
  final double minimumStock;
  final double pricePerKg;
  final DateTime updatedAt;

  FeedInventoryModel({
    this.id,
    required this.userId,
    required this.feedType,
    required this.stockKg,
    required this.minimumStock,
    this.pricePerKg = 0,
    required this.updatedAt,
  });

  factory FeedInventoryModel.fromMap(Map<String, dynamic> map) {
    return FeedInventoryModel(
      id: map['id'],
      userId: map['userId'] ?? '',
      feedType: map['feedType'] ?? '',
      stockKg: (map['stockKg'] ?? 0).toDouble(),
      minimumStock: (map['minimumStock'] ?? 0).toDouble(),
      pricePerKg: (map['pricePerKg'] ?? 0).toDouble(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'feedType': feedType,
      'stockKg': stockKg,
      'minimumStock': minimumStock,
      'pricePerKg': pricePerKg,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FeedInventoryModel copyWith({
    String? id,
    String? userId,
    String? feedType,
    double? stockKg,
    double? minimumStock,
    double? pricePerKg,
    DateTime? updatedAt,
  }) {
    return FeedInventoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      feedType: feedType ?? this.feedType,
      stockKg: stockKg ?? this.stockKg,
      minimumStock: minimumStock ?? this.minimumStock,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLowStock => stockKg <= minimumStock;

  double get stockPercentage {
    if (minimumStock == 0) return 1.0;
    return (stockKg / (minimumStock * 2)).clamp(0.0, 1.0);
  }
}
