class FarmProfileModel {
  final String id;
  final String userId;
  final String nombre;
  final String direccion;
  final String telefono;
  final int capacidad;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FarmProfileModel({
    required this.id,
    required this.userId,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.capacidad,
    required this.createdAt,
    this.updatedAt,
  });

  factory FarmProfileModel.fromMap(Map<String, dynamic> map) {
    return FarmProfileModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      nombre: map['nombre'] ?? '',
      direccion: map['direccion'] ?? '',
      telefono: map['telefono'] ?? '',
      capacidad: map['capacidad'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
      'capacidad': capacidad,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  FarmProfileModel copyWith({
    String? id,
    String? userId,
    String? nombre,
    String? direccion,
    String? telefono,
    int? capacidad,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      capacidad: capacidad ?? this.capacidad,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
