// =============================================================
// APLICATIVO NANCY
// Repository de Catálogos
// =============================================================

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../session/session_manager.dart';
import '../models/catalog_item_model.dart';

class CatalogRepository {
  // =============================================================
  // BASE DE DATOS
  // =============================================================

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // =============================================================
  // TABLAS
  // =============================================================

  static const String _tableName = 'catalog_items';

  static const String _userTableName = DatabaseConstants.userCatalogItemsTable;

  static const String _userStateTableName =
      DatabaseConstants.userCatalogStateTable;

  // =============================================================
  // COLUMNAS
  // =============================================================

  static const String _idColumn = 'id';
  static const String _typeColumn = 'catalog_type';
  static const String _nameColumn = 'name';
  static const String _parentIdColumn = 'parent_id';
  static const String _activeColumn = 'active';
  static const String _createdAtColumn = 'created_at';
  static const String _updatedAtColumn = 'updated_at';

  static const String _userIdColumn = DatabaseConstants.userCatalogUserId;

  static const String _sourceIdColumn = DatabaseConstants.userCatalogSourceId;

  // =============================================================
  // OBTENER EL USUARIO ACTUAL
  // =============================================================

  int _requireCurrentUserId() {
    final int? userId = SessionManager.instance.currentUser?.id;

    if (userId == null || userId <= 0) {
      throw StateError(
        'No hay una sesión válida para acceder a los catálogos.',
      );
    }

    return userId;
  }

  // =============================================================
  // PREPARAR EL CATÁLOGO PERSONAL DEL USUARIO
  // =============================================================

