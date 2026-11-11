// ===============================================================
// APLICATIVO NANCY
// Constantes de la Base de Datos SQLite
// ===============================================================

class DatabaseConstants {
  DatabaseConstants._();

  // =============================================================
  // BASE DE DATOS
  // =============================================================

  static const String databaseName = 'nancy.db';

  static const int databaseVersion = 25;

  // =============================================================
  // TABLA DE ASPIRANTES
  // =============================================================

  static const String applicantsTable = 'applicants';

  // =============================================================
  // TABLA DE HISTORIAL DE SINCRONIZACIÓN
  // =============================================================

  static const String syncHistoryTable = 'sync_history';

  static const String historyId = 'id';

  static const String historyApplicantId = 'applicant_id';

  static const String historyStatus = 'status';

  static const String historySyncedAt = 'synced_at';

  static const String historyAttempts = 'attempts';

  static const String historyMessage = 'message';

  // Identidad interna del registro del historial.
  static const String historyCreatedByUserId = 'created_by_user_id';

  static const String historySiteId = 'site_id';
  // =============================================================
  // IDENTIFICACIÓN
  // =============================================================

  static const String id = 'id';

  static const String documentType = 'document_type';

  static const String documentNumber = 'document_number';

  // =============================================================
  // INFORMACIÓN PERSONAL
  // =============================================================

  static const String firstName = 'first_name';

  static const String lastName = 'last_name';

  static const String birthDate = 'birth_date';

  static const String gender = 'gender';

  // =============================================================
  // INFORMACIÓN ACADÉMICA
  // =============================================================

  static const String schooling = 'schooling';

  static const String program = 'program';

  static const String trainingCenter = 'training_center';

  static const String modality = 'modality';

  static const String schedule = 'schedule';

  // =============================================================
  // INFORMACIÓN DE CONTACTO
  // =============================================================

  static const String phone = 'phone';

  static const String email = 'email';

  static const String address = 'address';

  // =============================================================
  // UBICACIÓN DEL ASPIRANTE
  // =============================================================

  static const String department = 'department';

  static const String municipality = 'municipality';

  static const String corregimiento = 'corregimiento';

  static const String village = 'village';

  // =============================================================
  // RESPONSABLE DEL REGISTRO
  // =============================================================

  static const String responsibleName = 'responsible_name';

  static const String responsibleRole = 'responsible_role';

  static const String responsibleCedula = 'responsible_cedula';

  // =============================================================
  // IDENTIDAD INTERNA DEL ASPIRANTE
  // =============================================================

  static const String applicantCreatedByUserId = 'created_by_user_id';

  static const String applicantSiteId = 'site_id';

  // =============================================================
  // OBSERVACIONES
  // =============================================================

  static const String observations = 'observations';

  // =============================================================
  // SINCRONIZACIÓN
  // =============================================================

  static const String syncStatus = 'sync_status';

  static const String syncAttempts = 'sync_attempts';

  static const String lastSyncAttempt = 'last_sync_attempt';

  static const String lastSyncError = 'last_sync_error';

  static const String syncedAt = 'synced_at';

  // =============================================================
  // FECHAS INTERNAS
  // =============================================================

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  static const String isDeleted = 'is_deleted';

  static const String deletedAt = 'deleted_at';

  // =============================================================
  // TABLA DE CATÁLOGOS
  // =============================================================

  static const String catalogItemsTable = 'catalog_items';

  // =============================================================
  // CAMPOS DE CATÁLOGOS
  // =============================================================

  static const String catalogId = 'id';

  static const String catalogType = 'catalog_type';

  static const String catalogName = 'name';

  static const String catalogParentId = 'parent_id';

  static const String catalogActive = 'active';

  static const String catalogCreatedAt = 'created_at';

  static const String catalogUpdatedAt = 'updated_at';

  // =============================================================
  // TABLAS DE CATÁLOGOS POR USUARIO
  // =============================================================

  static const String userCatalogItemsTable = 'user_catalog_items';

  static const String userCatalogStateTable = 'user_catalog_state';

  static const String userCatalogUserId = 'user_id';

  static const String userCatalogSourceId = 'source_catalog_id';

  static const String userCatalogInitializedAt = 'initialized_at';

  // =============================================================
  // TABLA DE DEPARTAMENTOS
  // =============================================================

  static const String departmentsTable = 'departments';

  static const String departmentId = 'id';

  static const String departmentCode = 'code';

  static const String departmentName = 'name';

  static const String departmentCreatedAt = 'created_at';

  // =============================================================
  // TABLA DE MUNICIPIOS
  // =============================================================

  static const String municipalitiesTable = 'municipalities';
  static const String municipalityId = 'id';
  static const String municipalityDepartmentId = 'department_id';
  static const String municipalityCode = 'code';
  static const String municipalityName = 'name';
  static const String municipalityCreatedAt = 'created_at';

  // =============================================================
  // TABLA DE SEDES
  // =============================================================

  static const String sitesTable = 'sites';
  static const String siteId = 'id';
  static const String siteName = 'name';
  static const String siteAddress = 'address';
  static const String siteActive = 'active';
  static const String siteCreatedAt = 'created_at';
  static const String siteUpdatedAt = 'updated_at';

  // =============================================================
  // RELACIÓN SEDES - MUNICIPIOS
  // =============================================================

  static const String siteMunicipalitiesTable = 'site_municipalities';
  static const String siteMunicipalitySiteId = 'site_id';
  static const String siteMunicipalityMunicipalityId = 'municipality_id';

  // =============================================================
  // TABLA DE CORREGIMIENTOS
  // =============================================================

  static const String corregimientosTable = 'corregimientos';

  static const String corregimientoId = 'id';

  static const String corregimientoMunicipalityId = 'municipality_id';

  static const String corregimientoCode = 'code';

  static const String corregimientoName = 'name';

  static const String corregimientoCreatedAt = 'created_at';

  // =============================================================
  // TABLA DE VEREDAS
  // =============================================================

  static const String villagesTable = 'villages';

  static const String villageId = 'id';

  static const String villageDepartmentId = 'department_id';

  static const String villageMunicipalityId = 'municipality_id';

  static const String villageCorregimientoId = 'corregimiento_id';

  static const String villageCode = 'code';

  static const String villageName = 'name';

  static const String villageCreatedAt = 'created_at';
}
