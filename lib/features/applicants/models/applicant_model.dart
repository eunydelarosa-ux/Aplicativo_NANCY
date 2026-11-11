// ===============================================================
// APLICATIVO NANCY
// Modelo de datos del Aspirante
// ===============================================================

class ApplicantModel {
  // =============================================================
  // IDENTIFICADOR
  // =============================================================

  final String id;

  // =============================================================
  // INFORMACIÓN PERSONAL
  // =============================================================

  final String documentType;

  final String documentNumber;

  final String firstName;

  final String lastName;

  final DateTime birthDate;

  final String gender;

  // =============================================================
  // INFORMACIÓN ACADÉMICA
  // =============================================================

  final String schooling;

  final String program;

  // =============================================================
  // INFORMACIÓN DE CONTACTO
  // =============================================================

  final String phone;

  final String email;

  final String address;

  // =============================================================
  // UBICACIÓN
  // =============================================================

  final String department;

  final String municipality;

  final String corregimiento;

  final String village;

  // =============================================================
  // RESPONSABLE DEL REGISTRO
  // =============================================================

  final String responsibleName;

  final String responsibleRole;

  final String responsibleCedula;

  // =============================================================
  // IDENTIDAD INTERNA DEL ASPIRANTE
  // =============================================================

  final int? createdByUserId;

  final int? siteId;

  // =============================================================
  // OBSERVACIONES
  // =============================================================

  final String observations;

  // =============================================================
  // SINCRONIZACIÓN
  // =============================================================

  final String syncStatus;

  final int syncAttempts;

  final DateTime? lastSyncAttempt;

  final String? lastSyncError;

  final DateTime? syncedAt;

  // =============================================================
  // FECHAS
  // =============================================================

  final DateTime createdAt;

  final DateTime updatedAt;

  // =============================================================
  // PAPELERA
  // =============================================================

  final bool isDeleted;

  final DateTime? deletedAt;

  // =============================================================
  // CONSTRUCTOR
  // =============================================================

  const ApplicantModel({
    required this.id,

    // Información personal.
    required this.documentType,
    required this.documentNumber,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.gender,

    // Información académica.
    required this.schooling,
    required this.program,

    // Contacto.
    required this.phone,
    required this.email,
    required this.address,

    // Ubicación.
    required this.department,
    required this.municipality,
    required this.corregimiento,
    required this.village,

    // Responsable.
    required this.responsibleName,
    required this.responsibleRole,
    required this.responsibleCedula,

    // Identidad interna del aspirante.
    this.createdByUserId,
    this.siteId,

    // Observaciones.
    required this.observations,

    // Sincronización.
    required this.syncStatus,
    this.syncAttempts = 0,
    this.lastSyncAttempt,
    this.lastSyncError,
    this.syncedAt,

    // Fechas.
    required this.createdAt,
    required this.updatedAt,

    // Papelera.
    this.isDeleted = false,
    this.deletedAt,
  });

  // =============================================================
  // CONVERTIR A MAP PARA SQLITE
  // =============================================================

