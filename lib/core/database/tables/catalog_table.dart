// ===============================================================
// APLICATIVO NANCY
// Tabla de Catálogos
// ===============================================================

import '../database_constants.dart';

class CatalogTable {
  CatalogTable._();

  // =============================================================
  // TABLA ACTUAL DE CATÁLOGOS COMPARTIDOS
  // =============================================================

  static const String tableName = DatabaseConstants.catalogItemsTable;

  static const String createTable =
      '''
     CREATE TABLE IF NOT EXISTS $tableName (
       ${DatabaseConstants.catalogId}
         INTEGER PRIMARY KEY AUTOINCREMENT,

       ${DatabaseConstants.catalogType}
         TEXT NOT NULL,

       ${DatabaseConstants.catalogName}
         TEXT NOT NULL,

       ${DatabaseConstants.catalogParentId}
         INTEGER NOT NULL DEFAULT 0,

       ${DatabaseConstants.catalogActive}
         INTEGER NOT NULL DEFAULT 1,

       ${DatabaseConstants.catalogCreatedAt}
         TEXT NOT NULL,

       ${DatabaseConstants.catalogUpdatedAt}
         TEXT NOT NULL
     );
   ''';

  // =============================================================
  // TABLA DE CATÁLOGOS INDEPENDIENTES POR USUARIO
  // =============================================================

  static const String createUserCatalogItemsTable =
      '''
     CREATE TABLE IF NOT EXISTS
       ${DatabaseConstants.userCatalogItemsTable} (

       ${DatabaseConstants.catalogId}
         INTEGER PRIMARY KEY AUTOINCREMENT,

       ${DatabaseConstants.userCatalogUserId}
         INTEGER NOT NULL,

       ${DatabaseConstants.userCatalogSourceId}
         INTEGER,

       ${DatabaseConstants.catalogType}
         TEXT NOT NULL,

       ${DatabaseConstants.catalogName}
         TEXT NOT NULL,

       ${DatabaseConstants.catalogParentId}
         INTEGER NOT NULL DEFAULT 0,

       ${DatabaseConstants.catalogActive}
         INTEGER NOT NULL DEFAULT 1,

       ${DatabaseConstants.catalogCreatedAt}
         TEXT NOT NULL,

       ${DatabaseConstants.catalogUpdatedAt}
         TEXT NOT NULL
     );
   ''';

  // =============================================================
  // ÍNDICE PARA CONSULTAR LOS CATÁLOGOS DE CADA USUARIO
  // =============================================================

  static const String createUserCatalogItemsIndex =
      '''
     CREATE INDEX IF NOT EXISTS
       idx_user_catalog_items_user_type
     ON ${DatabaseConstants.userCatalogItemsTable} (
       ${DatabaseConstants.userCatalogUserId},
       ${DatabaseConstants.catalogType},
       ${DatabaseConstants.catalogActive}
     );
   ''';

  // =============================================================
  // TABLA DE CONTROL DE INICIALIZACIÓN POR USUARIO
  // =============================================================

  static const String createUserCatalogStateTable =
      '''
     CREATE TABLE IF NOT EXISTS
       ${DatabaseConstants.userCatalogStateTable} (

       ${DatabaseConstants.userCatalogUserId}
         INTEGER PRIMARY KEY,

       ${DatabaseConstants.userCatalogInitializedAt}
         TEXT NOT NULL
     );
   ''';
}
