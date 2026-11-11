// ===============================================================
// APLICATIVO NANCY
// Repositorio de Aspirantes
// ===============================================================

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../session/session_manager.dart';
import '../models/applicant_model.dart';

class ApplicantRepository {
  ApplicantRepository();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // =============================================================
  // CONTROL CENTRALIZADO DE ACCESO A ASPIRANTES LOCALES
  // =============================================================

  _ApplicantQueryScope? _buildApplicantScope({
    required String where,
    required List<dynamic> whereArgs,
  }) {
    final SessionManager session = SessionManager.instance;

    final int? currentUserId = session.currentUser?.id;

    // Sin usuario identificado, no se permite acceder.
    if (currentUserId == null) {
      return null;
    }

    // El administrador puede consultar todos los registros locales.
    if (session.isAdministrator) {
      return _ApplicantQueryScope(
        where: where,
        whereArgs: List<dynamic>.from(whereArgs),
      );
    }

    // Coordinadores y asesores solo acceden a sus propios registros.
    if (session.isCoordinator || session.isAdviser) {
      return _ApplicantQueryScope(
        where:
            '($where) AND '
            '${DatabaseConstants.applicantCreatedByUserId} = ?',
        whereArgs: <dynamic>[...whereArgs, currentUserId],
      );
    }

    // Cualquier otro rol queda sin acceso por defecto.
    return null;
  }

  // ===============================================================
  // VERIFICAR SI YA EXISTE UNA INSCRIPCIÓN
  // ===============================================================

  Future<bool> existsApplicantRegistration({
    required String documentType,
    required String documentNumber,
    required String program,
    String? excludeApplicantId,
  }) async {
    final SessionManager session = SessionManager.instance;
    final int? currentUserId = session.currentUser?.id;

    // Solo los usuarios autorizados pueden ejecutar esta validación.
    if (currentUserId == null ||
        (!session.isAdministrator &&
            !session.isCoordinator &&
            !session.isAdviser)) {
      return false;
    }

    final Database db = await _databaseHelper.database;

    // Se comprueban todos los aspirantes activos del dispositivo.
    // Solo se devuelve si existe coincidencia, nunca sus datos personales.
    String where =
        '${DatabaseConstants.documentType} = ? AND '
        '${DatabaseConstants.documentNumber} = ? AND '
        '${DatabaseConstants.program} = ? AND '
        '${DatabaseConstants.isDeleted} = ?';

    final List<dynamic> whereArgs = [
      documentType.trim(),
      documentNumber.trim(),
      program.trim(),
      0,
    ];

    // Al editar, se excluye el mismo aspirante de la validación.
    if (excludeApplicantId != null && excludeApplicantId.trim().isNotEmpty) {
      where += ' AND ${DatabaseConstants.id} != ?';
      whereArgs.add(excludeApplicantId);
    }

    final List<Map<String, dynamic>> result = await db.query(
      DatabaseConstants.applicantsTable,
      columns: [DatabaseConstants.id],
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    return result.isNotEmpty;
  }
  // ===============================================================
  // INSERTAR ASPIRANTE
  // ===============================================================

  Future<int> insertApplicant(ApplicantModel applicant) async {
    final SessionManager session = SessionManager.instance;
    final currentUser = session.currentUser;

    if (currentUser == null ||
        currentUser.id == null ||
        (!session.isAdministrator &&
            !session.isCoordinator &&
            !session.isAdviser)) {
      throw StateError(
        'No hay una sesión autorizada para registrar aspirantes.',
      );
    }

    final Database db = await _databaseHelper.database;

    final Map<String, dynamic> values = applicant.toMap();

    // La identidad se obtiene de la sesión autenticada.
    values[DatabaseConstants.applicantCreatedByUserId] = currentUser.id;

    values[DatabaseConstants.applicantSiteId] = currentUser.siteId;

    return await db.insert(
      DatabaseConstants.applicantsTable,
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }
  // ===============================================================
  // OBTENER TODOS LOS ASPIRANTES ACTIVOS
  // ===============================================================

  // ===============================================================
  // OBTENER TODOS LOS ASPIRANTES ACTIVOS
  // ===============================================================

  Future<List<ApplicantModel>> getAllApplicants() async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where: '${DatabaseConstants.isDeleted} = ?',
      whereArgs: [0],
    );

    if (scope == null) {
      return [];
    }

    final List<Map<String, dynamic>> result = await db.query(
      DatabaseConstants.applicantsTable,
      where: scope.where,
      whereArgs: scope.whereArgs,
      orderBy: '${DatabaseConstants.createdAt} DESC',
    );

    return result.map((item) => ApplicantModel.fromMap(item)).toList();
  }
  // ===============================================================
  // OBTENER ASPIRANTE ACTIVO POR ID
  // ===============================================================

