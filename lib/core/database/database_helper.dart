// ===============================================================
// APLICATIVO NANCY
// Administrador de la Base de Datos SQLite
// ===============================================================

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'database_constants.dart';

import 'tables/applicant_table.dart';
import 'tables/user_profile_table.dart';
import 'tables/catalog_table.dart';
import 'tables/village_table.dart';

import 'tables/department_table.dart';
import 'tables/municipality_table.dart';
import 'tables/corregimiento_table.dart';
import 'tables/calendar_activity_table.dart';

import '../../features/location/data/colombia_location_seeder.dart';
import '../../features/catalogs/data/catalog_seeder.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  // =============================================================
  // OBTENER LA BASE DE DATOS
  // =============================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();

    return _database!;
  }

  // =============================================================
  // OBTENER RUTA COMPLETA DE LA BASE DE DATOS
  // =============================================================

  Future<String> getDatabaseFilePath() async {
    final String databasePath = await getDatabasesPath();

    return join(databasePath, DatabaseConstants.databaseName);
  }

  // =============================================================
  // INICIALIZAR BASE DE DATOS
  // =============================================================

  Future<Database> _initializeDatabase() async {
    final String path = await getDatabaseFilePath();

    final Database db = await openDatabase(
      path,

      // =========================================================
      // VERSIÓN ACTUAL
      // =========================================================
      version: DatabaseConstants.databaseVersion,

      // =========================================================
      // CREACIÓN INICIAL
      // =========================================================
      onCreate: (Database db, int version) async {
        // -------------------------------------------------------
        // TABLA DE ASPIRANTES
        // -------------------------------------------------------

        await db.execute(ApplicantTable.createTable);

        // -------------------------------------------------------
        // TABLA DE HISTORIAL DE SINCRONIZACIÓN
        // -------------------------------------------------------

        await db.execute('''
  CREATE TABLE IF NOT EXISTS ${DatabaseConstants.syncHistoryTable} (
    ${DatabaseConstants.historyId}
      INTEGER PRIMARY KEY AUTOINCREMENT,

    ${DatabaseConstants.historyApplicantId}
      TEXT NOT NULL,

    ${DatabaseConstants.historyStatus}
      TEXT NOT NULL,

    ${DatabaseConstants.historySyncedAt}
      TEXT NOT NULL,

    ${DatabaseConstants.historyAttempts}
      INTEGER NOT NULL DEFAULT 0,

    ${DatabaseConstants.historyMessage}
      TEXT,

    ${DatabaseConstants.historyCreatedByUserId}
      INTEGER,

    ${DatabaseConstants.historySiteId}
      INTEGER
  )
''');

        // -------------------------------------------------------
        // TABLA DEL PERFIL DEL USUARIO
        // -------------------------------------------------------

        await db.execute(UserProfileTable.createTable);

        await db.execute('''
  CREATE TABLE IF NOT EXISTS deleted_usernames (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL COLLATE NOCASE,
    deleted_at TEXT NOT NULL
  )
''');

        // -------------------------------------------------------
        // TABLA DE CATÁLOGOS GENERALES
        // -------------------------------------------------------

        await db.execute(CatalogTable.createTable);

        // -------------------------------------------------------
        // TABLAS DE CATÁLOGOS INDEPENDIENTES POR USUARIO
        // -------------------------------------------------------

        await db.execute(CatalogTable.createUserCatalogItemsTable);
        await db.execute(CatalogTable.createUserCatalogItemsIndex);
        await db.execute(CatalogTable.createUserCatalogStateTable);

        // -------------------------------------------------------
        // CARGAR CATÁLOGOS INICIALES
        // -------------------------------------------------------

        final CatalogSeeder catalogSeeder = CatalogSeeder(db);

        await catalogSeeder.seed();

        // -------------------------------------------------------
        // TABLAS DE UBICACIÓN
        // -------------------------------------------------------

        await db.execute(DepartmentTable.createTable);

        await db.execute(MunicipalityTable.createTable);

        await db.execute(CorregimientoTable.createTable);

        await db.execute(VillageTable.createTable);

        // -------------------------------------------------------
        // TABLA DE ACTIVIDADES DEL CALENDARIO
        // -------------------------------------------------------

        await db.execute(CalendarActivityTable.createTable);

        // -------------------------------------------------------
        // TABLA PARA FRECUENCIA DE SELECCIÓN DE UBICACIONES
        // -------------------------------------------------------

        await db.execute('''
          CREATE TABLE IF NOT EXISTS location_selection_frequency (
            location_type TEXT NOT NULL,
            location_id INTEGER NOT NULL,
            frequency INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (location_type, location_id)
          )
        ''');

        // -------------------------------------------------------
        // TABLA DE SEDES
        // -------------------------------------------------------

        await db.execute('''
          CREATE TABLE IF NOT EXISTS
          ${DatabaseConstants.sitesTable} (
            ${DatabaseConstants.siteId}
              INTEGER PRIMARY KEY AUTOINCREMENT,

            ${DatabaseConstants.siteName}
              TEXT NOT NULL,

            ${DatabaseConstants.siteAddress}
              TEXT,

            ${DatabaseConstants.siteActive}
              INTEGER NOT NULL DEFAULT 1,

            ${DatabaseConstants.siteCreatedAt}
              TEXT NOT NULL,

            ${DatabaseConstants.siteUpdatedAt}
              TEXT NOT NULL
          )
        ''');

        // -------------------------------------------------------
        // RELACIÓN SEDES - MUNICIPIOS
        // -------------------------------------------------------

        await db.execute('''
          CREATE TABLE IF NOT EXISTS
          ${DatabaseConstants.siteMunicipalitiesTable} (
            ${DatabaseConstants.siteMunicipalitySiteId}
              INTEGER NOT NULL,

            ${DatabaseConstants.siteMunicipalityMunicipalityId}
              INTEGER NOT NULL,

            PRIMARY KEY (
              ${DatabaseConstants.siteMunicipalitySiteId},
              ${DatabaseConstants.siteMunicipalityMunicipalityId}
            )
          )
        ''');
      },

      // =========================================================
      // MIGRACIONES
      // =========================================================
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // =======================================================
        // VERSIÓN 2 → 3
        // =======================================================

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${UserProfileTable.tableName} (

              ${UserProfileTable.id}
                INTEGER PRIMARY KEY AUTOINCREMENT,

              ${UserProfileTable.name}
                TEXT NOT NULL,

              ${UserProfileTable.role}
                TEXT NOT NULL,

              ${UserProfileTable.email}
                TEXT,

              ${UserProfileTable.phone}
                TEXT,

              ${UserProfileTable.imagePath}
                TEXT,

              ${UserProfileTable.createdAt}
                TEXT NOT NULL,

              ${UserProfileTable.updatedAt}
                TEXT NOT NULL

            )
          ''');
        }

        // =======================================================
        // VERSIÓN 3 → 4
        // =======================================================

        if (oldVersion < 4) {
          await db.execute(CatalogTable.createTable);
        }

        // =======================================================
        // VERSIÓN 4 → 5
        // =======================================================

        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS
            ${DatabaseConstants.catalogItemsTable} (

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

            )
          ''');
        }

        // =======================================================
        // VERSIÓN 5 → 6
        // =======================================================

        if (oldVersion < 6) {
          final List<Map<String, dynamic>> columns = await db.rawQuery(
            'PRAGMA table_info(${DatabaseConstants.applicantsTable})',
          );

          final bool hasIsDeleted = columns.any(
            (column) => column['name'] == DatabaseConstants.isDeleted,
          );

          final bool hasDeletedAt = columns.any(
            (column) => column['name'] == DatabaseConstants.deletedAt,
          );

          if (!hasIsDeleted) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.applicantsTable}
              ADD COLUMN ${DatabaseConstants.isDeleted}
              INTEGER NOT NULL DEFAULT 0
            ''');
          }

          if (!hasDeletedAt) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.applicantsTable}
              ADD COLUMN ${DatabaseConstants.deletedAt}
              TEXT
            ''');
          }
        }

        // =======================================================
        // VERSIÓN 6 → 7
        // =======================================================

        if (oldVersion < 7) {
          // -----------------------------------------------------
          // CREAR TABLA DE VEREDAS
          // -----------------------------------------------------

          await db.execute(VillageTable.createTable);

          // -----------------------------------------------------
          // COMPROBAR COLUMNA village EN applicants
          // -----------------------------------------------------

          final List<Map<String, dynamic>> columns = await db.rawQuery(
            'PRAGMA table_info(${DatabaseConstants.applicantsTable})',
          );

          final bool hasVillage = columns.any(
            (column) => column['name'] == DatabaseConstants.village,
          );

          // -----------------------------------------------------
          // AGREGAR COLUMNA village
          // -----------------------------------------------------

          if (!hasVillage) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.applicantsTable}
              ADD COLUMN ${DatabaseConstants.village}
              TEXT
            ''');
          }

          // -----------------------------------------------------
          // CONSERVAR LAS VEREDAS EXISTENTES
          // -----------------------------------------------------
        }
        // =======================================================
        // VERSIÓN 7 → 8
        // =======================================================

        if (oldVersion < 8) {
          // -----------------------------------------------------
          // CREAR TABLAS PRINCIPALES DE UBICACIÓN
          // -----------------------------------------------------

          await db.execute(DepartmentTable.createTable);

          await db.execute(MunicipalityTable.createTable);

          await db.execute(CorregimientoTable.createTable);

          // -----------------------------------------------------
          // REVISAR COLUMNAS DE applicants
          // -----------------------------------------------------

          final List<Map<String, dynamic>> applicantColumns = await db.rawQuery(
            'PRAGMA table_info(${DatabaseConstants.applicantsTable})',
          );

          bool hasApplicantColumn(String columnName) {
            return applicantColumns.any(
              (column) => column['name'] == columnName,
            );
          }

          // -----------------------------------------------------
          // ESCOLARIDAD
          // -----------------------------------------------------

          if (!hasApplicantColumn(DatabaseConstants.schooling)) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.applicantsTable}
              ADD COLUMN ${DatabaseConstants.schooling} TEXT
            ''');
          }

          // -----------------------------------------------------
          // CORREGIMIENTO
          // -----------------------------------------------------

          if (!hasApplicantColumn(DatabaseConstants.corregimiento)) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.applicantsTable}
              ADD COLUMN ${DatabaseConstants.corregimiento} TEXT
            ''');
          }

          // -----------------------------------------------------
          // RESPONSABLE DEL REGISTRO
          // -----------------------------------------------------

          if (!hasApplicantColumn(DatabaseConstants.responsibleName)) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.applicantsTable}
              ADD COLUMN ${DatabaseConstants.responsibleName} TEXT
            ''');
          }

          if (!hasApplicantColumn(DatabaseConstants.responsibleRole)) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.applicantsTable}
              ADD COLUMN ${DatabaseConstants.responsibleRole} TEXT
            ''');
          }

          // -----------------------------------------------------
          // ACTUALIZAR ESTRUCTURA DE villages
          // -----------------------------------------------------

          final List<Map<String, dynamic>> villageColumns = await db.rawQuery(
            'PRAGMA table_info(${DatabaseConstants.villagesTable})',
          );

          bool hasVillageColumn(String columnName) {
            return villageColumns.any((column) => column['name'] == columnName);
          }

          // DEPARTAMENTO
          if (!hasVillageColumn(DatabaseConstants.villageDepartmentId)) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.villagesTable}
              ADD COLUMN ${DatabaseConstants.villageDepartmentId} INTEGER
            ''');
          }

          // MUNICIPIO
          if (!hasVillageColumn(DatabaseConstants.villageMunicipalityId)) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.villagesTable}
              ADD COLUMN ${DatabaseConstants.villageMunicipalityId} INTEGER
            ''');
          }

          // CORREGIMIENTO
          if (!hasVillageColumn(DatabaseConstants.villageCorregimientoId)) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.villagesTable}
              ADD COLUMN ${DatabaseConstants.villageCorregimientoId} INTEGER
            ''');
          }

          // CÓDIGO DE LA VEREDA
          if (!hasVillageColumn(DatabaseConstants.villageCode)) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.villagesTable}
              ADD COLUMN ${DatabaseConstants.villageCode} TEXT
            ''');
          }
        }

        // =======================================================
        // VERSIÓN 8 → 9
        // AGREGAR CÉDULA AL PERFIL
        // =======================================================

        if (oldVersion < 9) {
          final List<Map<String, dynamic>> columns = await db.rawQuery(
            'PRAGMA table_info(${UserProfileTable.tableName})',
          );

          final bool hasCedula = columns.any(
            (column) => column['name'] == UserProfileTable.cedula,
          );

          if (!hasCedula) {
            await db.execute('''
              ALTER TABLE ${UserProfileTable.tableName}
              ADD COLUMN ${UserProfileTable.cedula} TEXT
            ''');
          }
        }

        // =======================================================
        // VERSIÓN 9 → 10
        // VERIFICAR Y AGREGAR CÉDULA AL PERFIL
        // =======================================================

        if (oldVersion < 10) {
          final List<Map<String, dynamic>> profileColumns = await db.rawQuery(
            'PRAGMA table_info(${UserProfileTable.tableName})',
          );

          final bool hasCedula = profileColumns.any(
            (column) => column['name'] == UserProfileTable.cedula,
          );

          if (!hasCedula) {
            await db.execute('''
              ALTER TABLE ${UserProfileTable.tableName}
              ADD COLUMN ${UserProfileTable.cedula} TEXT
            ''');
          }
        }

        // =======================================================
        // VERSIÓN 10 → 11
        // AGREGAR CÉDULA DEL RESPONSABLE DEL REGISTRO
        // =======================================================

        if (oldVersion < 11) {
          final List<Map<String, dynamic>> applicantColumns = await db.rawQuery(
            'PRAGMA table_info(${DatabaseConstants.applicantsTable})',
          );

          final bool hasResponsibleCedula = applicantColumns.any(
            (column) => column['name'] == DatabaseConstants.responsibleCedula,
          );

          if (!hasResponsibleCedula) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.applicantsTable}
              ADD COLUMN ${DatabaseConstants.responsibleCedula} TEXT
            ''');
          }
        }

        // =======================================================
        // VERSIÓN 11 → 12
        // FRECUENCIA DE SELECCIÓN DE UBICACIONES
        // =======================================================

        if (oldVersion < 12) {
          await db.execute('''
    CREATE TABLE IF NOT EXISTS location_selection_frequency (
      location_type TEXT NOT NULL,
      location_id INTEGER NOT NULL,
      frequency INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (location_type, location_id)
    )
  ''');
        }

        // =======================================================
        // NUEVA MIGRACIÓN: CALENDARIO
        // =======================================================

        if (oldVersion < 13) {
          await db.execute(CalendarActivityTable.createTable);
        }

        // =======================================================
        // VERSIÓN 13 → 14
        // AGREGAR DATOS DE AUTENTICACIÓN Y MUNICIPIO AL PERFIL
        // =======================================================

        if (oldVersion < 14) {
          final List<Map<String, dynamic>> profileColumns = await db.rawQuery(
            'PRAGMA table_info(${UserProfileTable.tableName})',
          );

          bool hasProfileColumn(String columnName) {
            return profileColumns.any((column) => column['name'] == columnName);
          }

          // -------------------------------------------------------
          // USUARIO / NOMBRE DE ACCESO
          // -------------------------------------------------------

          if (!hasProfileColumn(UserProfileTable.username)) {
            await db.execute('''
              ALTER TABLE ${UserProfileTable.tableName}
              ADD COLUMN ${UserProfileTable.username}
              TEXT NOT NULL DEFAULT ''
            ''');
          }

          // -------------------------------------------------------
          // MUNICIPIO ASOCIADO AL USUARIO
          // -------------------------------------------------------

          if (!hasProfileColumn(UserProfileTable.municipalityId)) {
            await db.execute('''
              ALTER TABLE ${UserProfileTable.tableName}
              ADD COLUMN ${UserProfileTable.municipalityId}
              INTEGER
            ''');
          }

          // -------------------------------------------------------
          // CONTRASEÑA ALMACENADA COMO HASH
          // -------------------------------------------------------

          if (!hasProfileColumn(UserProfileTable.passwordHash)) {
            await db.execute('''
              ALTER TABLE ${UserProfileTable.tableName}
              ADD COLUMN ${UserProfileTable.passwordHash}
              TEXT NOT NULL DEFAULT ''
            ''');
          }

          // -------------------------------------------------------
          // ESTADO DEL USUARIO
          // -------------------------------------------------------

          if (!hasProfileColumn(UserProfileTable.isActive)) {
            await db.execute('''
              ALTER TABLE ${UserProfileTable.tableName}
              ADD COLUMN ${UserProfileTable.isActive}
              INTEGER NOT NULL DEFAULT 1
            ''');
          }
        }

        // =======================================================
        // VERSIÓN 14 → 15
        // CREAR SEDES Y RELACIÓN SEDES - MUNICIPIOS
        // =======================================================

        if (oldVersion < 15) {
          // -----------------------------------------------------
          // TABLA DE SEDES
          // -----------------------------------------------------

          await db.execute('''
            CREATE TABLE IF NOT EXISTS
            ${DatabaseConstants.sitesTable} (
              ${DatabaseConstants.siteId}
                INTEGER PRIMARY KEY AUTOINCREMENT,

              ${DatabaseConstants.siteName}
                TEXT NOT NULL,

              ${DatabaseConstants.siteAddress}
                TEXT,

              ${DatabaseConstants.siteActive}
                INTEGER NOT NULL DEFAULT 1,

              ${DatabaseConstants.siteCreatedAt}
                TEXT NOT NULL,

              ${DatabaseConstants.siteUpdatedAt}
                TEXT NOT NULL
            )
          ''');

          // -----------------------------------------------------
          // RELACIÓN SEDES - MUNICIPIOS
          // -----------------------------------------------------

          await db.execute('''
            CREATE TABLE IF NOT EXISTS
            ${DatabaseConstants.siteMunicipalitiesTable} (
              ${DatabaseConstants.siteMunicipalitySiteId}
                INTEGER NOT NULL,

              ${DatabaseConstants.siteMunicipalityMunicipalityId}
                INTEGER NOT NULL,

              PRIMARY KEY (
                ${DatabaseConstants.siteMunicipalitySiteId},
                ${DatabaseConstants.siteMunicipalityMunicipalityId}
              )
            )
          ''');
        }

        // =======================================================
        // VERSIÓN 15 → 16
        // REPARAR TABLAS DE SEDES
        // =======================================================

        if (oldVersion < 16) {
          // -----------------------------------------------------
          // TABLA DE SEDES
          // -----------------------------------------------------

          await db.execute('''
            CREATE TABLE IF NOT EXISTS
            ${DatabaseConstants.sitesTable} (
              ${DatabaseConstants.siteId}
                INTEGER PRIMARY KEY AUTOINCREMENT,

              ${DatabaseConstants.siteName}
                TEXT NOT NULL,

              ${DatabaseConstants.siteAddress}
                TEXT,

              ${DatabaseConstants.siteActive}
                INTEGER NOT NULL DEFAULT 1,

              ${DatabaseConstants.siteCreatedAt}
                TEXT NOT NULL,

              ${DatabaseConstants.siteUpdatedAt}
                TEXT NOT NULL
            )
          ''');

          // -----------------------------------------------------
          // RELACIÓN SEDES - MUNICIPIOS
          // -----------------------------------------------------

          await db.execute('''
            CREATE TABLE IF NOT EXISTS
            ${DatabaseConstants.siteMunicipalitiesTable} (
              ${DatabaseConstants.siteMunicipalitySiteId}
                INTEGER NOT NULL,

              ${DatabaseConstants.siteMunicipalityMunicipalityId}
                INTEGER NOT NULL,

              PRIMARY KEY (
                ${DatabaseConstants.siteMunicipalitySiteId},
                ${DatabaseConstants.siteMunicipalityMunicipalityId}
              )
            )
          ''');
        }

        // =======================================================
        // VERSIÓN 16 → 17
        // AGREGAR USUARIO CREADOR
        // =======================================================

        if (oldVersion < 17) {
          final List<Map<String, dynamic>> profileColumns = await db.rawQuery(
            'PRAGMA table_info(${UserProfileTable.tableName})',
          );

          final bool hasCreatedByUserId = profileColumns.any(
            (column) => column['name'] == UserProfileTable.createdByUserId,
          );

          if (!hasCreatedByUserId) {
            await db.execute('''
              ALTER TABLE ${UserProfileTable.tableName}
              ADD COLUMN ${UserProfileTable.createdByUserId}
              INTEGER
            ''');
          }
        }

        // =======================================================
        // VERSIÓN 17 → 18
        // REGISTRAR NOMBRES DE USUARIO ELIMINADOS
        // =======================================================

        if (oldVersion < 18) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS deleted_usernames (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL COLLATE NOCASE,
              deleted_at TEXT NOT NULL
            )
          ''');
        }

        // =======================================================
        // VERSIÓN 18 → 19
        // AGREGAR CAMPOS PARA ACTIVACIÓN DE CUENTAS
        // =======================================================

        if (oldVersion < 19) {
          final List<Map<String, dynamic>> profileColumns = await db.rawQuery(
            'PRAGMA table_info(${UserProfileTable.tableName})',
          );

          bool hasProfileColumn(String columnName) {
            return profileColumns.any((column) => column['name'] == columnName);
          }

          // HASH DEL CÓDIGO DE ACTIVACIÓN
          if (!hasProfileColumn(UserProfileTable.activationCodeHash)) {
            await db.execute('''
              ALTER TABLE ${UserProfileTable.tableName}
              ADD COLUMN ${UserProfileTable.activationCodeHash} TEXT
            ''');
          }

          // INDICAR SI DEBE CREAR SU CONTRASEÑA PERSONAL
          if (!hasProfileColumn(UserProfileTable.mustChangePassword)) {
            await db.execute('''
              ALTER TABLE ${UserProfileTable.tableName}
              ADD COLUMN ${UserProfileTable.mustChangePassword}
              INTEGER NOT NULL DEFAULT 0
            ''');
          }
        }

        // =======================================================
        // VERSIÓN 19 → 20
        // AGREGAR CAMPOS DE CONTROL DE SINCRONIZACIÓN
        // =======================================================

        if (oldVersion < 20) {
          final List<Map<String, dynamic>> applicantColumns = await db.rawQuery(
            'PRAGMA table_info(${DatabaseConstants.applicantsTable})',
          );

          bool hasApplicantColumn(String columnName) {
            return applicantColumns.any(
              (column) => column['name'] == columnName,
            );
          }

          // -------------------------------------------------------
          // CANTIDAD DE INTENTOS
          // -------------------------------------------------------

          if (!hasApplicantColumn(DatabaseConstants.syncAttempts)) {
            await db.execute('''
      ALTER TABLE ${DatabaseConstants.applicantsTable}
      ADD COLUMN ${DatabaseConstants.syncAttempts}
      INTEGER NOT NULL DEFAULT 0
    ''');
          }

          // -------------------------------------------------------
          // FECHA DEL ÚLTIMO INTENTO
          // -------------------------------------------------------

          if (!hasApplicantColumn(DatabaseConstants.lastSyncAttempt)) {
            await db.execute('''
      ALTER TABLE ${DatabaseConstants.applicantsTable}
      ADD COLUMN ${DatabaseConstants.lastSyncAttempt}
      TEXT
    ''');
          }

          // -------------------------------------------------------
          // ÚLTIMO ERROR
          // -------------------------------------------------------

          if (!hasApplicantColumn(DatabaseConstants.lastSyncError)) {
            await db.execute('''
      ALTER TABLE ${DatabaseConstants.applicantsTable}
      ADD COLUMN ${DatabaseConstants.lastSyncError}
      TEXT
    ''');
          }

          // -------------------------------------------------------
          // FECHA DE SINCRONIZACIÓN
          // -------------------------------------------------------

          if (!hasApplicantColumn(DatabaseConstants.syncedAt)) {
            await db.execute('''
    ALTER TABLE ${DatabaseConstants.applicantsTable}
    ADD COLUMN ${DatabaseConstants.syncedAt}
    TEXT
  ''');
          }
        }

        // =======================================================
        // VERSIÓN 20 → 21
        // CREAR HISTORIAL TEMPORAL DE SINCRONIZACIÓN
        // =======================================================

        if (oldVersion < 21) {
          await db.execute('''
    CREATE TABLE IF NOT EXISTS ${DatabaseConstants.syncHistoryTable} (
      ${DatabaseConstants.historyId}
        INTEGER PRIMARY KEY AUTOINCREMENT,

      ${DatabaseConstants.historyApplicantId}
        TEXT NOT NULL,

      ${DatabaseConstants.historyStatus}
        TEXT NOT NULL,

      ${DatabaseConstants.historySyncedAt}
        TEXT NOT NULL,

      ${DatabaseConstants.historyAttempts}
        INTEGER NOT NULL DEFAULT 0,

      ${DatabaseConstants.historyMessage}
        TEXT
    )
  ''');
        }

        // =======================================================
        // VERSIÓN 21 → 22
        // AGREGAR IDENTIDAD INTERNA A LOS ASPIRANTES
        // =======================================================

        if (oldVersion < 22) {
          final List<Map<String, dynamic>> applicantColumns = await db.rawQuery(
            'PRAGMA table_info(${DatabaseConstants.applicantsTable})',
          );

          bool hasApplicantColumn(String columnName) {
            return applicantColumns.any(
              (column) => column['name'] == columnName,
            );
          }

          // -----------------------------------------------------
          // IDENTIFICADOR DEL USUARIO CREADOR
          // -----------------------------------------------------

          if (!hasApplicantColumn(DatabaseConstants.applicantCreatedByUserId)) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.applicantsTable}
              ADD COLUMN ${DatabaseConstants.applicantCreatedByUserId}
              INTEGER
            ''');
          }

          // -----------------------------------------------------
          // IDENTIFICADOR DE LA SEDE DEL ASPIRANTE
          // -----------------------------------------------------

          if (!hasApplicantColumn(DatabaseConstants.applicantSiteId)) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.applicantsTable}
              ADD COLUMN ${DatabaseConstants.applicantSiteId}
              INTEGER
            ''');
          }
        }

        // =======================================================
        // VERSIÓN 22 → 23
        // AGREGAR IDENTIDAD INTERNA AL HISTORIAL
        // =======================================================

        if (oldVersion < 23) {
          final List<Map<String, dynamic>> historyColumns = await db.rawQuery(
            'PRAGMA table_info(${DatabaseConstants.syncHistoryTable})',
          );

          bool hasHistoryColumn(String columnName) {
            return historyColumns.any((column) => column['name'] == columnName);
          }

          // IDENTIFICADOR DEL USUARIO CREADOR
          if (!hasHistoryColumn(DatabaseConstants.historyCreatedByUserId)) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.syncHistoryTable}
              ADD COLUMN ${DatabaseConstants.historyCreatedByUserId}
              INTEGER
            ''');
          }

          // IDENTIFICADOR DE LA SEDE
          if (!hasHistoryColumn(DatabaseConstants.historySiteId)) {
            await db.execute('''
              ALTER TABLE ${DatabaseConstants.syncHistoryTable}
              ADD COLUMN ${DatabaseConstants.historySiteId}
              INTEGER
            ''');
          }
        }

        // =======================================================
        // VERSIÓN 23 → 24
        // CREAR TABLAS DE CATÁLOGOS INDEPENDIENTES POR USUARIO
        // =======================================================

        if (oldVersion < 24) {
          await db.execute(CatalogTable.createUserCatalogItemsTable);
          await db.execute(CatalogTable.createUserCatalogItemsIndex);
          await db.execute(CatalogTable.createUserCatalogStateTable);
        }

        // =======================================================
        // VERSIÓN 24 → 25
        // AGREGAR PROPIETARIO A LAS ACTIVIDADES DEL CALENDARIO
        // =======================================================

        if (oldVersion < 25) {
          final List<Map<String, dynamic>> calendarColumns = await db.rawQuery(
            'PRAGMA table_info(${CalendarActivityTable.tableName})',
          );

          final bool hasUserId = calendarColumns.any(
            (column) => column['name'] == CalendarActivityTable.userIdColumn,
          );

          if (!hasUserId) {
            await db.execute('''
              ALTER TABLE ${CalendarActivityTable.tableName}
              ADD COLUMN ${CalendarActivityTable.userIdColumn} INTEGER
            ''');
          }
        }
      },
    );
    // =============================================================
    // CONECTAR LA INSTANCIA
    // =============================================================

    _database = db;

    // =============================================================
    // ASEGURAR ADMINISTRADOR INICIAL
    // =============================================================

    await _ensureInitialAdministrator(db);

    // =============================================================
    // ASIGNAR ACTIVIDADES ANTIGUAS AL ADMINISTRADOR
    // =============================================================

    final List<Map<String, dynamic>> administrators = await db.query(
      UserProfileTable.tableName,
      columns: [UserProfileTable.id],
      where: 'LOWER(${UserProfileTable.role}) = ?',
      whereArgs: ['administrador'],
      orderBy: '${UserProfileTable.id} ASC',
      limit: 1,
    );

    if (administrators.isNotEmpty) {
      final dynamic administratorId = administrators.first[UserProfileTable.id];

      await db.update(
        CalendarActivityTable.tableName,
        {CalendarActivityTable.userIdColumn: administratorId},
        where: '${CalendarActivityTable.userIdColumn} IS NULL',
      );
    }

    // =============================================================
    // CARGAR UBICACIONES DESDE colombia_locations.json
    // =============================================================

    try {
      final ColombiaLocationSeeder seeder = ColombiaLocationSeeder();

      await seeder.seed();
    } catch (error, stackTrace) {
      debugPrint('Error al cargar ubicaciones de Colombia: $error');

      debugPrint('$stackTrace');
    }

    return db;
  }

  // =============================================================
  // CERRAR BASE DE DATOS
  // =============================================================

  Future<void> closeDatabase() async {
    if (_database == null) {
      return;
    }

    await _database!.close();

    _database = null;
  }

  // =============================================================
  // CREAR ADMINISTRADOR INICIAL
  // =============================================================

  Future<void> _ensureInitialAdministrator(Database db) async {
    const String username = 'nancyadmin';
    const String password = 'Nancy123*';

    final List<Map<String, dynamic>> existingUsers = await db.query(
      UserProfileTable.tableName,
      columns: [UserProfileTable.id],
      where: 'LOWER(${UserProfileTable.username}) = LOWER(?)',
      whereArgs: [username],
      limit: 1,
    );

    if (existingUsers.isNotEmpty) {
      return;
    }

    final DateTime now = DateTime.now();

    final String passwordHash = sha256
        .convert(utf8.encode(password))
        .toString();

    await db.insert(UserProfileTable.tableName, {
      UserProfileTable.name: 'Administrador NANCY',
      UserProfileTable.role: 'Administrador',
      UserProfileTable.username: username,
      UserProfileTable.email: '',
      UserProfileTable.phone: '',
      UserProfileTable.cedula: null,
      UserProfileTable.imagePath: null,
      UserProfileTable.municipalityId: null,
      UserProfileTable.siteId: null,
      UserProfileTable.passwordHash: passwordHash,
      UserProfileTable.isActive: 1,
      UserProfileTable.createdAt: now.toIso8601String(),
      UserProfileTable.updatedAt: now.toIso8601String(),
    });
  }
}
