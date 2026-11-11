// =============================================================
// APLICATIVO NANCY
// Servicio de Copias de Seguridad
// =============================================================

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_constants.dart';
import '../../../../core/database/database_helper.dart';
import '../../../session/session_manager.dart';
import '../../models/backup_applicant_model.dart';
import '../../models/backup_model.dart';

class BackupService {
  // Identificador interno para reconocer las copias aisladas
  // creadas para coordinadores.
  static const int _coordinatorBackupUserVersion = 98231;

  // =============================================================
  // VERIFICAR PERMISOS
  // =============================================================

  void _ensureBackupPermission() {
    final SessionManager session = SessionManager.instance;

    if (!session.hasActiveSession) {
      throw StateError(
        'Debes iniciar sesión para utilizar las copias de seguridad.',
      );
    }

    if (session.isAdministrator) {
      return;
    }

    if (session.isCoordinator) {
      if (session.currentUser?.id == null) {
        throw StateError(
          'No fue posible identificar al coordinador conectado.',
        );
      }

      return;
    }

    throw StateError(
      'Tu rol no tiene permiso para utilizar las copias de seguridad.',
    );
  }

  // =============================================================
  // OBTENER CARPETA DE COPIAS
  // =============================================================

  Future<Directory> _getBackupsDirectory() async {
    final String databasePath = await DatabaseHelper.instance
        .getDatabaseFilePath();

    final Directory databaseDirectory = File(databasePath).parent;

    final Directory backupsDirectory = Directory(
      path.join(databaseDirectory.path, 'backups'),
    );

    if (!await backupsDirectory.exists()) {
      await backupsDirectory.create(recursive: true);
    }

    return backupsDirectory;
  }

  // =============================================================
  // VERIFICAR QUE UNA COPIA DE COORDINADOR ESTÉ AISLADA
  // =============================================================
  // =============================================================
  // VERIFICAR QUE UNA COPIA DE COORDINADOR ESTÉ AISLADA
  // =============================================================

  Future<bool> _isIsolatedCoordinatorBackup(File file) async {
    Database? backupDatabase;

    try {
      backupDatabase = await openDatabase(file.path, readOnly: true);

      // Obtener las tablas, vistas y disparadores de la copia.
      final List<Map<String, Object?>> objects = await backupDatabase.rawQuery(
        '''
        SELECT name, type
        FROM sqlite_master
        WHERE type IN ('table', 'view', 'trigger')
          AND name NOT LIKE 'sqlite_%'
          AND name != 'android_metadata'
      ''',
      );

      return objects.length == 1 &&
          objects.first['name'] == DatabaseConstants.applicantsTable &&
          objects.first['type'] == 'table';
    } catch (_) {
      return false;
    } finally {
      await backupDatabase?.close();
    }
  }
  // =============================================================
  // VALIDAR RUTA Y PROPIETARIO DE UNA COPIA
  // =============================================================

  Future<File> _validateBackupFile(String backupPath) async {
    _ensureBackupPermission();

    final Directory backupsDirectory = await _getBackupsDirectory();

    final String normalizedDirectoryPath = path.normalize(
      path.absolute(backupsDirectory.path),
    );

    final String normalizedBackupPath = path.normalize(
      path.absolute(backupPath),
    );

    // Impedir el acceso a archivos que estén fuera de la carpeta
    // destinada a las copias de seguridad.
    if (!path.isWithin(normalizedDirectoryPath, normalizedBackupPath)) {
      throw StateError('La ruta de la copia de seguridad no está autorizada.');
    }

    final String fileName = path.basename(normalizedBackupPath);

    if (!fileName.startsWith('backup_nancy_') ||
        path.extension(fileName).toLowerCase() != '.db') {
      throw StateError(
        'El archivo seleccionado no es una copia de seguridad válida.',
      );
    }

    final SessionManager session = SessionManager.instance;

    if (session.isCoordinator) {
      final int? userId = session.currentUser?.id;

      if (userId == null ||
          !fileName.startsWith('backup_nancy_user_${userId}_')) {
        throw StateError(
          'Solo puedes acceder a tus propias copias de seguridad.',
        );
      }
    }

    final File backupFile = File(normalizedBackupPath);

    if (!await backupFile.exists()) {
      throw Exception('No se encontró el archivo de la copia de seguridad.');
    }

    // No aceptar enlaces simbólicos como archivos de copia.
    final FileSystemEntityType entityType = await FileSystemEntity.type(
      normalizedBackupPath,
      followLinks: false,
    );

    if (entityType != FileSystemEntityType.file) {
      throw StateError(
        'La ruta seleccionada no corresponde a un archivo válido.',
      );
    }

    // Además del nombre, comprobar que el archivo realmente tenga
    // la estructura de una copia aislada.
    if (session.isCoordinator &&
        !await _isIsolatedCoordinatorBackup(backupFile)) {
      throw StateError(
        'La copia no es una copia aislada válida de tu usuario.',
      );
    }

    return backupFile;
  }

