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
  
  final int extraMaples;
  final int especialMaples;
  final int primeraMaples;
  final int segundaMaples;
  final int terceraMaples;
  final int cuartaMaples;
  final int quintaMaples;
  final int suciosMaples;
  final int rajadosMaples;
  final int descarteMaples;

  final int extraMounts;
  final int especialMounts;
  final int primeraMounts;
  final int segundaMounts;
  final int terceraMounts;
  final int cuartaMounts;
  final int quintaMounts;
  final int suciosMounts;
  final int rajadosMounts;
  final int descarteMounts;

  static const int MAPLE_EGGS = 30;
  static const int MOUNT_MAPLES = 10;
  static const int MOUNT_EGGS = MAPLE_EGGS * MOUNT_MAPLES;

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
    this.extraMaples = 0,
    this.especialMaples = 0,
    this.primeraMaples = 0,
    this.segundaMaples = 0,
    this.terceraMaples = 0,
    this.cuartaMaples = 0,
    this.quintaMaples = 0,
    this.suciosMaples = 0,
    this.rajadosMaples = 0,
    this.descarteMaples = 0,
    this.extraMounts = 0,
    this.especialMounts = 0,
    this.primeraMounts = 0,
    this.segundaMounts = 0,
    this.terceraMounts = 0,
    this.cuartaMounts = 0,
    this.quintaMounts = 0,
    this.suciosMounts = 0,
    this.rajadosMounts = 0,
    this.descarteMounts = 0,
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
      extraMaples: map['extraMaples'] ?? 0,
      especialMaples: map['especialMaples'] ?? 0,
      primeraMaples: map['primeraMaples'] ?? 0,
      segundaMaples: map['segundaMaples'] ?? 0,
      terceraMaples: map['terceraMaples'] ?? 0,
      cuartaMaples: map['cuartaMaples'] ?? 0,
      quintaMaples: map['quintaMaples'] ?? 0,
      suciosMaples: map['suciosMaples'] ?? 0,
      rajadosMaples: map['rajadosMaples'] ?? 0,
      descarteMaples: map['descarteMaples'] ?? 0,
      extraMounts: map['extraMounts'] ?? 0,
      especialMounts: map['especialMounts'] ?? 0,
      primeraMounts: map['primeraMounts'] ?? 0,
      segundaMounts: map['segundaMounts'] ?? 0,
      terceraMounts: map['terceraMounts'] ?? 0,
      cuartaMounts: map['cuartaMounts'] ?? 0,
      quintaMounts: map['quintaMounts'] ?? 0,
      suciosMounts: map['suciosMounts'] ?? 0,
      rajadosMounts: map['rajadosMounts'] ?? 0,
      descarteMounts: map['descarteMounts'] ?? 0,
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
      'extraMaples': extraMaples,
      'especialMaples': especialMaples,
      'primeraMaples': primeraMaples,
      'segundaMaples': segundaMaples,
      'terceraMaples': terceraMaples,
      'cuartaMaples': cuartaMaples,
      'quintaMaples': quintaMaples,
      'suciosMaples': suciosMaples,
      'rajadosMaples': rajadosMaples,
      'descarteMaples': descarteMaples,
      'extraMounts': extraMounts,
      'especialMounts': especialMounts,
      'primeraMounts': primeraMounts,
      'segundaMounts': segundaMounts,
      'terceraMounts': terceraMounts,
      'cuartaMounts': cuartaMounts,
      'quintaMounts': quintaMounts,
      'suciosMounts': suciosMounts,
      'rajadosMounts': rajadosMounts,
      'descarteMounts': descarteMounts,
    };
  }

  int calculateUnits() {
    return extra + especial + primera + segunda + tercera + cuarta + quinta + sucios + rajados + descarte;
  }

  int calculateMaples() {
    return extraMaples + especialMaples + primeraMaples + segundaMaples + terceraMaples + cuartaMaples + quintaMaples + suciosMaples + rajadosMaples + descarteMaples;
  }

  int calculateMounts() {
    return extraMounts + especialMounts + primeraMounts + segundaMounts + terceraMounts + cuartaMounts + quintaMounts + suciosMounts + rajadosMounts + descarteMounts;
  }

  int get totalFromMaples => calculateMaples() * MAPLE_EGGS;
  int get totalFromMounts => calculateMounts() * MOUNT_EGGS;

  int get totalUnits => calculateUnits() + totalFromMaples + totalFromMounts;

  int getTotalByCategory(String category) {
    switch (category) {
      case 'extra': return extra + (extraMaples * MAPLE_EGGS) + (extraMounts * MOUNT_EGGS);
      case 'especial': return especial + (especialMaples * MAPLE_EGGS) + (especialMounts * MOUNT_EGGS);
      case 'primera': return primera + (primeraMaples * MAPLE_EGGS) + (primeraMounts * MOUNT_EGGS);
      case 'segunda': return segunda + (segundaMaples * MAPLE_EGGS) + (segundaMounts * MOUNT_EGGS);
      case 'tercera': return tercera + (terceraMaples * MAPLE_EGGS) + (terceraMounts * MOUNT_EGGS);
      case 'cuarta': return cuarta + (cuartaMaples * MAPLE_EGGS) + (cuartaMounts * MOUNT_EGGS);
      case 'quinta': return quinta + (quintaMaples * MAPLE_EGGS) + (quintaMounts * MOUNT_EGGS);
      case 'sucios': return sucios + (suciosMaples * MAPLE_EGGS) + (suciosMounts * MOUNT_EGGS);
      case 'rajados': return rajados + (rajadosMaples * MAPLE_EGGS) + (rajadosMounts * MOUNT_EGGS);
      case 'descarte': return descarte + (descarteMaples * MAPLE_EGGS) + (descarteMounts * MOUNT_EGGS);
      default: return 0;
    }
  }

  String get displayTotal {
    final units = calculateUnits();
    final maples = calculateMaples();
    final mounts = calculateMounts();
    
    if (mounts > 0 && maples > 0 && units > 0) {
      return '$mounts montones ($totalFromMounts) + $maples maples ($totalFromMaples) + $units = $totalUnits huevos';
    } else if (mounts > 0 && maples > 0) {
      return '$mounts montones ($totalFromMounts) + $maples maples ($totalFromMaples) = $totalUnits huevos';
    } else if (mounts > 0 && units > 0) {
      return '$mounts montones ($totalFromMounts) + $units = $totalUnits huevos';
    } else if (mounts > 0) {
      return '$mounts montones ($totalUnits huevos)';
    } else if (maples > 0 && units > 0) {
      return '$maples maples ($totalFromMaples) + $units = $totalUnits huevos';
    } else if (maples > 0) {
      return '$maples maples ($totalUnits huevos)';
    }
    return '$totalUnits huevos';
  }

  String getCategoryDisplay(String category, int units, int maples, int mounts) {
    final fromMaples = maples * MAPLE_EGGS;
    final fromMounts = mounts * MOUNT_EGGS;
    final total = units + fromMaples + fromMounts;
    
    if (mounts > 0 && maples > 0 && units > 0) {
      return '$mounts m ($fromMounts) + $maples m ($fromMaples) + $units = $total';
    } else if (mounts > 0 && maples > 0) {
      return '$mounts m ($fromMounts) + $maples m ($fromMaples) = $total';
    } else if (mounts > 0 && units > 0) {
      return '$mounts m ($fromMounts) + $units = $total';
    } else if (mounts > 0) {
      return '$mounts montones ($total)';
    } else if (maples > 0 && units > 0) {
      return '$maples m ($fromMaples) + $units = $total';
    } else if (maples > 0) {
      return '$maples maples ($total)';
    } else if (units > 0) {
      return '$units';
    }
    return '0';
  }

  EggProductionModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? extra,
    int? especial,
    int? primera,
    int? segunda,
    int? tercera,
    int? cuarta,
    int? quinta,
    int? sucios,
    int? rajados,
    int? descarte,
    int? totalHuevos,
    DateTime? createdAt,
    int? extraMaples,
    int? especialMaples,
    int? primeraMaples,
    int? segundaMaples,
    int? terceraMaples,
    int? cuartaMaples,
    int? quintaMaples,
    int? suciosMaples,
    int? rajadosMaples,
    int? descarteMaples,
    int? extraMounts,
    int? especialMounts,
    int? primeraMounts,
    int? segundaMounts,
    int? terceraMounts,
    int? cuartaMounts,
    int? quintaMounts,
    int? suciosMounts,
    int? rajadosMounts,
    int? descarteMounts,
  }) {
    return EggProductionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      extra: extra ?? this.extra,
      especial: especial ?? this.especial,
      primera: primera ?? this.primera,
      segunda: segunda ?? this.segunda,
      tercera: tercera ?? this.tercera,
      cuarta: cuarta ?? this.cuarta,
      quinta: quinta ?? this.quinta,
      sucios: sucios ?? this.sucios,
      rajados: rajados ?? this.rajados,
      descarte: descarte ?? this.descarte,
      totalHuevos: totalHuevos ?? this.totalHuevos,
      createdAt: createdAt ?? this.createdAt,
      extraMaples: extraMaples ?? this.extraMaples,
      especialMaples: especialMaples ?? this.especialMaples,
      primeraMaples: primeraMaples ?? this.primeraMaples,
      segundaMaples: segundaMaples ?? this.segundaMaples,
      terceraMaples: terceraMaples ?? this.terceraMaples,
      cuartaMaples: cuartaMaples ?? this.cuartaMaples,
      quintaMaples: quintaMaples ?? this.quintaMaples,
      suciosMaples: suciosMaples ?? this.suciosMaples,
      rajadosMaples: rajadosMaples ?? this.rajadosMaples,
      descarteMaples: descarteMaples ?? this.descarteMaples,
      extraMounts: extraMounts ?? this.extraMounts,
      especialMounts: especialMounts ?? this.especialMounts,
      primeraMounts: primeraMounts ?? this.primeraMounts,
      segundaMounts: segundaMounts ?? this.segundaMounts,
      terceraMounts: terceraMounts ?? this.terceraMounts,
      cuartaMounts: cuartaMounts ?? this.cuartaMounts,
      quintaMounts: quintaMounts ?? this.quintaMounts,
      suciosMounts: suciosMounts ?? this.suciosMounts,
      rajadosMounts: rajadosMounts ?? this.rajadosMounts,
      descarteMounts: descarteMounts ?? this.descarteMounts,
    );
  }
}
