import 'role_model.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;
  final AppRole role;
  final bool isActive;
  final String farmId;
  final String createdBy;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    this.role = AppRole.operador,
    this.isActive = true,
    this.farmId = '',
    this.createdBy = '',
  });

  bool hasPermission(String permission) {
    return RolePermissions.hasPermission(role, permission);
  }

  String get roleName => RolePermissions.getRoleName(role);

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    DateTime? createdAt,
    AppRole? role,
    bool? isActive,
    String? farmId,
    String? createdBy,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      farmId: farmId ?? this.farmId,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      role: RolePermissions.roleFromString(map['role']) ?? AppRole.operador,
      isActive: map['isActive'] ?? true,
      farmId: map['farmId'] ?? '',
      createdBy: map['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'role': RolePermissions.roleToString(role),
      'isActive': isActive,
      'farmId': farmId,
      'createdBy': createdBy,
    };
  }
}
