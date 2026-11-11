// ===============================================================
// APLICATIVO NANCY
// Provider de administración de usuarios
// ===============================================================

import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../profile/models/user_profile_model.dart';
import '../../session/session_manager.dart';
import '../repositories/user_management_repository.dart';

class UserManagementProvider extends ChangeNotifier {
  UserManagementProvider({UserManagementRepository? repository})
    : _repository = repository ?? UserManagementRepository();

  final UserManagementRepository _repository;
  final SessionManager _sessionManager = SessionManager.instance;

  // =============================================================
  // ESTADO
  // =============================================================

  List<UserProfileModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserProfileModel> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // =============================================================
  // PERMISOS
  // =============================================================

  bool get _isAdministrator => _sessionManager.isAdministrator;
  bool get _isCoordinator => _sessionManager.isCoordinator;

  int? get _currentUserId => _sessionManager.currentUser?.id;

  bool _canManage(UserProfileModel user) {
    if (_currentUserId == null || user.id == null) {
      return false;
    }

    // El administrador puede gestionar cualquier usuario,
    // excepto desactivar o eliminar su propia cuenta.
    if (_isAdministrator) {
      return true;
    }

    // El coordinador solo puede gestionar asesores
    // que él mismo haya creado.
    if (_isCoordinator) {
      return user.role.trim().toLowerCase() == 'asesor' &&
          user.createdByUserId == _currentUserId;
    }

    // Los asesores no administran usuarios.
    return false;
  }

  bool _canCreateRole(String role) {
    if (_isAdministrator) {
      return true;
    }

    if (_isCoordinator) {
      return role.trim().toLowerCase() == 'asesor';
    }

    return false;
  }

  // =============================================================
  // CARGAR USUARIOS
  // =============================================================

  Future<void> loadUsers({bool onlyActive = false}) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final List<UserProfileModel> allUsers = await _repository.getUsers(
        onlyActive: onlyActive,
      );

