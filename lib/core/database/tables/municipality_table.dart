// ===============================================================
// APLICATIVO NANCY
// Tabla de Municipios
// ===============================================================

import '../database_constants.dart';

class MunicipalityTable {
  MunicipalityTable._();

  static const String createTable =
      '''
    CREATE TABLE IF NOT EXISTS
    ${DatabaseConstants.municipalitiesTable} (

      ${DatabaseConstants.municipalityId}
        INTEGER PRIMARY KEY AUTOINCREMENT,

      ${DatabaseConstants.municipalityDepartmentId}
        INTEGER NOT NULL,

      ${DatabaseConstants.municipalityCode}
        TEXT,

      ${DatabaseConstants.municipalityName}
        TEXT NOT NULL COLLATE NOCASE,

      ${DatabaseConstants.municipalityCreatedAt}
        TEXT NOT NULL,

      FOREIGN KEY (
        ${DatabaseConstants.municipalityDepartmentId}
      )
      REFERENCES ${DatabaseConstants.departmentsTable} (
        ${DatabaseConstants.departmentId}
      )
      ON DELETE CASCADE,

      UNIQUE (
        ${DatabaseConstants.municipalityDepartmentId},
        ${DatabaseConstants.municipalityName}
      )
    )
  ''';
}
