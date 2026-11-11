// ===============================================================
// APLICATIVO NANCY
// Modelo de Sede
// ===============================================================

class SiteModel {
  final int? id;
  final String name;
  final String? address;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SiteModel({
    this.id,
    required this.name,
    this.address,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // =============================================================
  // CONVERTIR MODELO → MAP
  // =============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'active': active ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // =============================================================
  // CONVERTIR MAP → MODELO
  // =============================================================

  factory SiteModel.fromMap(Map<String, dynamic> map) {
    return SiteModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      address: map['address'] as String?,
      active: (map['active'] ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // =============================================================
  // COPY WITH
  // =============================================================

  SiteModel copyWith({
    int? id,
    String? name,
    String? address,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SiteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
