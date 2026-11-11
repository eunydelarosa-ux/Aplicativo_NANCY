// ===============================================================
// APLICATIVO NANCY
// Tabla de Departamentos
// ===============================================================

import '../database_constants.dart';

class DepartmentTable {
  DepartmentTable._();

  static const String createTable =
      '''
    CREATE TABLE IF NOT EXISTS
    ${DatabaseConstants.departmentsTable} (

      ${DatabaseConstants.departmentId}
        INTEGER PRIMARY KEY AUTOINCREMENT,

      ${DatabaseConstants.departmentCode}
        TEXT UNIQUE,

      ${DatabaseConstants.departmentName}
        TEXT NOT NULL COLLATE NOCASE UNIQUE,

      ${DatabaseConstants.departmentCreatedAt}
        TEXT NOT NULL
    )
  ''';
}
