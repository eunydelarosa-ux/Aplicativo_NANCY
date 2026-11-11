// ===============================================================
// APLICATIVO NANCY
// Modelo del perfil del usuario
// ===============================================================
class UserProfileModel {
  final int? id;

  final String name;

  final String role;

  final String username;

  final String email;

  final String phone;

  final String? cedula;

  final String? imagePath;

  final int? municipalityId;

  final int? siteId;

  final int? createdByUserId;

  final String passwordHash;
  final bool isActive;

  final String? activationCodeHash;

  final bool mustChangePassword;

  final DateTime createdAt;

  final DateTime updatedAt;

  const UserProfileModel({
    this.id,
    required this.name,
    required this.role,
    this.username = '',
    required this.email,
    required this.phone,
    this.cedula,
    this.imagePath,
    this.municipalityId,

    this.siteId,

    this.createdByUserId,

    this.passwordHash = '',
    this.isActive = true,
    this.activationCodeHash,
    this.mustChangePassword = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // =============================================================
  // VALIDAR COMPLETITUD DEL PERFIL
  // =============================================================

  bool get isProfileComplete {
    return name.trim().isNotEmpty &&
        role.trim().isNotEmpty &&
        email.trim().isNotEmpty &&
        phone.trim().isNotEmpty &&
        (cedula?.trim().isNotEmpty ?? false);
  }

  // =============================================================
  // CONVERTIR MODELO → MAP
  // =============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'username': username,
      'email': email,
      'phone': phone,
      'cedula': cedula,
      'image_path': imagePath,
      'municipality_id': municipalityId,

      'site_id': siteId,

      'created_by_user_id': createdByUserId,

      'password_hash': passwordHash,
      'is_active': isActive ? 1 : 0,
      'activation_code_hash': activationCodeHash,
      'must_change_password': mustChangePassword ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // =============================================================
  // CONVERTIR MAP → MODELO
  // =============================================================

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      role: map['role'] as String,
      username: (map['username'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      cedula: map['cedula'] as String?,
      imagePath: map['image_path'] as String?,
      municipalityId: map['municipality_id'] as int?,

      siteId: map['site_id'] as int?,

      createdByUserId: map['created_by_user_id'] as int?,
      passwordHash: (map['password_hash'] ?? '') as String,
      isActive: (map['is_active'] ?? 1) == 1,
      activationCodeHash: map['activation_code_hash'] as String?,
      mustChangePassword: (map['must_change_password'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // =============================================================
  // COPY WITH
  // =============================================================

  UserProfileModel copyWith({
    int? id,
    String? name,
    String? role,
    String? username,
    String? email,
    String? phone,
    String? cedula,
    String? imagePath,
    int? municipalityId,

    int? siteId,

    int? createdByUserId,

    String? passwordHash,
    bool? isActive,
    String? activationCodeHash,
    bool? mustChangePassword,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      cedula: cedula ?? this.cedula,
      imagePath: imagePath ?? this.imagePath,
      municipalityId: municipalityId ?? this.municipalityId,

      siteId: siteId ?? this.siteId,

      createdByUserId: createdByUserId ?? this.createdByUserId,

      passwordHash: passwordHash ?? this.passwordHash,
      isActive: isActive ?? this.isActive,
      activationCodeHash: activationCodeHash ?? this.activationCodeHash,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
