// ===============================================================
// APLICATIVO NANCY
// Repositorio del perfil del usuario
// ===============================================================

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../models/user_profile_model.dart';
import '../../session/session_manager.dart';

class UserProfileRepository {
  UserProfileRepository();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // =============================================================
  // NOMBRE DE LA TABLA
  // =============================================================

  static const String _tableName = 'user_profile';

  // =============================================================
  // OBTENER PERFIL
  // =============================================================
  Future<UserProfileModel?> getProfile() async {
    final int? currentUserId = SessionManager.instance.currentUser?.id;

    if (currentUserId == null) {
      return null;
    }

    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      _tableName,
      where: 'id = ? AND is_active = ?',
      whereArgs: [currentUserId, 1],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return UserProfileModel.fromMap(result.first);
  }

  // =============================================================
  // OBTENER PERFIL POR USUARIO
  // =============================================================

  Future<UserProfileModel?> getProfileByUsername(String username) async {
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
  // CREAR PERFIL
  // =============================================================

  Future<int> insertProfile(UserProfileModel profile) async {
    final Database db = await _databaseHelper.database;

    return await db.insert(
      _tableName,
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // =============================================================
  // ACTUALIZAR PERFIL
  // =============================================================

  Future<int> updateProfile(UserProfileModel profile) async {
    final Database db = await _databaseHelper.database;

    if (profile.id == null) {
      return await insertProfile(profile);
    }

    return await db.update(
      _tableName,
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  // =============================================================
  // GUARDAR O ACTUALIZAR
  // =============================================================

  Future<int> saveProfile(UserProfileModel profile) async {
    final int? currentUserId = SessionManager.instance.currentUser?.id;

    if (currentUserId == null) {
      throw StateError('No hay una sesión de usuario activa.');
    }

    if (profile.id != null && profile.id != currentUserId) {
      throw StateError('No puedes modificar el perfil de otro usuario.');
    }

    final UserProfileModel? existingProfile = await getProfile();

    if (existingProfile == null) {
      throw StateError(
        'No se encontró el perfil del usuario que inició sesión.',
      );
    }

    final UserProfileModel updatedProfile = profile.copyWith(
      id: currentUserId,
      createdAt: existingProfile.createdAt,
      createdByUserId: existingProfile.createdByUserId,
    );

    return updateProfile(updatedProfile);
  }

  // =============================================================
  // ESTABLECER CONTRASEÑA PERSONAL
  // =============================================================

  Future<int> setPersonalPassword({required String passwordHash}) async {
    final int? currentUserId = SessionManager.instance.currentUser?.id;

    if (currentUserId == null) {
      throw StateError('No hay una sesión de usuario activa.');
    }

    final Database db = await _databaseHelper.database;

    final int updatedRows = await db.update(
      _tableName,
      {
        'password_hash': passwordHash,
        'activation_code_hash': null,
        'must_change_password': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [currentUserId],
    );

    if (updatedRows == 0) {
      throw StateError(
        'No se encontró el perfil del usuario que inició sesión.',
      );
    }

    return updatedRows;
  }

  // =============================================================
  // GUARDAR O QUITAR FOTO DEL PERFIL
  // =============================================================

  Future<int> updateProfileImage({String? imagePath}) async {
    final int? currentUserId = SessionManager.instance.currentUser?.id;

    if (currentUserId == null) {
      throw StateError('No hay una sesión de usuario activa.');
    }

    final Database db = await _databaseHelper.database;

    final int updatedRows = await db.update(
      _tableName,
      {'image_path': imagePath, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ? AND is_active = ?',
      whereArgs: [currentUserId, 1],
    );

    if (updatedRows == 0) {
      throw StateError(
        'No se encontró el perfil del usuario que inició sesión.',
      );
    }

    return updatedRows;
  }

  // =============================================================
  // ELIMINAR PERFIL
  // =============================================================

  Future<int> deleteProfile() async {
    final Database db = await _databaseHelper.database;

    return await db.delete(_tableName);
  }
}
