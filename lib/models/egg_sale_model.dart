class EggSaleModel {
  final String? id;
  final String userId;
  final DateTime date;
  final String customer;
  final int extraMounts;
  final int extraMaples;
  final int extraUnits;
  final double extraPrice;
  final int especialMounts;
  final int especialMaples;
  final int especialUnits;
  final double especialPrice;
  final int primeraMounts;
  final int primeraMaples;
  final int primeraUnits;
  final double primeraPrice;
  final int segundaMounts;
  final int segundaMaples;
  final int segundaUnits;
  final double segundaPrice;
  final int terceraMounts;
  final int terceraMaples;
  final int terceraUnits;
  final double terceraPrice;
  final int cuartaMounts;
  final int cuartaMaples;
  final int cuartaUnits;
  final double cuartaPrice;
  final int quintaMounts;
  final int quintaMaples;
  final int quintaUnits;
  final double quintaPrice;
  final int suciosMounts;
  final int suciosMaples;
  final int suciosUnits;
  final double suciosPrice;
  final int rajadosMounts;
  final int rajadosMaples;
  final int rajadosUnits;
  final double rajadosPrice;
  final double totalSale;
  final DateTime createdAt;

  static const int MOUNT_EGGS = 300;
  static const int MAPLE_EGGS = 30;

  EggSaleModel({
    this.id,
    required this.userId,
    required this.date,
    required this.customer,
    this.extraMounts = 0,
    this.extraMaples = 0,
    this.extraUnits = 0,
    required this.extraPrice,
    this.especialMounts = 0,
    this.especialMaples = 0,
    this.especialUnits = 0,
    required this.especialPrice,
    this.primeraMounts = 0,
    this.primeraMaples = 0,
    this.primeraUnits = 0,
    required this.primeraPrice,
    this.segundaMounts = 0,
    this.segundaMaples = 0,
    this.segundaUnits = 0,
    required this.segundaPrice,
    this.terceraMounts = 0,
    this.terceraMaples = 0,
    this.terceraUnits = 0,
    required this.terceraPrice,
    this.cuartaMounts = 0,
    this.cuartaMaples = 0,
    this.cuartaUnits = 0,
    required this.cuartaPrice,
    this.quintaMounts = 0,
    this.quintaMaples = 0,
    this.quintaUnits = 0,
    required this.quintaPrice,
    this.suciosMounts = 0,
    this.suciosMaples = 0,
    this.suciosUnits = 0,
    required this.suciosPrice,
    this.rajadosMounts = 0,
    this.rajadosMaples = 0,
    this.rajadosUnits = 0,
    required this.rajadosPrice,
    required this.totalSale,
    required this.createdAt,
  });

  factory EggSaleModel.fromMap(Map<String, dynamic> map) {
    return EggSaleModel(
      id: map['id'],
      userId: map['userId'] ?? '',
      date: DateTime.parse(map['date']),
      customer: map['customer'] ?? '',
      extraMounts: map['extraMounts'] ?? 0,
      extraMaples: map['extraMaples'] ?? 0,
      extraUnits: map['extraUnits'] ?? 0,
      extraPrice: (map['extraPrice'] ?? 0).toDouble(),
      especialMounts: map['especialMounts'] ?? 0,
      especialMaples: map['especialMaples'] ?? 0,
      especialUnits: map['especialUnits'] ?? 0,
      especialPrice: (map['especialPrice'] ?? 0).toDouble(),
      primeraMounts: map['primeraMounts'] ?? 0,
      primeraMaples: map['primeraMaples'] ?? 0,
      primeraUnits: map['primeraUnits'] ?? 0,
      primeraPrice: (map['primeraPrice'] ?? 0).toDouble(),
      segundaMounts: map['segundaMounts'] ?? 0,
      segundaMaples: map['segundaMaples'] ?? 0,
      segundaUnits: map['segundaUnits'] ?? 0,
      segundaPrice: (map['segundaPrice'] ?? 0).toDouble(),
      terceraMounts: map['terceraMounts'] ?? 0,
      terceraMaples: map['terceraMaples'] ?? 0,
      terceraUnits: map['terceraUnits'] ?? 0,
      terceraPrice: (map['terceraPrice'] ?? 0).toDouble(),
      cuartaMounts: map['cuartaMounts'] ?? 0,
      cuartaMaples: map['cuartaMaples'] ?? 0,
      cuartaUnits: map['cuartaUnits'] ?? 0,
      cuartaPrice: (map['cuartaPrice'] ?? 0).toDouble(),
      quintaMounts: map['quintaMounts'] ?? 0,
      quintaMaples: map['quintaMaples'] ?? 0,
      quintaUnits: map['quintaUnits'] ?? 0,
      quintaPrice: (map['quintaPrice'] ?? 0).toDouble(),
      suciosMounts: map['suciosMounts'] ?? 0,
      suciosMaples: map['suciosMaples'] ?? 0,
      suciosUnits: map['suciosUnits'] ?? 0,
      suciosPrice: (map['suciosPrice'] ?? 0).toDouble(),
      rajadosMounts: map['rajadosMounts'] ?? 0,
      rajadosMaples: map['rajadosMaples'] ?? 0,
      rajadosUnits: map['rajadosUnits'] ?? 0,
      rajadosPrice: (map['rajadosPrice'] ?? 0).toDouble(),
      totalSale: (map['totalSale'] ?? 0).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'customer': customer,
      'extraMounts': extraMounts,
      'extraMaples': extraMaples,
      'extraUnits': extraUnits,
      'extraPrice': extraPrice,
      'especialMounts': especialMounts,
      'especialMaples': especialMaples,
      'especialUnits': especialUnits,
      'especialPrice': especialPrice,
      'primeraMounts': primeraMounts,
      'primeraMaples': primeraMaples,
      'primeraUnits': primeraUnits,
      'primeraPrice': primeraPrice,
      'segundaMounts': segundaMounts,
      'segundaMaples': segundaMaples,
      'segundaUnits': segundaUnits,
      'segundaPrice': segundaPrice,
      'terceraMounts': terceraMounts,
      'terceraMaples': terceraMaples,
      'terceraUnits': terceraUnits,
      'terceraPrice': terceraPrice,
      'cuartaMounts': cuartaMounts,
      'cuartaMaples': cuartaMaples,
      'cuartaUnits': cuartaUnits,
      'cuartaPrice': cuartaPrice,
      'quintaMounts': quintaMounts,
      'quintaMaples': quintaMaples,
      'quintaUnits': quintaUnits,
      'quintaPrice': quintaPrice,
      'suciosMounts': suciosMounts,
      'suciosMaples': suciosMaples,
      'suciosUnits': suciosUnits,
      'suciosPrice': suciosPrice,
      'rajadosMounts': rajadosMounts,
      'rajadosMaples': rajadosMaples,
      'rajadosUnits': rajadosUnits,
      'rajadosPrice': rajadosPrice,
      'totalSale': totalSale,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  int _getTotalUnits(String category) {
    switch (category) {
      case 'extra': return extraMounts * MOUNT_EGGS + extraMaples * MAPLE_EGGS + extraUnits;
      case 'especial': return especialMounts * MOUNT_EGGS + especialMaples * MAPLE_EGGS + especialUnits;
      case 'primera': return primeraMounts * MOUNT_EGGS + primeraMaples * MAPLE_EGGS + primeraUnits;
      case 'segunda': return segundaMounts * MOUNT_EGGS + segundaMaples * MAPLE_EGGS + segundaUnits;
      case 'tercera': return terceraMounts * MOUNT_EGGS + terceraMaples * MAPLE_EGGS + terceraUnits;
      case 'cuarta': return cuartaMounts * MOUNT_EGGS + cuartaMaples * MAPLE_EGGS + cuartaUnits;
      case 'quinta': return quintaMounts * MOUNT_EGGS + quintaMaples * MAPLE_EGGS + quintaUnits;
      case 'sucios': return suciosMounts * MOUNT_EGGS + suciosMaples * MAPLE_EGGS + suciosUnits;
      case 'rajados': return rajadosMounts * MOUNT_EGGS + rajadosMaples * MAPLE_EGGS + rajadosUnits;
      default: return 0;
    }
  }

  double getPrice(String category) {
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

  double calculateTotal() {
    double total = 0;
    for (var category in ['extra', 'especial', 'primera', 'segunda', 'tercera', 'cuarta', 'quinta', 'sucios', 'rajados']) {
      total += _getTotalUnits(category) * getPrice(category);
    }
    return total;
  }

  EggSaleModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? customer,
    int? extraMounts,
    int? extraMaples,
    int? extraUnits,
    double? extraPrice,
    int? especialMounts,
    int? especialMaples,
    int? especialUnits,
    double? especialPrice,
    int? primeraMounts,
    int? primeraMaples,
    int? primeraUnits,
    double? primeraPrice,
    int? segundaMounts,
    int? segundaMaples,
    int? segundaUnits,
    double? segundaPrice,
    int? terceraMounts,
    int? terceraMaples,
    int? terceraUnits,
    double? terceraPrice,
    int? cuartaMounts,
    int? cuartaMaples,
    int? cuartaUnits,
    double? cuartaPrice,
    int? quintaMounts,
    int? quintaMaples,
    int? quintaUnits,
    double? quintaPrice,
    int? suciosMounts,
    int? suciosMaples,
    int? suciosUnits,
    double? suciosPrice,
    int? rajadosMounts,
    int? rajadosMaples,
    int? rajadosUnits,
    double? rajadosPrice,
    double? totalSale,
    DateTime? createdAt,
  }) {
    return EggSaleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      customer: customer ?? this.customer,
      extraMounts: extraMounts ?? this.extraMounts,
      extraMaples: extraMaples ?? this.extraMaples,
      extraUnits: extraUnits ?? this.extraUnits,
      extraPrice: extraPrice ?? this.extraPrice,
      especialMounts: especialMounts ?? this.especialMounts,
      especialMaples: especialMaples ?? this.especialMaples,
      especialUnits: especialUnits ?? this.especialUnits,
      especialPrice: especialPrice ?? this.especialPrice,
      primeraMounts: primeraMounts ?? this.primeraMounts,
      primeraMaples: primeraMaples ?? this.primeraMaples,
      primeraUnits: primeraUnits ?? this.primeraUnits,
      primeraPrice: primeraPrice ?? this.primeraPrice,
      segundaMounts: segundaMounts ?? this.segundaMounts,
      segundaMaples: segundaMaples ?? this.segundaMaples,
      segundaUnits: segundaUnits ?? this.segundaUnits,
      segundaPrice: segundaPrice ?? this.segundaPrice,
      terceraMounts: terceraMounts ?? this.terceraMounts,
      terceraMaples: terceraMaples ?? this.terceraMaples,
      terceraUnits: terceraUnits ?? this.terceraUnits,
      terceraPrice: terceraPrice ?? this.terceraPrice,
      cuartaMounts: cuartaMounts ?? this.cuartaMounts,
      cuartaMaples: cuartaMaples ?? this.cuartaMaples,
      cuartaUnits: cuartaUnits ?? this.cuartaUnits,
      cuartaPrice: cuartaPrice ?? this.cuartaPrice,
      quintaMounts: quintaMounts ?? this.quintaMounts,
      quintaMaples: quintaMaples ?? this.quintaMaples,
      quintaUnits: quintaUnits ?? this.quintaUnits,
      quintaPrice: quintaPrice ?? this.quintaPrice,
      suciosMounts: suciosMounts ?? this.suciosMounts,
      suciosMaples: suciosMaples ?? this.suciosMaples,
      suciosUnits: suciosUnits ?? this.suciosUnits,
      suciosPrice: suciosPrice ?? this.suciosPrice,
      rajadosMounts: rajadosMounts ?? this.rajadosMounts,
      rajadosMaples: rajadosMaples ?? this.rajadosMaples,
      rajadosUnits: rajadosUnits ?? this.rajadosUnits,
      rajadosPrice: rajadosPrice ?? this.rajadosPrice,
      totalSale: totalSale ?? this.totalSale,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String getDisplayQuantity(String category) {
    int mounts = 0, maples = 0, units = 0;
    switch (category) {
      case 'extra': mounts = extraMounts; maples = extraMaples; units = extraUnits; break;
      case 'especial': mounts = especialMounts; maples = especialMaples; units = especialUnits; break;
      case 'primera': mounts = primeraMounts; maples = primeraMaples; units = primeraUnits; break;
      case 'segunda': mounts = segundaMounts; maples = segundaMaples; units = segundaUnits; break;
      case 'tercera': mounts = terceraMounts; maples = terceraMaples; units = terceraUnits; break;
      case 'cuarta': mounts = cuartaMounts; maples = cuartaMaples; units = cuartaUnits; break;
      case 'quinta': mounts = quintaMounts; maples = quintaMaples; units = quintaUnits; break;
      case 'sucios': mounts = suciosMounts; maples = suciosMaples; units = suciosUnits; break;
      case 'rajados': mounts = rajadosMounts; maples = rajadosMaples; units = rajadosUnits; break;
    }
    List<String> parts = [];
    if (mounts > 0) parts.add('$mounts Mo');
    if (maples > 0) parts.add('$maples Ma');
    if (units > 0) parts.add('$units U');
    return parts.isEmpty ? '0' : parts.join(' + ');
  }
}