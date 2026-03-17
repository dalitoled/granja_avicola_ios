class FarmExpenseModel {
  final String? id;
  final String userId;
  final DateTime date;
  final String category;
  final String description;
  final double amount;
  final String paymentMethod;
  final String? notes;
  final DateTime createdAt;

  FarmExpenseModel({
    this.id,
    required this.userId,
    required this.date,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
  });

  factory FarmExpenseModel.fromMap(Map<String, dynamic> map) {
    return FarmExpenseModel(
      id: map['id'],
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date']),
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'category': category,
      'description': description,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  FarmExpenseModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? category,
    String? description,
    double? amount,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
  }) {
    return FarmExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
