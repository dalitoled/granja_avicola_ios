class FeedConsumptionModel {
  final String? id;
  final String userId;
  final DateTime date;
  final int hensCount;
  final double feedKg;
  final String feedType;
  final double pricePerKg;
  final double feedCost;
  final String? notes;
  final DateTime createdAt;

  FeedConsumptionModel({
    this.id,
    required this.userId,
    required this.date,
    required this.hensCount,
    required this.feedKg,
    required this.feedType,
    required this.pricePerKg,
    required this.feedCost,
    this.notes,
    required this.createdAt,
  });

  factory FeedConsumptionModel.fromMap(Map<String, dynamic> map) {
    return FeedConsumptionModel(
      id: map['id'],
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date']),
      hensCount: map['hensCount'] ?? 0,
      feedKg: (map['feedKg'] ?? 0).toDouble(),
      feedType: map['feedType'] ?? '',
      pricePerKg: (map['pricePerKg'] ?? 0).toDouble(),
      feedCost: (map['feedCost'] ?? 0).toDouble(),
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'hensCount': hensCount,
      'feedKg': feedKg,
      'feedType': feedType,
      'pricePerKg': pricePerKg,
      'feedCost': feedCost,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static double calculateFeedCost(double feedKg, double pricePerKg) {
    return feedKg * pricePerKg;
  }
}
