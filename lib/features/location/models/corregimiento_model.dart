// ===============================================================
// APLICATIVO NANCY
// Modelo de Corregimiento
// ===============================================================

class CorregimientoModel {
  final int? id;
  final int municipalityId;
  final String? code;
  final String name;
  final DateTime createdAt;

  const CorregimientoModel({
    this.id,
    required this.municipalityId,
    this.code,
    required this.name,
    required this.createdAt,
  });

  // =============================================================
  // CREAR MODELO DESDE SQLITE
  // =============================================================

  factory CorregimientoModel.fromMap(Map<String, dynamic> map) {
    return CorregimientoModel(
      id: map['id'] == null ? null : (map['id'] as num).toInt(),
      municipalityId: (map['municipality_id'] as num).toInt(),
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
      'municipality_id': municipalityId,
      'code': code,
      'name': name.trim(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // =============================================================
  // COPY WITH
  // =============================================================

  CorregimientoModel copyWith({
    int? id,
    int? municipalityId,
    String? code,
    String? name,
    DateTime? createdAt,
  }) {
    return CorregimientoModel(
      id: id ?? this.id,
      municipalityId: municipalityId ?? this.municipalityId,
      code: code ?? this.code,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
