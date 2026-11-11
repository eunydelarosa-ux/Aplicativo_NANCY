// ===============================================================
// APLICATIVO NANCY
// Administrador de sesión
// ===============================================================

import '../profile/models/user_profile_model.dart';

class SessionManager {
  SessionManager._();

  static final SessionManager instance = SessionManager._();

  // =============================================================
  // ESTADO DE SESIÓN
  // =============================================================

  UserProfileModel? _currentUser;

  bool _isInitialized = false;

  // =============================================================
  // USUARIO ACTUAL
  // =============================================================

  UserProfileModel? get currentUser => _currentUser;

  // =============================================================
  // SESIÓN ACTIVA
  // =============================================================

  bool get hasActiveSession => _currentUser != null;

  // =============================================================
  // ESTADO DE INICIALIZACIÓN
  // =============================================================

  bool get isInitialized => _isInitialized;

  // =============================================================
  // ROL ACTUAL
  // =============================================================

  String? get currentRole => _currentUser?.role;

  // =============================================================
  // MUNICIPIO ACTUAL
  // =============================================================

  int? get currentMunicipalityId => _currentUser?.municipalityId;

  // =============================================================
  // SEDE ACTUAL
  // =============================================================

  int? get currentSiteId => _currentUser?.siteId;

  // =============================================================
  // INICIALIZAR ADMINISTRADOR DE SESIÓN
  // =============================================================

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;
  }

  // =============================================================
  // INICIAR SESIÓN
  // =============================================================

  Future<void> startSession(UserProfileModel user) async {
    _currentUser = user;
    _isInitialized = true;
  }

  // =============================================================
  // CERRAR SESIÓN
  // =============================================================

  Future<void> clearSession() async {
    _currentUser = null;
  }

  // =============================================================
  // COMPROBAR ROL
  // =============================================================

  bool hasRole(String role) {
    if (_currentUser == null) {
      return false;
    }

    return _currentUser!.role.trim().toLowerCase() == role.trim().toLowerCase();
  }

  // =============================================================
  // ES ADMINISTRADOR
  // =============================================================

  bool get isAdministrator {
    return hasRole('Administrador');
  }

  // =============================================================
  // ES COORDINADOR
  // =============================================================

  bool get isCoordinator {
    return hasRole('Coordinador');
  }

  // =============================================================
  // ES ASESOR
  // =============================================================

  bool get isAdviser {
    return hasRole('Asesor');
  }
}
