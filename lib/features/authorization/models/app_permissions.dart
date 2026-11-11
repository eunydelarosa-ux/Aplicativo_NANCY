// =============================================================
// APLICATIVO NANCY
// Permisos de la aplicación
// =============================================================

class AppPermissions {
  const AppPermissions({
    required this.canAccessAdministration,
    required this.canManageUsers,
    required this.canCreateAdministrators,
    required this.canCreateCoordinators,
    required this.canCreateAdvisers,
    required this.canManageSites,
    required this.canAssignMunicipalitiesToSites,
    required this.canRegisterApplicants,
    required this.canViewApplicants,
    required this.canViewCentralInformation,
    required this.canSynchronize,
    required this.canAccessBackup,
    required this.canAccessReports,
  });

  // =============================================================
  // ADMINISTRACIÓN
  // =============================================================

  final bool canAccessAdministration;

  // =============================================================
  // USUARIOS
  // =============================================================

  final bool canManageUsers;

  final bool canCreateAdministrators;

  final bool canCreateCoordinators;

  final bool canCreateAdvisers;

  // =============================================================
  // SEDES
  // =============================================================

  final bool canManageSites;

  final bool canAssignMunicipalitiesToSites;

  // =============================================================
  // ASPIRANTES
  // =============================================================

  final bool canRegisterApplicants;

  final bool canViewApplicants;

  // =============================================================
  // INFORMACIÓN CENTRAL
  // =============================================================

  final bool canViewCentralInformation;

  // =============================================================
  // SINCRONIZACIÓN
  // =============================================================

  final bool canSynchronize;

  // =============================================================
  // BACKUP
  // =============================================================

  final bool canAccessBackup;

  // =============================================================
  // REPORTES
  // =============================================================

  final bool canAccessReports;
}