  // =============================================================
  // CREAR COPIA AISLADA DEL COORDINADOR
  // =============================================================

  Future<void> _createCoordinatorBackup({
    required Database sourceDatabase,
    required String backupPath,
    required int userId,
  }) async {
    // Obtener la definición real de la tabla para mantener las
    // columnas actuales sin copiar las demás tablas de NANCY.
    final List<Map<String, Object?>> tableDefinitions = await sourceDatabase
        .rawQuery(
          '''
      SELECT sql
      FROM sqlite_master
      WHERE type = ?
        AND name = ?
      ''',
          ['table', DatabaseConstants.applicantsTable],
        );

    if (tableDefinitions.isEmpty) {
      throw StateError(
        'No se encontró la estructura de la tabla de aspirantes.',
      );
    }

    final String? createTableSql = tableDefinitions.first['sql'] as String?;

    if (createTableSql == null || createTableSql.trim().isEmpty) {
      throw StateError(
        'No fue posible obtener la estructura de los aspirantes.',
      );
    }

    // Consultar únicamente los aspirantes registrados por el usuario
    // conectado. Se incluyen también sus registros en papelera.
    final List<Map<String, Object?>> applicants = await sourceDatabase.query(
      DatabaseConstants.applicantsTable,
      where: '${DatabaseConstants.applicantCreatedByUserId} = ?',
      whereArgs: [userId],
    );

    Database? isolatedDatabase;

    try {
      // Crear una base de datos nueva: no copiar nancy.db.
      isolatedDatabase = await openDatabase(backupPath, version: 1);

      // Crear solamente la tabla de aspirantes.
      await isolatedDatabase.execute(createTableSql);

      // Insertar exclusivamente los registros del coordinador.
      await isolatedDatabase.transaction((Transaction transaction) async {
        for (final Map<String, Object?> applicant in applicants) {
          await transaction.insert(
            DatabaseConstants.applicantsTable,
            applicant,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      });

      // Marcar la estructura de las copias aisladas.
      await isolatedDatabase.execute(
        'PRAGMA user_version = $_coordinatorBackupUserVersion',
      );
    } catch (_) {
      if (isolatedDatabase != null) {
        await isolatedDatabase.close();
        isolatedDatabase = null;
      }

      // No conservar copias incompletas si ocurre un error.
      final File partialFile = File(backupPath);

      if (await partialFile.exists()) {
        await partialFile.delete();
      }

      rethrow;
    } finally {
      await isolatedDatabase?.close();
    }
  }

  // =============================================================
  // CREAR COPIA DE SEGURIDAD
  // =============================================================

  Future<File> createBackup() async {
    try {
      _ensureBackupPermission();

      final SessionManager session = SessionManager.instance;
      final currentUser = session.currentUser!;

      final Database sourceDatabase = await DatabaseHelper.instance.database;

      final String databasePath = await DatabaseHelper.instance
          .getDatabaseFilePath();

      final File databaseFile = File(databasePath);

      if (!await databaseFile.exists()) {
        throw Exception('No se encontró la base de datos nancy.db.');
      }

      final Directory backupsDirectory = await _getBackupsDirectory();

      final DateTime now = DateTime.now();

      final String dateTime =
          '${now.year}'
          '_${now.month.toString().padLeft(2, '0')}'
          '_${now.day.toString().padLeft(2, '0')}'
          '_${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}'
          '${now.millisecond.toString().padLeft(3, '0')}'
          '${now.microsecond.toString().padLeft(3, '0')}';

      final String backupFileName;

      if (session.isAdministrator) {
        // El administrador conserva la copia completa.
        backupFileName = 'backup_nancy_$dateTime.db';
      } else {
        // Cada coordinador tiene un espacio de nombres propio.
        backupFileName = 'backup_nancy_user_${currentUser.id}_$dateTime.db';
      }

      final String backupPath = path.join(
        backupsDirectory.path,
        backupFileName,
      );

      if (session.isAdministrator) {
        // Solamente el administrador copia la base completa.
        return await databaseFile.copy(backupPath);
      }

      // El coordinador obtiene una base aislada que contiene
      // únicamente sus aspirantes y no las tablas privadas
      // de los demás usuarios.
      await _createCoordinatorBackup(
        sourceDatabase: sourceDatabase,
        backupPath: backupPath,
        userId: currentUser.id!,
      );

      return File(backupPath);
    } catch (error) {
      throw Exception('No fue posible crear la copia de seguridad: $error');
    }
  }

  // =============================================================
  // OBTENER HISTORIAL DE COPIAS
  // =============================================================

  Future<List<BackupModel>> getBackups() async {
    try {
      _ensureBackupPermission();

      final SessionManager session = SessionManager.instance;

      final Directory backupsDirectory = await _getBackupsDirectory();

      final List<FileSystemEntity> entities = await backupsDirectory
          .list()
          .toList();

      final List<BackupModel> backups = [];

      for (final FileSystemEntity entity in entities) {
        if (entity is! File) {
          continue;
        }

        final String fileName = path.basename(entity.path);

        if (!fileName.startsWith('backup_nancy_') ||
            path.extension(fileName).toLowerCase() != '.db') {
          continue;
        }

        final FileSystemEntityType entityType = await FileSystemEntity.type(
          entity.path,
          followLinks: false,
        );

        if (entityType != FileSystemEntityType.file) {
          continue;
        }

        if (session.isCoordinator) {
          final int? userId = session.currentUser?.id;

          if (userId == null ||
              !fileName.startsWith('backup_nancy_user_${userId}_')) {
            continue;
          }

          // No mostrar archivos antiguos que contengan la base
          // completa ni archivos que no sean copias aisladas.
          if (!await _isIsolatedCoordinatorBackup(entity)) {
            continue;
          }
        }

        backups.add(await BackupModel.fromFile(entity));
      }

      backups.sort(
        (BackupModel a, BackupModel b) => b.createdAt.compareTo(a.createdAt),
      );

      return backups;
    } catch (error) {
      throw Exception('No fue posible obtener el historial de copias: $error');
    }
  }

  // =============================================================
  // LEER ASPIRANTES DE UNA COPIA
  // =============================================================

  Future<List<BackupApplicantModel>> getBackupApplicants(
    String backupPath,
  ) async {
    Database? backupDatabase;

    try {
      final File backupFile = await _validateBackupFile(backupPath);

      backupDatabase = await openDatabase(backupFile.path, readOnly: true);

      final List<Map<String, Object?>> tables = await backupDatabase.rawQuery(
        '''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
          AND name = 'applicants'
        ''',
      );

      if (tables.isEmpty) {
        throw Exception(
          'La copia de seguridad no contiene la tabla de aspirantes.',
        );
      }

      final List<Map<String, Object?>> result = await backupDatabase.query(
        DatabaseConstants.applicantsTable,
        where:
            '''
          ${DatabaseConstants.isDeleted} IS NULL
          OR ${DatabaseConstants.isDeleted} = 0
        ''',
        orderBy: 'first_name ASC, last_name ASC',
      );

      return result
          .map((Map<String, Object?> map) => BackupApplicantModel.fromMap(map))
          .toList();
    } catch (error) {
      throw Exception('No fue posible leer la copia de seguridad: $error');
    } finally {
      await backupDatabase?.close();
    }
  }

  // =============================================================
  // CREAR ARCHIVO ZIP PARA COMPARTIR
  // =============================================================

  Future<File> createBackupZip(BackupModel backup) async {
    try {
      final File backupFile = await _validateBackupFile(backup.path);

      final List<int> bytes = await backupFile.readAsBytes();

      final Archive archive = Archive();

      final String safeBackupName = path.basename(backupFile.path);

      archive.addFile(ArchiveFile(safeBackupName, bytes.length, bytes));

      final String zipName = safeBackupName.replaceAll('.db', '.zip');

      final Directory backupsDirectory = await _getBackupsDirectory();

      final String zipPath = path.join(backupsDirectory.path, zipName);

      final ZipEncoder encoder = ZipEncoder();

      final List<int>? zipBytes = encoder.encode(archive);

      if (zipBytes == null) {
        throw Exception('No fue posible generar el archivo ZIP.');
      }

      final File zipFile = File(zipPath);

      await zipFile.writeAsBytes(zipBytes, flush: true);

      return zipFile;
    } catch (error) {
      throw Exception('No fue posible preparar la copia para enviar: $error');
    }
  }

  // =============================================================
  // ELIMINAR COPIA DE SEGURIDAD
  // =============================================================

  Future<void> deleteBackup(String backupPath) async {
    try {
      final File backupFile = await _validateBackupFile(backupPath);

      await backupFile.delete();
    } catch (error) {
      throw Exception('No fue posible eliminar la copia de seguridad: $error');
    }
  }
}
