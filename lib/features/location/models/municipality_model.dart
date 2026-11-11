// ===============================================================
// APLICATIVO NANCY
// Modelo de Municipio
// ===============================================================

class MunicipalityModel {
  final int? id;
  final int departmentId;
  final String? code;
  final String name;
  final DateTime createdAt;

  const MunicipalityModel({
    this.id,
    required this.departmentId,
    this.code,
    required this.name,
    required this.createdAt,
  });

  // =============================================================
  // CREAR MODELO DESDE SQLITE
  // =============================================================

  factory MunicipalityModel.fromMap(Map<String, dynamic> map) {
    return MunicipalityModel(
      id: map['id'] == null ? null : (map['id'] as num).toInt(),
      departmentId: (map['department_id'] as num).toInt(),
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
      'code': code,
      'name': name.trim(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // =============================================================
  // COPY WITH
  // =============================================================

  MunicipalityModel copyWith({
    int? id,
    int? departmentId,
    String? code,
    String? name,
    DateTime? createdAt,
  }) {
    return MunicipalityModel(
      id: id ?? this.id,
      departmentId: departmentId ?? this.departmentId,
      code: code ?? this.code,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
