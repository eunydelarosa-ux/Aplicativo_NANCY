// ===============================================================
// APLICATIVO NANCY
// Repositorio de administración de usuarios
// ===============================================================

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../../profile/models/user_profile_model.dart';
import '../../session/session_manager.dart';

class UserManagementRepository {
  UserManagementRepository();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final SessionManager _sessionManager = SessionManager.instance;

  static const String _tableName = 'user_profile';

  // =============================================================
  // PERMISOS
  // =============================================================

  int? get _currentUserId => _sessionManager.currentUser?.id;

  bool get _isAdministrator => _sessionManager.isAdministrator;

  bool get _isCoordinator => _sessionManager.isCoordinator;

  bool _canCreateRole(String role) {
    if (_isAdministrator) {
      return true;
    }

    if (_isCoordinator) {
      return role.trim().toLowerCase() == 'asesor';
    }

    return false;
  }

  bool _canManage(UserProfileModel user) {
    if (_currentUserId == null || user.id == null) {
      return false;
    }

    if (_isAdministrator) {
      return true;
    }

    if (_isCoordinator) {
      return user.role.trim().toLowerCase() == 'asesor' &&
          user.createdByUserId == _currentUserId;
    }

    return false;
  }

  // =============================================================
  // OBTENER TODOS LOS USUARIOS PERMITIDOS
  // =============================================================

  Future<List<UserProfileModel>> getUsers({bool onlyActive = false}) async {
    final Database db = await _databaseHelper.database;

    if (_isAdministrator) {
      final List<Map<String, dynamic>> result = await db.query(
        _tableName,
        where: onlyActive ? 'is_active = ?' : null,
        whereArgs: onlyActive ? [1] : null,
        orderBy: 'name COLLATE NOCASE ASC',
      );

      return result.map(UserProfileModel.fromMap).toList();
    }

    if (!_isCoordinator || _currentUserId == null) {
      return [];
    }

    String where = 'LOWER(role) = ? AND created_by_user_id = ?';

    final List<dynamic> whereArgs = ['asesor', _currentUserId];

    if (onlyActive) {
      where += ' AND is_active = ?';
      whereArgs.add(1);
    }

    final List<Map<String, dynamic>> result = await db.query(
      _tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result.map(UserProfileModel.fromMap).toList();
  }

  // =============================================================
  // OBTENER USUARIO POR ID
  // =============================================================

  Future<UserProfileModel?> getUserById(int id) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    final UserProfileModel user = UserProfileModel.fromMap(result.first);

    if (!_canManage(user)) {
      return null;
    }

    return user;
  }

  // =============================================================
  // OBTENER USUARIO POR NOMBRE DE USUARIO
  // =============================================================

  Future<UserProfileModel?> getUserByUsername(String username) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      _tableName,
      where: 'LOWER(username) = LOWER(?)',
      whereArgs: [username.trim()],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return UserProfileModel.fromMap(result.first);
  }

  // =============================================================
  // COMPROBAR SI EXISTE USERNAME
  // =============================================================

  Future<bool> usernameExists(String username, {int? excludeUserId}) async {
    final Database db = await _databaseHelper.database;

    String where = 'LOWER(username) = LOWER(?)';
    final List<dynamic> whereArgs = [username.trim()];

    if (excludeUserId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeUserId);
    }

    final List<Map<String, dynamic>> result = await db.query(
      _tableName,
      columns: ['id'],
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // =============================================================
  // CREAR USUARIO
  // =============================================================

  Future<int> insertUser(UserProfileModel user) async {
    if (_currentUserId == null) {
      throw StateError('No hay una sesión de usuario activa.');
    }

    if (!_canCreateRole(user.role)) {
      throw StateError('No tienes permiso para crear este tipo de usuario.');
    }

    final UserProfileModel userToSave = user.copyWith(
      createdByUserId: _currentUserId,
    );

    final Database db = await _databaseHelper.database;

    return db.insert(
      _tableName,
      userToSave.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // =============================================================
  // ACTUALIZAR USUARIO
  // =============================================================

  Future<int> updateUser(UserProfileModel user) async {
    if (user.id == null) {
      throw StateError('No se puede actualizar un usuario sin identificador.');
    }

    final UserProfileModel? existingUser =
        await _getUserByIdWithoutPermissionCheck(user.id!);

    if (existingUser == null || !_canManage(existingUser)) {
      throw StateError('No tienes permiso para editar este usuario.');
    }

    final String roleToSave = _isCoordinator ? existingUser.role : user.role;

    if (!_canCreateRole(roleToSave)) {
      throw StateError('No tienes permiso para asignar ese rol.');
    }

    final UserProfileModel userToSave = user.copyWith(
      role: roleToSave,
      createdByUserId: existingUser.createdByUserId,
    );

    final Database db = await _databaseHelper.database;

    return db.update(
      _tableName,
      userToSave.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // =============================================================
  // ACTIVAR / DESACTIVAR USUARIO
  // =============================================================

  Future<int> setUserActive(int userId, bool active) async {
    final UserProfileModel? targetUser =
        await _getUserByIdWithoutPermissionCheck(userId);

    if (targetUser == null || !_canManage(targetUser)) {
      throw StateError('No tienes permiso para modificar este usuario.');
    }

    if (!active && userId == _currentUserId) {
      throw StateError('No puedes desactivar tu propia cuenta.');
    }

    final Database db = await _databaseHelper.database;

    return db.update(
      _tableName,
      {
        'is_active': active ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // =============================================================
  // ELIMINAR USUARIO
  // =============================================================

  Future<int> deleteUser(int userId) async {
    if (userId == _currentUserId) {
      throw StateError('No puedes eliminar tu propia cuenta.');
    }

    final UserProfileModel? targetUser =
        await _getUserByIdWithoutPermissionCheck(userId);

    if (targetUser == null || !_canManage(targetUser)) {
      throw StateError('No tienes permiso para eliminar este usuario.');
    }

    final Database db = await _databaseHelper.database;

    // Registrar el nombre antes de eliminar la cuenta.
    // Esto permite distinguir una cuenta eliminada de un
    // nombre de usuario que nunca ha existido.
    final String username = targetUser.username.trim();

    if (username.isNotEmpty) {
      await db.insert('deleted_usernames', {
        'username': username,
        'deleted_at': DateTime.now().toIso8601String(),
      });
    }

    // Conservar el borrado físico de la cuenta.
    return db.delete(_tableName, where: 'id = ?', whereArgs: [userId]);
  }

  // =============================================================
  // CONSULTA INTERNA POR ID
  // No aplica permisos: solo se usa para validar operaciones.
  // =============================================================

  Future<UserProfileModel?> _getUserByIdWithoutPermissionCheck(int id) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return UserProfileModel.fromMap(result.first);
  }
}