  Future<void> _ensureUserCatalogInitialized(Database db, int userId) async {
    await db.transaction((Transaction transaction) async {
      // Comprobar si este usuario ya tiene su catálogo inicializado.
      final List<Map<String, dynamic>> states = await transaction.query(
        _userStateTableName,
        where: '$_userIdColumn = ?',
        whereArgs: [userId],
        limit: 1,
      );

      // Si ya existe el registro, no volver a copiar la base general.
      if (states.isNotEmpty) {
        return;
      }

      // Obtener todos los elementos del catálogo general.
      final List<Map<String, dynamic>> sourceRows = await transaction.query(
        _tableName,
        orderBy: '$_idColumn ASC',
      );

      final Map<int, int> idMap = <int, int>{};
      final String now = DateTime.now().toIso8601String();

      // -----------------------------------------------------------
      // COPIAR ELEMENTOS A LA TABLA PERSONAL
      // -----------------------------------------------------------

      for (final Map<String, dynamic> source in sourceRows) {
        final dynamic rawSourceId = source[_idColumn];

        if (rawSourceId is! num) {
          continue;
        }

        final int sourceId = rawSourceId.toInt();

        final dynamic rawActive = source[_activeColumn];

        final int activeValue = rawActive is num ? rawActive.toInt() : 1;

        final int newId = await transaction.insert(_userTableName, {
          _userIdColumn: userId,
          _sourceIdColumn: sourceId,
          _typeColumn: source[_typeColumn]?.toString() ?? '',
          _nameColumn: source[_nameColumn]?.toString() ?? '',
          // Los vínculos se ajustan después de copiar todos los datos.
          _parentIdColumn: 0,
          _activeColumn: activeValue,
          _createdAtColumn: source[_createdAtColumn]?.toString() ?? now,
          _updatedAtColumn: source[_updatedAtColumn]?.toString() ?? now,
        }, conflictAlgorithm: ConflictAlgorithm.abort);

        // Relacionar el ID original con el ID personal nuevo.
        idMap[sourceId] = newId;
      }

      // -----------------------------------------------------------
      // RECONSTRUIR LAS RELACIONES ENTRE ELEMENTOS
      // -----------------------------------------------------------

      for (final Map<String, dynamic> source in sourceRows) {
        final dynamic rawSourceId = source[_idColumn];

        if (rawSourceId is! num) {
          continue;
        }

        final int sourceId = rawSourceId.toInt();
        final int? personalId = idMap[sourceId];

        if (personalId == null) {
          continue;
        }

        final dynamic rawParentId = source[_parentIdColumn];

        final int originalParentId = rawParentId is num
            ? rawParentId.toInt()
            : int.tryParse('$rawParentId') ?? 0;

        // Vincular únicamente con elementos copiados al mismo usuario.
        final int personalParentId = idMap[originalParentId] ?? 0;

        await transaction.update(
          _userTableName,
          {_parentIdColumn: personalParentId},
          where: '$_idColumn = ? AND $_userIdColumn = ?',
          whereArgs: [personalId, userId],
        );
      }

      // -----------------------------------------------------------
      // MARCAR LA INICIALIZACIÓN COMO COMPLETADA
      // -----------------------------------------------------------

      await transaction.insert(_userStateTableName, {
        _userIdColumn: userId,
        DatabaseConstants.userCatalogInitializedAt: now,
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    });
  }

  // =============================================================
  // OBTENER TODOS LOS ELEMENTOS DEL USUARIO
  // =============================================================

  Future<List<CatalogItemModel>> getAll() async {
    final Database db = await _databaseHelper.database;
    final int userId = _requireCurrentUserId();

    await _ensureUserCatalogInitialized(db, userId);

    final List<Map<String, dynamic>> rows = await db.query(
      _userTableName,
      where: '$_userIdColumn = ?',
      whereArgs: [userId],
      orderBy: '$_nameColumn ASC',
    );

    return rows
        .map((Map<String, dynamic> row) => CatalogItemModel.fromMap(row))
        .toList();
  }

  // =============================================================
  // OBTENER ELEMENTOS ACTIVOS POR TIPO
  // =============================================================

  Future<List<CatalogItemModel>> getByType(String catalogType) async {
    final String cleanCatalogType = catalogType.trim();

    if (cleanCatalogType.isEmpty) {
      return <CatalogItemModel>[];
    }

    final Database db = await _databaseHelper.database;
    final int userId = _requireCurrentUserId();

    await _ensureUserCatalogInitialized(db, userId);

    final List<Map<String, dynamic>> rows = await db.query(
      _userTableName,
      where:
          '$_userIdColumn = ? '
          'AND $_typeColumn = ? '
          'AND $_activeColumn = ?',
      whereArgs: [userId, cleanCatalogType, 1],
      orderBy: '$_nameColumn ASC',
    );

    return rows
        .map((Map<String, dynamic> row) => CatalogItemModel.fromMap(row))
        .toList();
  }

  // =============================================================
  // OBTENER POR ID DEL CATÁLOGO PERSONAL
  // =============================================================

  Future<CatalogItemModel?> getById(int id) async {
    if (id <= 0) {
      return null;
    }

    final Database db = await _databaseHelper.database;
    final int userId = _requireCurrentUserId();

    await _ensureUserCatalogInitialized(db, userId);

    final List<Map<String, dynamic>> rows = await db.query(
      _userTableName,
      where: '$_idColumn = ? AND $_userIdColumn = ?',
      whereArgs: [id, userId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return CatalogItemModel.fromMap(rows.first);
  }

  // =============================================================
  // INSERTAR EN EL CATÁLOGO PERSONAL
  // =============================================================

  Future<int> insert(CatalogItemModel item) async {
    final String catalogType = item.catalogType.trim();
    final String name = item.name.trim();

    if (catalogType.isEmpty) {
      throw ArgumentError('El tipo de catálogo no puede estar vacío.');
    }

    if (name.isEmpty) {
      throw ArgumentError('El nombre del catálogo no puede estar vacío.');
    }

    final Database db = await _databaseHelper.database;
    final int userId = _requireCurrentUserId();

    await _ensureUserCatalogInitialized(db, userId);

    final Map<String, dynamic> data = {
      _userIdColumn: userId,

      // Los elementos nuevos no proceden del catálogo general.
      _sourceIdColumn: null,

      _typeColumn: catalogType,
      _nameColumn: name,
      _parentIdColumn: item.parentId,
      _activeColumn: item.active ? 1 : 0,
      _createdAtColumn: item.createdAt,
      _updatedAtColumn: item.updatedAt,
    };

    final int insertedId = await db.insert(
      _userTableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    if (insertedId <= 0) {
      throw StateError(
        'SQLite no devolvió un ID válido después de insertar '
        'el catálogo.',
      );
    }

    return insertedId;
  }

  // =============================================================
  // ACTUALIZAR UN ELEMENTO PROPIO
  // =============================================================

  Future<int> update(CatalogItemModel item) async {
    final int? id = item.id;

    if (id == null || id <= 0) {
      throw ArgumentError(
        'No se puede actualizar un catálogo sin un ID válido.',
      );
    }

    final String catalogType = item.catalogType.trim();
    final String name = item.name.trim();

    if (catalogType.isEmpty) {
      throw ArgumentError('El tipo de catálogo no puede estar vacío.');
    }

    if (name.isEmpty) {
      throw ArgumentError('El nombre del catálogo no puede estar vacío.');
    }

    final Database db = await _databaseHelper.database;
    final int userId = _requireCurrentUserId();

    await _ensureUserCatalogInitialized(db, userId);

    final Map<String, dynamic> data = {
      _typeColumn: catalogType,
      _nameColumn: name,
      _parentIdColumn: item.parentId,
      _activeColumn: item.active ? 1 : 0,
      _updatedAtColumn: item.updatedAt,
    };

    final int affectedRows = await db.update(
      _userTableName,
      data,
      where: '$_idColumn = ? AND $_userIdColumn = ?',
      whereArgs: [id, userId],
    );

    if (affectedRows == 0) {
      throw StateError(
        'No se encontró el catálogo $id para el usuario actual.',
      );
    }

    return affectedRows;
  }

  // =============================================================
  // ELIMINAR UN ELEMENTO PROPIO
  // =============================================================

  Future<int> delete(int id) async {
    if (id <= 0) {
      throw ArgumentError(
        'No se puede eliminar un catálogo con un ID inválido.',
      );
    }

    final Database db = await _databaseHelper.database;
    final int userId = _requireCurrentUserId();

    await _ensureUserCatalogInitialized(db, userId);

    return db.delete(
      _userTableName,
      where: '$_idColumn = ? AND $_userIdColumn = ?',
      whereArgs: [id, userId],
    );
  }

  // =============================================================
  // DESACTIVAR UN ELEMENTO PROPIO
  // =============================================================

  Future<int> deactivate(int id) async {
    if (id <= 0) {
      throw ArgumentError(
        'No se puede desactivar un catálogo con un ID inválido.',
      );
    }

    final Database db = await _databaseHelper.database;
    final int userId = _requireCurrentUserId();

    await _ensureUserCatalogInitialized(db, userId);

    return db.update(
      _userTableName,
      {_activeColumn: 0, _updatedAtColumn: DateTime.now().toIso8601String()},
      where: '$_idColumn = ? AND $_userIdColumn = ?',
      whereArgs: [id, userId],
    );
  }

  // =============================================================
  // ACTIVAR UN ELEMENTO PROPIO
  // =============================================================

  Future<int> activate(int id) async {
    if (id <= 0) {
      throw ArgumentError(
        'No se puede activar un catálogo con un ID inválido.',
      );
    }

    final Database db = await _databaseHelper.database;
    final int userId = _requireCurrentUserId();

    await _ensureUserCatalogInitialized(db, userId);

    return db.update(
      _userTableName,
      {_activeColumn: 1, _updatedAtColumn: DateTime.now().toIso8601String()},
      where: '$_idColumn = ? AND $_userIdColumn = ?',
      whereArgs: [id, userId],
    );
  }

  // =============================================================
  // COMPROBAR SI EXISTE EN EL CATÁLOGO DEL USUARIO
  // =============================================================

  Future<bool> exists({
    required String catalogType,
    required String name,
  }) async {
    final String cleanCatalogType = catalogType.trim();
    final String cleanName = name.trim();

    if (cleanCatalogType.isEmpty || cleanName.isEmpty) {
      return false;
    }

    final Database db = await _databaseHelper.database;
    final int userId = _requireCurrentUserId();

    await _ensureUserCatalogInitialized(db, userId);

    final List<Map<String, dynamic>> rows = await db.query(
      _userTableName,
      columns: [_idColumn],
      where:
          '$_userIdColumn = ? '
          'AND $_typeColumn = ? '
          'AND LOWER($_nameColumn) = LOWER(?)',
      whereArgs: [userId, cleanCatalogType, cleanName],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  // =============================================================
  // ELIMINAR TODOS LOS ELEMENTOS DE UN TIPO PROPIO
  // =============================================================

  Future<int> deleteByType(String catalogType) async {
    final String cleanCatalogType = catalogType.trim();

    if (cleanCatalogType.isEmpty) {
      return 0;
    }

    final Database db = await _databaseHelper.database;
    final int userId = _requireCurrentUserId();

    await _ensureUserCatalogInitialized(db, userId);

    return db.delete(
      _userTableName,
      where: '$_typeColumn = ? AND $_userIdColumn = ?',
      whereArgs: [cleanCatalogType, userId],
    );
  }
}