  Future<ApplicantModel?> getApplicantById(String id) async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where:
          '${DatabaseConstants.id} = ? AND '
          '${DatabaseConstants.isDeleted} = ?',
      whereArgs: [id, 0],
    );

    if (scope == null) {
      return null;
    }

    final List<Map<String, dynamic>> result = await db.query(
      DatabaseConstants.applicantsTable,
      where: scope.where,
      whereArgs: scope.whereArgs,
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return ApplicantModel.fromMap(result.first);
  }

  // ===============================================================
  // ACTUALIZAR ASPIRANTE ACTIVO
  // ===============================================================

  Future<int> updateApplicant(ApplicantModel applicant) async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where:
          '${DatabaseConstants.id} = ? AND '
          '${DatabaseConstants.isDeleted} = ?',
      whereArgs: [applicant.id, 0],
    );

    if (scope == null) {
      return 0;
    }

    // Comprobamos que el aspirante pertenezca al alcance autorizado.
    final List<Map<String, dynamic>> existing = await db.query(
      DatabaseConstants.applicantsTable,
      where: scope.where,
      whereArgs: scope.whereArgs,
      limit: 1,
    );

    if (existing.isEmpty) {
      return 0;
    }

    final Map<String, dynamic> values = applicant.toMap();

    // El creador y la sede originales no se cambian al editar.
    values[DatabaseConstants.applicantCreatedByUserId] =
        existing.first[DatabaseConstants.applicantCreatedByUserId];

    values[DatabaseConstants.applicantSiteId] =
        existing.first[DatabaseConstants.applicantSiteId];

    return await db.update(
      DatabaseConstants.applicantsTable,
      values,
      where: scope.where,
      whereArgs: scope.whereArgs,
    );
  }
  // ===============================================================
  // OBTENER ASPIRANTES PENDIENTES DE SINCRONIZACIÓN
  // ===============================================================

  Future<List<ApplicantModel>> getPendingSyncApplicants() async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where:
          '${DatabaseConstants.isDeleted} = ? AND '
          'LOWER(${DatabaseConstants.syncStatus}) IN (?, ?)',
      whereArgs: [0, 'pendiente', 'error'],
    );

    if (scope == null) {
      return [];
    }

    final List<Map<String, dynamic>> result = await db.query(
      DatabaseConstants.applicantsTable,
      where: scope.where,
      whereArgs: scope.whereArgs,
      orderBy: '${DatabaseConstants.createdAt} ASC',
    );

    return result.map((item) => ApplicantModel.fromMap(item)).toList();
  }

  // ===============================================================
  // MARCAR ASPIRANTE COMO SINCRONIZANDO
  // ===============================================================
  // ===============================================================
  // MARCAR ASPIRANTE COMO SINCRONIZANDO
  // ===============================================================

  Future<int> markApplicantSyncing(String id) async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where:
          '${DatabaseConstants.id} = ? AND '
          '${DatabaseConstants.isDeleted} = ?',
      whereArgs: [id, 0],
    );

    if (scope == null) {
      return 0;
    }

    final DateTime now = DateTime.now();

    return await db.rawUpdate(
      '''
      UPDATE ${DatabaseConstants.applicantsTable}
      SET
        ${DatabaseConstants.syncStatus} = ?,
        ${DatabaseConstants.syncAttempts} =
            COALESCE(${DatabaseConstants.syncAttempts}, 0) + 1,
        ${DatabaseConstants.lastSyncAttempt} = ?,
        ${DatabaseConstants.lastSyncError} = NULL
      WHERE ${scope.where}
      ''',
      ['sincronizando', now.toIso8601String(), ...scope.whereArgs],
    );
  }
  // ===============================================================
  // MARCAR ASPIRANTE COMO SINCRONIZADO
  // ===============================================================

  Future<int> markApplicantSynced(String id) async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where:
          '${DatabaseConstants.id} = ? AND '
          '${DatabaseConstants.isDeleted} = ?',
      whereArgs: [id, 0],
    );

    if (scope == null) {
      throw StateError(
        'No hay una sesión autorizada para completar la sincronización.',
      );
    }

    final DateTime now = DateTime.now();

    return await db.transaction<int>((txn) async {
      // Buscar el aspirante dentro del alcance autorizado.
      final List<Map<String, dynamic>> result = await txn.query(
        DatabaseConstants.applicantsTable,
        where: scope.where,
        whereArgs: scope.whereArgs,
        limit: 1,
      );

      if (result.isEmpty) {
        throw StateError(
          'No se encontró el aspirante autorizado para completar '
          'la sincronización.',
        );
      }

      final Map<String, dynamic> applicant = result.first;

      final int attempts =
          int.tryParse(
            applicant[DatabaseConstants.syncAttempts]?.toString() ?? '0',
          ) ??
          0;

      // Guardar solamente el historial técnico de sincronización.
      // La identidad se toma del aspirante autorizado que se consultó.
      await txn.insert(DatabaseConstants.syncHistoryTable, <String, dynamic>{
        DatabaseConstants.historyApplicantId: id,
        DatabaseConstants.historyStatus: 'sincronizado',
        DatabaseConstants.historySyncedAt: now.toIso8601String(),
        DatabaseConstants.historyAttempts: attempts,
        DatabaseConstants.historyMessage: null,
        DatabaseConstants.historyCreatedByUserId:
            applicant[DatabaseConstants.applicantCreatedByUserId],
        DatabaseConstants.historySiteId:
            applicant[DatabaseConstants.applicantSiteId],
      });

      // Eliminar únicamente el registro que se comprobó
      // y que sigue dentro del alcance autorizado.
      final int deletedRows = await txn.delete(
        DatabaseConstants.applicantsTable,
        where: scope.where,
        whereArgs: scope.whereArgs,
      );

      if (deletedRows != 1) {
        throw StateError(
          'No fue posible eliminar el aspirante después de guardar '
          'el historial de sincronización.',
        );
      }

      return deletedRows;
    });
  }
  // ===============================================================
  // REGISTRAR ERROR DE SINCRONIZACIÓN
  // ===============================================================

  // ===============================================================
  // REGISTRAR ERROR DE SINCRONIZACIÓN
  // ===============================================================

  Future<int> markApplicantSyncError(String id, String errorMessage) async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where:
          '${DatabaseConstants.id} = ? AND '
          '${DatabaseConstants.isDeleted} = ?',
      whereArgs: [id, 0],
    );

    if (scope == null) {
      return 0;
    }

    return await db.update(
      DatabaseConstants.applicantsTable,
      <String, dynamic>{
        DatabaseConstants.syncStatus: 'error',
        DatabaseConstants.lastSyncError: errorMessage.trim(),
      },
      where: scope.where,
      whereArgs: scope.whereArgs,
    );
  }

  // ===============================================================
  // OBTENER HISTORIAL DE SINCRONIZACIÓN
  // ===============================================================

  Future<List<Map<String, dynamic>>> getSyncHistory() async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? historyScope = _buildApplicantScope(
      where: '1 = 1',
      whereArgs: <dynamic>[],
    );

    if (historyScope == null) {
      return [];
    }

    final DateTime expirationDate = DateTime.now().subtract(
      const Duration(days: 30),
    );

    final _ApplicantQueryScope? expirationScope = _buildApplicantScope(
      where: '${DatabaseConstants.historySyncedAt} < ?',
      whereArgs: [expirationDate.toIso8601String()],
    );

    if (expirationScope != null) {
      await db.delete(
        DatabaseConstants.syncHistoryTable,
        where: expirationScope.where,
        whereArgs: expirationScope.whereArgs,
      );
    }

    return await db.query(
      DatabaseConstants.syncHistoryTable,
      where: historyScope.where,
      whereArgs: historyScope.whereArgs,
      orderBy: '${DatabaseConstants.historySyncedAt} DESC',
    );
  }
  // ===============================================================
  // ELIMINAR REGISTRO DEL HISTORIAL
  // ===============================================================

  Future<int> deleteSyncHistory(int id) async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where: '${DatabaseConstants.historyId} = ?',
      whereArgs: [id],
    );

    if (scope == null) {
      return 0;
    }

    return await db.delete(
      DatabaseConstants.syncHistoryTable,
      where: scope.where,
      whereArgs: scope.whereArgs,
    );
  }
  // ===============================================================
  // VACIAR HISTORIAL
  // ===============================================================

  Future<int> clearSyncHistory() async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where: '1 = 1',
      whereArgs: <dynamic>[],
    );

    if (scope == null) {
      return 0;
    }

    return await db.delete(
      DatabaseConstants.syncHistoryTable,
      where: scope.where,
      whereArgs: scope.whereArgs,
    );
  }

  // ===============================================================
  // MOVER A PAPELERA
  // ===============================================================

  Future<int> moveToTrash(String id) async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where:
          '${DatabaseConstants.id} = ? AND '
          '${DatabaseConstants.isDeleted} = ?',
      whereArgs: [id, 0],
    );

    if (scope == null) {
      return 0;
    }

    final DateTime now = DateTime.now();

    return await db.update(
      DatabaseConstants.applicantsTable,
      <String, dynamic>{
        DatabaseConstants.isDeleted: 1,
        DatabaseConstants.deletedAt: now.toIso8601String(),
        DatabaseConstants.updatedAt: now.toIso8601String(),
      },
      where: scope.where,
      whereArgs: scope.whereArgs,
    );
  }

  // ===============================================================
  // ELIMINAR ASPIRANTE
  // ===============================================================

  Future<int> deleteApplicant(String id) async {
    return moveToTrash(id);
  }

  // ===============================================================
  // OBTENER ASPIRANTES DE LA PAPELERA
  // ===============================================================

  // ===============================================================
  // OBTENER ASPIRANTES DE LA PAPELERA
  // ===============================================================

  Future<List<ApplicantModel>> getDeletedApplicants() async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where: '${DatabaseConstants.isDeleted} = ?',
      whereArgs: [1],
    );

    if (scope == null) {
      return [];
    }

    final List<Map<String, dynamic>> result = await db.query(
      DatabaseConstants.applicantsTable,
      where: scope.where,
      whereArgs: scope.whereArgs,
      orderBy: '${DatabaseConstants.deletedAt} DESC',
    );

    return result.map((item) => ApplicantModel.fromMap(item)).toList();
  }

  // ===============================================================
  // CONTAR ELEMENTOS DE LA PAPELERA
  // ===============================================================

  Future<int> countDeletedApplicants() async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where: '${DatabaseConstants.isDeleted} = ?',
      whereArgs: [1],
    );

    if (scope == null) {
      return 0;
    }

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT COUNT(*)
      FROM ${DatabaseConstants.applicantsTable}
      WHERE ${scope.where}
      ''', scope.whereArgs);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ===============================================================
  // RESTAURAR ASPIRANTE
  // ===============================================================

  Future<int> restoreApplicant(String id) async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where:
          '${DatabaseConstants.id} = ? AND '
          '${DatabaseConstants.isDeleted} = ?',
      whereArgs: [id, 1],
    );

    if (scope == null) {
      return 0;
    }

    final DateTime now = DateTime.now();

    return await db.update(
      DatabaseConstants.applicantsTable,
      <String, dynamic>{
        DatabaseConstants.isDeleted: 0,
        DatabaseConstants.deletedAt: null,
        DatabaseConstants.updatedAt: now.toIso8601String(),
      },
      where: scope.where,
      whereArgs: scope.whereArgs,
    );
  }

  // ===============================================================
  // ELIMINAR DEFINITIVAMENTE
  // ===============================================================

  Future<int> deleteApplicantPermanently(String id) async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where:
          '${DatabaseConstants.id} = ? AND '
          '${DatabaseConstants.isDeleted} = ?',
      whereArgs: [id, 1],
    );

    if (scope == null) {
      return 0;
    }

    return await db.delete(
      DatabaseConstants.applicantsTable,
      where: scope.where,
      whereArgs: scope.whereArgs,
    );
  }

  // ===============================================================
  // VACIAR PAPELERA
  // ===============================================================

  Future<int> emptyTrash() async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where: '${DatabaseConstants.isDeleted} = ?',
      whereArgs: [1],
    );

    if (scope == null) {
      return 0;
    }

    return await db.delete(
      DatabaseConstants.applicantsTable,
      where: scope.where,
      whereArgs: scope.whereArgs,
    );
  }

  // ===============================================================
  // CONTAR ASPIRANTES ACTIVOS
  // ===============================================================

  Future<int> countApplicants() async {
    final Database db = await _databaseHelper.database;

    final _ApplicantQueryScope? scope = _buildApplicantScope(
      where: '${DatabaseConstants.isDeleted} = ?',
      whereArgs: [0],
    );

    if (scope == null) {
      return 0;
    }

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT COUNT(*)
      FROM ${DatabaseConstants.applicantsTable}
      WHERE ${scope.where}
      ''', scope.whereArgs);

    return Sqflite.firstIntValue(result) ?? 0;
  }
}

// ===============================================================
// ALCANCE DE CONSULTA AUTORIZADO
// ===============================================================

class _ApplicantQueryScope {
  const _ApplicantQueryScope({required this.where, required this.whereArgs});

  final String where;

  final List<dynamic> whereArgs;
}
