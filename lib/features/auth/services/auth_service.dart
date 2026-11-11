// ===============================================================
// APLICATIVO NANCY
// Servicio de autenticación
// ===============================================================

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'package:nancy_app/features/configuration/providers/appearance_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../profile/models/user_profile_model.dart';
import '../../profile/repositories/user_profile_repository.dart';
import '../../session/session_manager.dart';
import '../../../core/database/database_helper.dart';

class AuthService {
  AuthService({
    UserProfileRepository? repository,
    SessionManager? sessionManager,
  }) : _repository = repository ?? UserProfileRepository(),
       _sessionManager = sessionManager ?? SessionManager.instance;

  final UserProfileRepository _repository;

  final SessionManager _sessionManager;

  // =============================================================
  // INICIAR SESIÓN
  // =============================================================

  Future<UserProfileModel?> login({
    required String username,
    required String password,
  }) async {
    final String normalizedUsername = username.trim();

    if (normalizedUsername.isEmpty || password.isEmpty) {
      return null;
    }

    final UserProfileModel? profile = await _repository.getProfileByUsername(
      normalizedUsername,
    );

    if (profile == null) {
      final Database db = await DatabaseHelper.instance.database;

      final List<Map<String, dynamic>> deletedUsers = await db.query(
        'deleted_usernames',
        columns: ['id'],
        where: 'username = ? COLLATE NOCASE',
        whereArgs: [normalizedUsername],
        limit: 1,
      );

      debugPrint('USUARIO INGRESADO: [$normalizedUsername]');
      debugPrint('REGISTROS ELIMINADOS ENCONTRADOS: ${deletedUsers.length}');

      if (deletedUsers.isNotEmpty) {
        throw Exception(
          'Tu cuenta fue eliminada. '
          'Comunícate con el administrador para que te cree '
          'o habilite una cuenta nueva.',
        );
      }

      throw Exception('Usuario o contraseña incorrectos.');
    }

    if (!profile.isActive) {
      throw Exception(
        'Tu cuenta está desactivada. '
        'Comunícate con el administrador para reactivarla.',
      );
    }

    final bool isAdministrator =
        profile.role.trim().toLowerCase() == 'administrador';

    if (profile.mustChangePassword && !isAdministrator) {
      throw Exception(
        'Debes utilizar tu código de activación para crear '
        'una nueva contraseña personal.',
      );
    }

    final String passwordHash = _hashPassword(password);

    if (passwordHash != profile.passwordHash) {
      throw Exception('Usuario o contraseña incorrectos.');
    }

    await _sessionManager.startSession(profile);

await AppearanceProvider.instance.loadAppearance();

return profile;
  }

  // =============================================================
  // INICIAR SESIÓN CON CÓDIGO DE ACTIVACIÓN
  // =============================================================

  Future<UserProfileModel?> loginWithActivationCode({
    required String username,
    required String activationCode,
  }) async {
    final String normalizedUsername = username.trim();
    final String normalizedCode = activationCode.trim().toUpperCase();

    if (normalizedUsername.isEmpty || normalizedCode.isEmpty) {
      return null;
    }

    final UserProfileModel? profile = await _repository.getProfileByUsername(
      normalizedUsername,
    );

    if (profile == null) {
      throw Exception('Usuario o código incorrectos.');
    }

    if (!profile.isActive) {
      throw Exception(
        'Tu cuenta está desactivada. '
        'Comunícate con el administrador para reactivarla.',
      );
    }

    final String? storedCodeHash = profile.activationCodeHash;

    if (storedCodeHash == null || storedCodeHash.isEmpty) {
      throw Exception(
        'No existe un código de activación válido para esta cuenta.',
      );
    }

    final String codeHash = _hashPassword(normalizedCode);

    if (codeHash != storedCodeHash) {
      throw Exception('Usuario o código incorrectos.');
    }
    final bool isAdministrator =
        profile.role.trim().toLowerCase() == 'administrador';

    if (isAdministrator) {
      throw Exception(
        'La cuenta del administrador no puede cambiar la contraseña '
        'mediante un código de recuperación.',
      );
    }

    final Database db = await DatabaseHelper.instance.database;

    await db.update(
      'user_profile',
      <String, Object?>{
        'activation_code_hash': null,
        'must_change_password': 1,
        'password_hash': '',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [profile.id],
    );

    final UserProfileModel? updatedProfile = await _repository
        .getProfileByUsername(normalizedUsername);

    if (updatedProfile == null) {
      throw Exception(
        'No fue posible preparar tu cuenta para crear la contraseña.',
      );
    }

   await _sessionManager.startSession(updatedProfile);

await AppearanceProvider.instance.loadAppearance();

return updatedProfile;
  }

  // =============================================================
  // CERRAR SESIÓN
  // =============================================================

  Future<void> logout() async {
  await _sessionManager.clearSession();

  await AppearanceProvider.instance.loadAppearance();
}

  // =============================================================
  // COMPROBAR SESIÓN
  // =============================================================

  Future<bool> hasActiveSession() async {
    return _sessionManager.hasActiveSession;
  }

  // =============================================================
  // OBTENER PERFIL DE SESIÓN
  // =============================================================

  UserProfileModel? get currentUser {
    return _sessionManager.currentUser;
  }

  // =============================================================
  // GENERAR HASH DE CONTRASEÑA
  // =============================================================

  String _hashPassword(String password) {
    final List<int> bytes = utf8.encode(password);

    return sha256.convert(bytes).toString();
  }

  // =============================================================
  // GENERAR HASH PARA NUEVAS CONTRASEÑAS
  // =============================================================

  String hashPassword(String password) {
    return _hashPassword(password);
  }
}
