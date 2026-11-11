// ===============================================================
// APLICATIVO NANCY
// Tabla de Corregimientos
// ===============================================================

import '../database_constants.dart';

class CorregimientoTable {
  CorregimientoTable._();

  static const String createTable =
      '''
    CREATE TABLE IF NOT EXISTS
    ${DatabaseConstants.corregimientosTable} (

      ${DatabaseConstants.corregimientoId}
        INTEGER PRIMARY KEY AUTOINCREMENT,

      ${DatabaseConstants.corregimientoMunicipalityId}
        INTEGER NOT NULL,

      ${DatabaseConstants.corregimientoCode}
        TEXT,

      ${DatabaseConstants.corregimientoName}
        TEXT NOT NULL COLLATE NOCASE,

      ${DatabaseConstants.corregimientoCreatedAt}
        TEXT NOT NULL,

      FOREIGN KEY (
        ${DatabaseConstants.corregimientoMunicipalityId}
      )
      REFERENCES ${DatabaseConstants.municipalitiesTable} (
        ${DatabaseConstants.municipalityId}
      )
      ON DELETE CASCADE,

      UNIQUE (
        ${DatabaseConstants.corregimientoMunicipalityId},
        ${DatabaseConstants.corregimientoName}
      )
    )
  ''';
}
