// ===============================================================
// APLICATIVO NANCY
// Provider del perfil del usuario
// ===============================================================

import 'package:flutter/foundation.dart';

import '../models/user_profile_model.dart';
import '../repositories/user_profile_repository.dart';
import '../../session/session_manager.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfileProvider({UserProfileRepository? repository})
    : _repository = repository ?? UserProfileRepository();

  final UserProfileRepository _repository;

  // =============================================================
  // ESTADO
  // =============================================================

  UserProfileModel? _profile;

  bool _isLoading = false;

  String? _errorMessage;

  // =============================================================
  // LECTURA DEL ESTADO
  // =============================================================

  UserProfileModel? get profile => _profile;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasProfile => _profile != null;

  // =============================================================
  // CARGAR PERFIL
  // =============================================================

  Future<void> loadProfile() async {
    _setLoading(true);

    try {
      _errorMessage = null;

      _profile = await _repository.getProfile();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'No fue posible cargar el perfil.';

      if (kDebugMode) {
        debugPrint('Error al cargar perfil: $e');
      }

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // GUARDAR PERFIL
  // =============================================================

  Future<bool> saveProfile({
    required String name,
    required String role,
    String? username,
    required String email,
    required String phone,
    String? cedula,
    String? imagePath,
    int? municipalityId,
    int? siteId,
    String? passwordHash,
    bool? isActive,
    bool removeImage = false,
  }) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final DateTime now = DateTime.now();

      String? finalImagePath;

      if (removeImage) {
        finalImagePath = null;
      } else if (imagePath != null) {
        finalImagePath = imagePath;
      } else {
        finalImagePath = _profile?.imagePath;
      }
      final UserProfileModel profile = UserProfileModel(
        id: _profile?.id,
        name: name.trim(),
        role: _profile?.role ?? role.trim(),
        username: _profile?.username ?? username?.trim() ?? '',
        email: email.trim(),
        phone: phone.trim(),
        cedula: cedula?.trim(),
        imagePath: finalImagePath,
        municipalityId: _profile?.municipalityId ?? municipalityId,
        siteId: _profile?.siteId ?? siteId,
        passwordHash: _profile?.passwordHash ?? passwordHash ?? '',
        isActive: _profile?.isActive ?? isActive ?? true,
        createdAt: _profile?.createdAt ?? now,
        updatedAt: now,
        createdByUserId: _profile?.createdByUserId,
      );
      await _repository.saveProfile(profile);

      _profile = await _repository.getProfile();

      if (_profile != null) {
        await SessionManager.instance.startSession(_profile!);
      }

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible guardar el perfil.';

      if (kDebugMode) {
        debugPrint('Error al guardar perfil: $e');
      }

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // ACTUALIZAR PERFIL
  // =============================================================

  Future<bool> updateProfile(UserProfileModel profile) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final UserProfileModel? currentProfile = await _repository.getProfile();

      if (currentProfile == null) {
        throw StateError(
          'No se encontró el perfil del usuario que inició sesión.',
        );
      }

      if (profile.id != null && profile.id != currentProfile.id) {
        throw StateError('No puedes modificar el perfil de otro usuario.');
      }

      final UserProfileModel updatedProfile = profile.copyWith(
        id: currentProfile.id,
        role: currentProfile.role,
        username: currentProfile.username,
        createdAt: currentProfile.createdAt,
        createdByUserId: currentProfile.createdByUserId,
        updatedAt: DateTime.now(),
      );
      await _repository.saveProfile(updatedProfile);

      _profile = await _repository.getProfile();

      if (_profile != null) {
        await SessionManager.instance.startSession(_profile!);
      }

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible actualizar el perfil.';

      if (kDebugMode) {
        debugPrint('Error al actualizar perfil: $e');
      }

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // GUARDAR O QUITAR FOTO DEL PERFIL INMEDIATAMENTE
  // =============================================================

  Future<bool> updateProfileImage({String? imagePath}) async {
    try {
      _errorMessage = null;

      await _repository.updateProfileImage(imagePath: imagePath);

      _profile = await _repository.getProfile();

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible actualizar la foto del perfil.';

      if (kDebugMode) {
        debugPrint('Error al actualizar foto del perfil: $e');
      }

      notifyListeners();

      return false;
    }
  }

  // =============================================================
  // ESTABLECER CONTRASEÑA PERSONAL
  // =============================================================

  Future<bool> setPersonalPassword({required String passwordHash}) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      await _repository.setPersonalPassword(passwordHash: passwordHash);

      _profile = await _repository.getProfile();

      if (_profile != null) {
        await SessionManager.instance.startSession(_profile!);
      }

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible establecer la contraseña personal.';

      if (kDebugMode) {
        debugPrint('Error al establecer contraseña personal: $e');
      }

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // ELIMINAR PERFIL
  // =============================================================

  Future<bool> deleteProfile() async {
    _setLoading(true);

    try {
      _errorMessage = null;

      await _repository.deleteProfile();

      _profile = null;

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible eliminar el perfil.';

      if (kDebugMode) {
        debugPrint('Error al eliminar perfil: $e');
      }

      notifyListeners();

      return false;
    } finally {
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
  // CONTROL INTERNO DE CARGA
  // =============================================================

  void _setLoading(bool value) {
    _isLoading = value;

    notifyListeners();
  }
}