      if (_isAdministrator) {
        _users = allUsers;
      } else if (_isCoordinator && _currentUserId != null) {
        _users = allUsers.where((user) {
          return user.role.trim().toLowerCase() == 'asesor' &&
              user.createdByUserId == _currentUserId;
        }).toList();
      } else {
        _users = [];
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = 'No fue posible cargar los usuarios.';

      if (kDebugMode) {
        debugPrint('Error al cargar usuarios: $e');
      }

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // COMPROBAR USERNAME
  // =============================================================

  Future<bool> usernameExists(String username, {int? excludeUserId}) async {
    try {
      return await _repository.usernameExists(
        username,
        excludeUserId: excludeUserId,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al comprobar username: $e');
      }

      return false;
    }
  }

  // =============================================================
  // CREAR USUARIO
  // =============================================================

  Future<bool> createUser(UserProfileModel user) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      if (!_canCreateRole(user.role)) {
        _errorMessage = 'No tienes permiso para crear este tipo de usuario.';
        return false;
      }

      if (_currentUserId == null) {
        _errorMessage = 'No hay una sesión de usuario activa.';
        return false;
      }

      final bool exists = await _repository.usernameExists(user.username);

      if (exists) {
        _errorMessage = 'El nombre de usuario ya existe.';
        return false;
      }

      final UserProfileModel userToSave = user.copyWith(
        createdByUserId: _currentUserId,
      );

      await _repository.insertUser(userToSave);
      await _reloadUsers();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible crear el usuario.';

      if (kDebugMode) {
        debugPrint('Error al crear usuario: $e');
      }

      return false;
    } finally {
      notifyListeners();
      _setLoading(false);
    }
  }

  // =============================================================
  // ACTUALIZAR USUARIO
  // =============================================================

  Future<bool> updateUser(UserProfileModel user) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      if (user.id == null) {
        _errorMessage = 'No se encontró el usuario que deseas editar.';
        return false;
      }

      final UserProfileModel? existingUser = await _repository.getUserById(
        user.id!,
      );

      if (existingUser == null || !_canManage(existingUser)) {
        _errorMessage = 'No tienes permiso para editar este usuario.';
        return false;
      }

      // Un coordinador no puede cambiar el rol ni el creador
      // de un asesor que tiene asignado.
      final UserProfileModel userToSave = user.copyWith(
        role: _isCoordinator ? existingUser.role : user.role,
        createdByUserId: existingUser.createdByUserId,
      );

      if (!_canCreateRole(userToSave.role)) {
        _errorMessage = 'No tienes permiso para asignar ese rol.';
        return false;
      }

      final bool exists = await _repository.usernameExists(
        userToSave.username,
        excludeUserId: userToSave.id,
      );

      if (exists) {
        _errorMessage = 'El nombre de usuario ya existe.';
        return false;
      }

      await _repository.updateUser(userToSave);
      await _reloadUsers();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible actualizar el usuario.';

      if (kDebugMode) {
        debugPrint('Error al actualizar usuario: $e');
      }

      return false;
    } finally {
      notifyListeners();
      _setLoading(false);
    }
  }

  // =============================================================
  // GENERAR CÓDIGO DE ACTIVACIÓN O RECUPERACIÓN
  // =============================================================

  Future<String?> generateRecoveryCode(int userId) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final UserProfileModel? targetUser = await _repository.getUserById(
        userId,
      );

      if (targetUser == null || !_canManage(targetUser)) {
        _errorMessage =
            'No tienes permiso para generar un código para este usuario.';
        return null;
      }

      final String code = _generateActivationCode();

      final UserProfileModel updatedUser = targetUser.copyWith(
        activationCodeHash: sha256.convert(utf8.encode(code)).toString(),
        mustChangePassword: true,
        updatedAt: DateTime.now(),
      );

      await _repository.updateUser(updatedUser);
      await _reloadUsers();

      return code;
    } catch (e) {
      _errorMessage = 'No fue posible generar el código de recuperación.';

      if (kDebugMode) {
        debugPrint('Error al generar código de recuperación: $e');
      }

      return null;
    } finally {
      notifyListeners();
      _setLoading(false);
    }
  }

  String _generateActivationCode() {
    const String characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final math.Random random = math.Random.secure();

    return List<String>.generate(
      12,
      (_) => characters[random.nextInt(characters.length)],
    ).join();
  }

  // =============================================================
  // ACTIVAR / DESACTIVAR USUARIO
  // =============================================================

  Future<bool> setUserActive({
    required int userId,
    required bool active,
  }) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final UserProfileModel? targetUser = await _repository.getUserById(
        userId,
      );

      if (targetUser == null || !_canManage(targetUser)) {
        _errorMessage = 'No tienes permiso para modificar este usuario.';
        return false;
      }

      if (!active && userId == _currentUserId) {
        _errorMessage = 'No puedes desactivar tu propia cuenta.';
        return false;
      }

      await _repository.setUserActive(userId, active);
      await _reloadUsers();

      return true;
    } catch (e) {
      _errorMessage = active
          ? 'No fue posible activar el usuario.'
          : 'No fue posible desactivar el usuario.';

      if (kDebugMode) {
        debugPrint('Error al cambiar estado del usuario: $e');
      }

      return false;
    } finally {
      notifyListeners();
      _setLoading(false);
    }
  }

  // =============================================================
  // ELIMINAR USUARIO
  // =============================================================

  Future<bool> deleteUser(int userId) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      if (userId == _currentUserId) {
        _errorMessage = 'No puedes eliminar tu propia cuenta.';
        return false;
      }

      final UserProfileModel? targetUser = await _repository.getUserById(
        userId,
      );

      if (targetUser == null || !_canManage(targetUser)) {
        _errorMessage = 'No tienes permiso para eliminar este usuario.';
        return false;
      }

      await _repository.deleteUser(userId);
      await _reloadUsers();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible eliminar el usuario.';

      if (kDebugMode) {
        debugPrint('Error al eliminar usuario: $e');
      }

      return false;
    } finally {
      notifyListeners();
      _setLoading(false);
    }
  }

  // =============================================================
  // LIMPIAR ERROR
  // =============================================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // =============================================================
  // RECARGAR USUARIOS
  // =============================================================

  Future<void> _reloadUsers() async {
    final List<UserProfileModel> allUsers = await _repository.getUsers();

    if (_isAdministrator) {
      _users = allUsers;
    } else if (_isCoordinator && _currentUserId != null) {
      _users = allUsers.where((user) {
        return user.role.trim().toLowerCase() == 'asesor' &&
            user.createdByUserId == _currentUserId;
      }).toList();
    } else {
      _users = [];
    }

    notifyListeners();
  }

  // =============================================================
  // CONTROL INTERNO DE CARGA
  // =============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