  Map<String, dynamic> toMap() {
    return {
      // =========================================================
      // IDENTIFICADOR
      // =========================================================
      'id': id,

      // =========================================================
      // INFORMACIÓN PERSONAL
      // =========================================================
      'document_type': documentType,

      'document_number': documentNumber,

      'first_name': firstName,

      'last_name': lastName,

      'birth_date': birthDate.toIso8601String(),

      'gender': gender,

      // =========================================================
      // INFORMACIÓN ACADÉMICA
      // =========================================================
      'schooling': schooling,

      'program': program,

      // =========================================================
      // CONTACTO
      // =========================================================
      'phone': phone,

      'email': email,

      'address': address,

      // =========================================================
      // UBICACIÓN
      // =========================================================
      'department': department,

      'municipality': municipality,

      'corregimiento': corregimiento,

      'village': village,

      // =========================================================
      // RESPONSABLE DEL REGISTRO
      // =========================================================
      'responsible_name': responsibleName,

      'responsible_role': responsibleRole,

      'responsible_cedula': responsibleCedula,

      // Identidad interna del aspirante.
      'created_by_user_id': createdByUserId,

      'site_id': siteId,

      // =========================================================
      // OBSERVACIONES
      // =========================================================
      'observations': observations,

      // =========================================================
      // SINCRONIZACIÓN
      // =========================================================
      'sync_status': syncStatus,

      'sync_attempts': syncAttempts,
      'last_sync_attempt': lastSyncAttempt?.toIso8601String(),
      'last_sync_error': lastSyncError,
      'synced_at': syncedAt?.toIso8601String(),

      // =========================================================
      // FECHAS
      // =========================================================
      'created_at': createdAt.toIso8601String(),

      'updated_at': updatedAt.toIso8601String(),

      // =========================================================
      // PAPELERA
      // =========================================================
      'is_deleted': isDeleted ? 1 : 0,

      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  // =============================================================
  // CREAR MODELO DESDE SQLITE
  // =============================================================

  factory ApplicantModel.fromMap(Map<String, dynamic> map) {
    return ApplicantModel(
      // =========================================================
      // IDENTIFICADOR
      // =========================================================
      id: (map['id'] ?? '').toString(),

      // =========================================================
      // INFORMACIÓN PERSONAL
      // =========================================================
      documentType: (map['document_type'] ?? '').toString(),

      documentNumber: (map['document_number'] ?? '').toString(),

      firstName: (map['first_name'] ?? '').toString(),

      lastName: (map['last_name'] ?? '').toString(),

      birthDate: DateTime.parse((map['birth_date'] ?? '').toString()),

      gender: (map['gender'] ?? '').toString(),

      // =========================================================
      // INFORMACIÓN ACADÉMICA
      // =========================================================
      schooling: (map['schooling'] ?? '').toString(),

      program: (map['program'] ?? '').toString(),

      // =========================================================
      // CONTACTO
      // =========================================================
      phone: (map['phone'] ?? '').toString(),

      email: (map['email'] ?? '').toString(),

      address: (map['address'] ?? '').toString(),

      // =========================================================
      // UBICACIÓN
      // =========================================================
      department: (map['department'] ?? '').toString(),

      municipality: (map['municipality'] ?? '').toString(),

      corregimiento: (map['corregimiento'] ?? '').toString(),

      village: (map['village'] ?? '').toString(),

      // =========================================================
      // RESPONSABLE DEL REGISTRO
      // =========================================================
      responsibleName: (map['responsible_name'] ?? '').toString(),

      responsibleRole: (map['responsible_role'] ?? '').toString(),

      responsibleCedula: (map['responsible_cedula'] ?? '').toString(),

      // Identidad interna del aspirante.
      createdByUserId: _parseNullableInt(map['created_by_user_id']),

      siteId: _parseNullableInt(map['site_id']),

      // =========================================================
      // OBSERVACIONES
      // =========================================================
      observations: (map['observations'] ?? '').toString(),

      // =========================================================
      // SINCRONIZACIÓN
      // =========================================================
      syncStatus: (map['sync_status'] ?? '').toString(),

      syncAttempts: _parseInt(map['sync_attempts']),
      lastSyncAttempt: map['last_sync_attempt'] == null
          ? null
          : DateTime.tryParse(map['last_sync_attempt'].toString()),
      lastSyncError: map['last_sync_error']?.toString(),
      syncedAt: map['synced_at'] == null
          ? null
          : DateTime.tryParse(map['synced_at'].toString()),

      // =========================================================
      // FECHAS
      // =========================================================
      createdAt: DateTime.parse((map['created_at'] ?? '').toString()),

      updatedAt: DateTime.parse((map['updated_at'] ?? '').toString()),

      // =========================================================
      // PAPELERA
      // =========================================================
      isDeleted: _parseBoolean(map['is_deleted']),

      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.tryParse(map['deleted_at'].toString()),
    );
  }

  // =============================================================
  // CONVERTIR VALOR SQLITE A BOOLEAN
  // =============================================================

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is String) {
      final String normalized = value.trim();

      if (normalized.isEmpty) {
        return null;
      }

      return int.tryParse(normalized);
    }

    return null;
  }

