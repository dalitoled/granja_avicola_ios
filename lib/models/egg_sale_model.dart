class EggSaleModel {
  final String? id;
  final String userId;
  final DateTime date;
  final String customer;
  final int extraQuantity;
  final double extraPrice;
  final int especialQuantity;
  final double especialPrice;
  final int primeraQuantity;
  final double primeraPrice;
  final int segundaQuantity;
  final double segundaPrice;
  final int terceraQuantity;
  final double terceraPrice;
  final int cuartaQuantity;
  final double cuartaPrice;
  final int quintaQuantity;
  final double quintaPrice;
  final int suciosQuantity;
  final double suciosPrice;
  final int rajadosQuantity;
  final double rajadosPrice;
  final double totalSale;
  final DateTime createdAt;
  final bool isByMount;

  static const double MOUNT_EGGS = 300;

  EggSaleModel({
    this.id,
    required this.userId,
    required this.date,
    required this.customer,
    required this.extraQuantity,
    required this.extraPrice,
    required this.especialQuantity,
    required this.especialPrice,
    required this.primeraQuantity,
    required this.primeraPrice,
    required this.segundaQuantity,
    required this.segundaPrice,
    required this.terceraQuantity,
    required this.terceraPrice,
    required this.cuartaQuantity,
    required this.cuartaPrice,
    required this.quintaQuantity,
    required this.quintaPrice,
    required this.suciosQuantity,
    required this.suciosPrice,
    required this.rajadosQuantity,
    required this.rajadosPrice,
    required this.totalSale,
    required this.createdAt,
    this.isByMount = false,
  });

  factory EggSaleModel.fromMap(Map<String, dynamic> map) {
    return EggSaleModel(
      id: map['id'],
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date']),
      customer: map['customer'] ?? '',
      extraQuantity: map['extraQuantity'] ?? 0,
      extraPrice: (map['extraPrice'] ?? 0).toDouble(),
      especialQuantity: map['especialQuantity'] ?? 0,
      especialPrice: (map['especialPrice'] ?? 0).toDouble(),
      primeraQuantity: map['primeraQuantity'] ?? 0,
      primeraPrice: (map['primeraPrice'] ?? 0).toDouble(),
      segundaQuantity: map['segundaQuantity'] ?? 0,
      segundaPrice: (map['segundaPrice'] ?? 0).toDouble(),
      terceraQuantity: map['terceraQuantity'] ?? 0,
      terceraPrice: (map['terceraPrice'] ?? 0).toDouble(),
      cuartaQuantity: map['cuartaQuantity'] ?? 0,
      cuartaPrice: (map['cuartaPrice'] ?? 0).toDouble(),
      quintaQuantity: map['quintaQuantity'] ?? 0,
      quintaPrice: (map['quintaPrice'] ?? 0).toDouble(),
      suciosQuantity: map['suciosQuantity'] ?? 0,
      suciosPrice: (map['suciosPrice'] ?? 0).toDouble(),
      rajadosQuantity: map['rajadosQuantity'] ?? 0,
      rajadosPrice: (map['rajadosPrice'] ?? 0).toDouble(),
      totalSale: (map['totalSale'] ?? 0).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      isByMount: map['isByMount'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'customer': customer,
      'extraQuantity': extraQuantity,
      'extraPrice': extraPrice,
      'especialQuantity': especialQuantity,
      'especialPrice': especialPrice,
      'primeraQuantity': primeraQuantity,
      'primeraPrice': primeraPrice,
      'segundaQuantity': segundaQuantity,
      'segundaPrice': segundaPrice,
      'terceraQuantity': terceraQuantity,
      'terceraPrice': terceraPrice,
      'cuartaQuantity': cuartaQuantity,
      'cuartaPrice': cuartaPrice,
      'quintaQuantity': quintaQuantity,
      'quintaPrice': quintaPrice,
      'suciosQuantity': suciosQuantity,
      'suciosPrice': suciosPrice,
      'rajadosQuantity': rajadosQuantity,
      'rajadosPrice': rajadosPrice,
      'totalSale': totalSale,
      'createdAt': createdAt.toIso8601String(),
      'isByMount': isByMount,
    };
  }

  double calculateTotal() {
    return (extraQuantity * extraPrice) +
        (especialQuantity * especialPrice) +
        (primeraQuantity * primeraPrice) +
        (segundaQuantity * segundaPrice) +
        (terceraQuantity * terceraPrice) +
        (cuartaQuantity * cuartaPrice) +
        (quintaQuantity * quintaPrice) +
        (suciosQuantity * suciosPrice) +
        (rajadosQuantity * rajadosPrice);
  }

  EggSaleModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? customer,
    int? extraQuantity,
    double? extraPrice,
    int? especialQuantity,
    double? especialPrice,
    int? primeraQuantity,
    double? primeraPrice,
    int? segundaQuantity,
    double? segundaPrice,
    int? terceraQuantity,
    double? terceraPrice,
    int? cuartaQuantity,
    double? cuartaPrice,
    int? quintaQuantity,
    double? quintaPrice,
    int? suciosQuantity,
    double? suciosPrice,
    int? rajadosQuantity,
    double? rajadosPrice,
    double? totalSale,
    DateTime? createdAt,
    bool? isByMount,
  }) {
    return EggSaleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      customer: customer ?? this.customer,
      extraQuantity: extraQuantity ?? this.extraQuantity,
      extraPrice: extraPrice ?? this.extraPrice,
      especialQuantity: especialQuantity ?? this.especialQuantity,
      especialPrice: especialPrice ?? this.especialPrice,
      primeraQuantity: primeraQuantity ?? this.primeraQuantity,
      primeraPrice: primeraPrice ?? this.primeraPrice,
      segundaQuantity: segundaQuantity ?? this.segundaQuantity,
      segundaPrice: segundaPrice ?? this.segundaPrice,
      terceraQuantity: terceraQuantity ?? this.terceraQuantity,
      terceraPrice: terceraPrice ?? this.terceraPrice,
      cuartaQuantity: cuartaQuantity ?? this.cuartaQuantity,
      cuartaPrice: cuartaPrice ?? this.cuartaPrice,
      quintaQuantity: quintaQuantity ?? this.quintaQuantity,
      quintaPrice: quintaPrice ?? this.quintaPrice,
      suciosQuantity: suciosQuantity ?? this.suciosQuantity,
      suciosPrice: suciosPrice ?? this.suciosPrice,
      rajadosQuantity: rajadosQuantity ?? this.rajadosQuantity,
      rajadosPrice: rajadosPrice ?? this.rajadosPrice,
      totalSale: totalSale ?? this.totalSale,
      createdAt: createdAt ?? this.createdAt,
      isByMount: isByMount ?? this.isByMount,
    );
  }

  double getDisplayQuantity(String category) {
    if (isByMount) {
      int quantity;
      switch (category) {
        case 'extra': quantity = extraQuantity; break;
        case 'especial': quantity = especialQuantity; break;
        case 'primera': quantity = primeraQuantity; break;
        case 'segunda': quantity = segundaQuantity; break;
        case 'tercera': quantity = terceraQuantity; break;
        case 'cuarta': quantity = cuartaQuantity; break;
        case 'quinta': quantity = quintaQuantity; break;
        case 'sucios': quantity = suciosQuantity; break;
        case 'rajados': quantity = rajadosQuantity; break;
        default: quantity = 0;
      }
      return quantity / MOUNT_EGGS;
    }
    return 0;
  }

  int getFieldQuantity(String category) {
    switch (category) {
      case 'extra': return extraQuantity;
      case 'especial': return especialQuantity;
      case 'primera': return primeraQuantity;
      case 'segunda': return segundaQuantity;
      case 'tercera': return terceraQuantity;
      case 'cuarta': return cuartaQuantity;
      case 'quinta': return quintaQuantity;
      case 'sucios': return suciosQuantity;
      case 'rajados': return rajadosQuantity;
      default: return 0;
    }
  }

  double getFieldPrice(String category) {
    switch (category) {
      case 'extra': return extraPrice;
      case 'especial': return especialPrice;
      case 'primera': return primeraPrice;
      case 'segunda': return segundaPrice;
      case 'tercera': return terceraPrice;
      case 'cuarta': return cuartaPrice;
      case 'quinta': return quintaPrice;
      case 'sucios': return suciosPrice;
      case 'rajados': return rajadosPrice;
      default: return 0;
    }
  }
}
