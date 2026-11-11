// ===============================================================
// APLICATIVO NANCY
// Modelo de Departamento
// ===============================================================

class DepartmentModel {
  final int? id;
  final String? code;
  final String name;
  final DateTime createdAt;

  const DepartmentModel({
    this.id,
    this.code,
    required this.name,
    required this.createdAt,
  });

  // =============================================================
  // CREAR MODELO DESDE SQLITE
  // =============================================================

  factory DepartmentModel.fromMap(Map<String, dynamic> map) {
    return DepartmentModel(
      id: map['id'] == null ? null : (map['id'] as num).toInt(),
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
      'code': code,
      'name': name.trim(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // =============================================================
  // COPY WITH
  // =============================================================

  DepartmentModel copyWith({
    int? id,
    String? code,
    String? name,
    DateTime? createdAt,
  }) {
    return DepartmentModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