  static bool _parseBoolean(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }

    return false;
  }

  // =============================================================
  // COPY WITH
  // =============================================================

  ApplicantModel copyWith({
    // Identificador.
    String? id,

    // Información personal.
    String? documentType,
    String? documentNumber,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? gender,

    // Información académica.
    String? schooling,
    String? program,

    // Contacto.
    String? phone,
    String? email,
    String? address,

    // Ubicación.
    String? department,
    String? municipality,
    String? corregimiento,
    String? village,

    // Responsable.
    String? responsibleName,

    String? responsibleRole,

    String? responsibleCedula,

    // Identidad interna del aspirante.
    int? createdByUserId,

    int? siteId,

    // Observaciones.
    String? observations,

    // Sincronización.
    String? syncStatus,
    int? syncAttempts,
    DateTime? lastSyncAttempt,
    String? lastSyncError,
    DateTime? syncedAt,
    bool clearLastSyncAttempt = false,
    bool clearLastSyncError = false,
    bool clearSyncedAt = false,

    // Fechas.
    DateTime? createdAt,
    DateTime? updatedAt,

    // Papelera.
    bool? isDeleted,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return ApplicantModel(
      // =========================================================
      // IDENTIFICADOR
      // =========================================================
      id: id ?? this.id,

      // =========================================================
      // INFORMACIÓN PERSONAL
      // =========================================================
      documentType: documentType ?? this.documentType,

      documentNumber: documentNumber ?? this.documentNumber,

      firstName: firstName ?? this.firstName,

      lastName: lastName ?? this.lastName,

      birthDate: birthDate ?? this.birthDate,

      gender: gender ?? this.gender,

      // =========================================================
      // INFORMACIÓN ACADÉMICA
      // =========================================================
      schooling: schooling ?? this.schooling,

      program: program ?? this.program,

      // =========================================================
      // CONTACTO
      // =========================================================
      phone: phone ?? this.phone,

      email: email ?? this.email,

      address: address ?? this.address,

      // =========================================================
      // UBICACIÓN
      // =========================================================
      department: department ?? this.department,

      municipality: municipality ?? this.municipality,

      corregimiento: corregimiento ?? this.corregimiento,

      village: village ?? this.village,

      // =========================================================
      // RESPONSABLE
      // =========================================================
      responsibleName: responsibleName ?? this.responsibleName,

      responsibleRole: responsibleRole ?? this.responsibleRole,

      responsibleCedula: responsibleCedula ?? this.responsibleCedula,

      // Identidad interna del aspirante.
      createdByUserId: createdByUserId ?? this.createdByUserId,

      siteId: siteId ?? this.siteId,

      // =========================================================
      // OBSERVACIONES
      // =========================================================
      observations: observations ?? this.observations,

      // =========================================================
      // SINCRONIZACIÓN
      // =========================================================
      syncStatus: syncStatus ?? this.syncStatus,

      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastSyncAttempt: clearLastSyncAttempt
          ? null
          : lastSyncAttempt ?? this.lastSyncAttempt,
      lastSyncError: clearLastSyncError
          ? null
          : lastSyncError ?? this.lastSyncError,
      syncedAt: clearSyncedAt ? null : syncedAt ?? this.syncedAt,

      // =========================================================
      // FECHAS
      // =========================================================
      createdAt: createdAt ?? this.createdAt,

      updatedAt: updatedAt ?? this.updatedAt,

      // =========================================================
      // PAPELERA
      // =========================================================
      isDeleted: isDeleted ?? this.isDeleted,

      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }
}
