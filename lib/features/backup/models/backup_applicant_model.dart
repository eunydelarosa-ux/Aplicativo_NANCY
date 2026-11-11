// =============================================================
// APLICATIVO NANCY
// Modelo - Aspirante de una Copia de Seguridad
// =============================================================


class BackupApplicantModel {
  // ===========================================================
  // IDENTIFICACIÓN
  // ===========================================================

  final String id;

  final String documentType;

  final String documentNumber;

  // ===========================================================
  // INFORMACIÓN PERSONAL
  // ===========================================================

  final String firstName;

  final String lastName;

  final String birthDate;

  final String gender;

  // ===========================================================
  // INFORMACIÓN ACADÉMICA
  // ===========================================================

  final String schooling;

  final String program;

  // ===========================================================
  // INFORMACIÓN DE CONTACTO
  // ===========================================================

  final String? phone;

  final String? email;

  final String? address;

  // ===========================================================
  // UBICACIÓN
  // ===========================================================
  //
  // Estos campos corresponden a la ubicación registrada
  // para el aspirante.
  //
  // La información de ubicación ya NO depende de catalog_items.
  //
  // Departamento
  //    ↓
  // Municipio
  //    ↓
  // Corregimiento
  //    ↓
  // Vereda
  //
  // ===========================================================

  final String? department;

  final String? municipality;

  final String? corregimiento;

  final String? village;

  // ===========================================================
  // RESPONSABLE DEL REGISTRO
  // ===========================================================

  final String? responsibleName;

  final String? responsibleRole;

  // ===========================================================
  // OBSERVACIONES
  // ===========================================================

  final String? observations;

  // ===========================================================
  // SINCRONIZACIÓN
  // ===========================================================

  final String? syncStatus;

  // ===========================================================
  // FECHAS DEL ASPIRANTE
  // ===========================================================

  final String? createdAt;

  final String? updatedAt;

  // ===========================================================
  // PAPELERA
  // ===========================================================

  final bool isDeleted;

  final String? deletedAt;

  // ===========================================================
  // CONSTRUCTOR
  // ===========================================================

  const BackupApplicantModel({
    required this.id,
    required this.documentType,
    required this.documentNumber,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.gender,
    required this.schooling,
    required this.program,
    this.phone,
    this.email,
    this.address,
    this.department,
    this.municipality,
    this.corregimiento,
    this.village,
    this.responsibleName,
    this.responsibleRole,
    this.observations,
    this.syncStatus,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  // ===========================================================
  // NOMBRE COMPLETO
  // ===========================================================

  String get fullName {
    return '$firstName $lastName'.trim();
  }

  // ===========================================================
  // CREAR DESDE SQLITE
  // ===========================================================

  factory BackupApplicantModel.fromMap(Map<String, dynamic> map) {
    return BackupApplicantModel(
      // =======================================================
      // IDENTIFICACIÓN
      // =======================================================
      id: map['id']?.toString() ?? '',

      documentType: map['document_type']?.toString() ?? '',

      documentNumber: map['document_number']?.toString() ?? '',

      // =======================================================
      // INFORMACIÓN PERSONAL
      // =======================================================
      firstName: map['first_name']?.toString() ?? '',

      lastName: map['last_name']?.toString() ?? '',

      birthDate: map['birth_date']?.toString() ?? '',

      gender: map['gender']?.toString() ?? '',

      // =======================================================
      // INFORMACIÓN ACADÉMICA
      // =======================================================
      schooling: map['schooling']?.toString() ?? '',

      program: map['program']?.toString() ?? '',

      // =======================================================
      // CONTACTO
      // =======================================================
      phone: map['phone']?.toString(),

      email: map['email']?.toString(),

      address: map['address']?.toString(),

      // =======================================================
      // UBICACIÓN
      // =======================================================
      department: map['department']?.toString(),

      municipality: map['municipality']?.toString(),

      corregimiento: map['corregimiento']?.toString(),

      village: map['village']?.toString(),

      // =======================================================
      // RESPONSABLE
      // =======================================================
      responsibleName: map['responsible_name']?.toString(),

      responsibleRole: map['responsible_role']?.toString(),

      // =======================================================
      // OBSERVACIONES
      // =======================================================
      observations: map['observations']?.toString(),

      // =======================================================
      // SINCRONIZACIÓN
      // =======================================================
      syncStatus: map['sync_status']?.toString(),

      // =======================================================
      // FECHAS
      // =======================================================
      createdAt: map['created_at']?.toString(),

      updatedAt: map['updated_at']?.toString(),

      // =======================================================
      // PAPELERA
      // =======================================================
      isDeleted: _parseBool(map['is_deleted']),

      deletedAt: map['deleted_at']?.toString(),
    );
  }

  // ===========================================================
  // CONVERTIR A MAP
  // ===========================================================
  //
  // Se utiliza cuando el backup necesita serializar los datos
  // del aspirante.
  //
  // ===========================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_type': documentType,
      'document_number': documentNumber,
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': birthDate,
      'gender': gender,
      'schooling': schooling,
      'program': program,
      'phone': phone,
      'email': email,
      'address': address,
      'department': department,
      'municipality': municipality,
      'corregimiento': corregimiento,
      'village': village,
      'responsible_name': responsibleName,
      'responsible_role': responsibleRole,
      'observations': observations,
      'sync_status': syncStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt,
    };
  }

  // ===========================================================
  // CONVERTIR VALOR SQLITE A BOOLEAN
  // ===========================================================

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final String normalized = value.trim().toLowerCase();

      return normalized == '1' || normalized == 'true' || normalized == 'yes';
    }

    return false;
  }
}
