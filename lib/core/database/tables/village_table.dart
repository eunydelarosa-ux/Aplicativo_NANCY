// ===============================================================
// APLICATIVO NANCY
// Tabla de Veredas
// ===============================================================

import '../database_constants.dart';

class VillageTable {
  VillageTable._();

  static const String createTable =
      '''
    CREATE TABLE IF NOT EXISTS
    ${DatabaseConstants.villagesTable} (

      ${DatabaseConstants.villageId}
        INTEGER PRIMARY KEY AUTOINCREMENT,

      ${DatabaseConstants.villageDepartmentId}
        INTEGER,

      ${DatabaseConstants.villageMunicipalityId}
        INTEGER,

      ${DatabaseConstants.villageCorregimientoId}
        INTEGER,

      ${DatabaseConstants.villageCode}
        TEXT,

      ${DatabaseConstants.villageName}
        TEXT NOT NULL COLLATE NOCASE,

      ${DatabaseConstants.villageCreatedAt}
        TEXT NOT NULL,

      FOREIGN KEY (
        ${DatabaseConstants.villageDepartmentId}
      )
      REFERENCES ${DatabaseConstants.departmentsTable} (
        ${DatabaseConstants.departmentId}
      )
      ON DELETE SET NULL,

      FOREIGN KEY (
        ${DatabaseConstants.villageMunicipalityId}
      )
      REFERENCES ${DatabaseConstants.municipalitiesTable} (
        ${DatabaseConstants.municipalityId}
      )
      ON DELETE SET NULL,

      FOREIGN KEY (
        ${DatabaseConstants.villageCorregimientoId}
      )
      REFERENCES ${DatabaseConstants.corregimientosTable} (
        ${DatabaseConstants.corregimientoId}
      )
      ON DELETE SET NULL,

      UNIQUE (
        ${DatabaseConstants.villageMunicipalityId},
        ${DatabaseConstants.villageCorregimientoId},
        ${DatabaseConstants.villageName}
      )
    )
  ''';
}
