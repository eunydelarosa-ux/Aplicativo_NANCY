// =============================================================
// APLICATIVO NANCY
// Permisos según rol
// =============================================================

import 'session_manager.dart';

class AppPermissions {
  AppPermissions._();

  // =============================================================
  // REGISTRO DE ASPIRANTES
  // =============================================================

  static bool canRegisterApplicants(SessionManager session) {
    return session.isCoordinator || session.isAdviser;
  }

  // =============================================================
  // LISTADO DE ASPIRANTES
  // =============================================================

  static bool canViewApplicants(SessionManager session) {
    return session.isCoordinator || session.isAdviser;
  }

  // =============================================================
  // SINCRONIZACIÓN
  // =============================================================

  static bool canSynchronize(SessionManager session) {
    return session.isCoordinator || session.isAdviser;
  }

  // =============================================================
  // CATÁLOGOS / GESTIÓN DE DATOS
  // =============================================================

  static bool canManageCatalogs(SessionManager session) {
    return session.isCoordinator;
  }

  // =============================================================
  // HERRAMIENTAS
  // =============================================================

  static bool canUseTools(SessionManager session) {
    return session.isCoordinator;
  }

  // =============================================================
  // GESTIÓN DE USUARIOS
  // =============================================================

  static bool canManageUsers(SessionManager session) {
    return session.isAdministrator;
  }

  // =============================================================
  // CONSULTA DE INFORMACIÓN CENTRAL
  // =============================================================

  static bool canQueryCentralData(SessionManager session) {
    return session.isAdministrator || session.isCoordinator;
  }

  // =============================================================
  // HISTORIAL
  // =============================================================

  static bool canViewHistory(SessionManager session) {
    return session.isCoordinator || session.isAdviser;
  }

  // =============================================================
  // EXPORTACIONES
  // =============================================================

  static bool canExportData(SessionManager session) {
    return session.isCoordinator;
  }

  // =============================================================
  // COPIAS DE SEGURIDAD
  // =============================================================

  static bool canUseBackup(SessionManager session) {
    return session.isCoordinator;
  }

  // =============================================================
  // REPORTES
  // =============================================================

  static bool canViewReports(SessionManager session) {
    return session.isCoordinator || session.isAdministrator;
  }

  // =============================================================
  // PAPELERA
  // =============================================================

  static bool canUseTrash(SessionManager session) {
    return session.isCoordinator || session.isAdviser;
  }

  // =============================================================
  // FUNCIONES COMUNES
  // =============================================================

  static bool canUseCalendar(SessionManager session) {
    return session.hasActiveSession;
  }

  static bool canViewProfile(SessionManager session) {
    return session.hasActiveSession;
  }

  static bool canUseConfiguration(SessionManager session) {
    return session.hasActiveSession;
  }

  static bool canUsePreferences(SessionManager session) {
    return session.hasActiveSession;
  }

  static bool canUseAppearance(SessionManager session) {
    return session.hasActiveSession;
  }

  static bool canUseNotifications(SessionManager session) {
    return session.hasActiveSession;
  }
}
