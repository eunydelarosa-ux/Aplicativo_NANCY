// ===============================================================
// APLICATIVO NANCY
// Modelo de Vereda
// ===============================================================

class VillageModel {
  final int? id;
  final int? departmentId;
  final int? municipalityId;
  final int? corregimientoId;
  final String? code;
  final String name;
  final DateTime createdAt;

  const VillageModel({
    this.id,
    this.departmentId,
    this.municipalityId,
    this.corregimientoId,
    this.code,
    required this.name,
    required this.createdAt,
  });

  // =============================================================
  // CREAR MODELO DESDE SQLITE
  // =============================================================

  factory VillageModel.fromMap(Map<String, dynamic> map) {
    return VillageModel(
      id: map['id'] == null ? null : (map['id'] as num).toInt(),
      departmentId: map['department_id'] == null
          ? null
          : (map['department_id'] as num).toInt(),
      municipalityId: map['municipality_id'] == null
          ? null
          : (map['municipality_id'] as num).toInt(),
      corregimientoId: map['corregimiento_id'] == null
          ? null
          : (map['corregimiento_id'] as num).toInt(),
      code: map['code']?.toString(),
      name: (map['name'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  // =============================================================
  // CONVERTIR A MAP
  // =============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'department_id': departmentId,
      'municipality_id': municipalityId,
      'corregimiento_id': corregimientoId,
      'code': code,
      'name': name.trim(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // =============================================================
  // COPY WITH
  // =============================================================

  VillageModel copyWith({
    int? id,
    int? departmentId,
    int? municipalityId,
    int? corregimientoId,
    String? code,
    String? name,
    DateTime? createdAt,
  }) {
    return VillageModel(
      id: id ?? this.id,
      departmentId: departmentId ?? this.departmentId,
      municipalityId: municipalityId ?? this.municipalityId,
      corregimientoId: corregimientoId ?? this.corregimientoId,
      code: code ?? this.code,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
