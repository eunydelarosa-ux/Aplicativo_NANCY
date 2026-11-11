import '../models/app_permissions.dart';

class RolePermissionService {
  const RolePermissionService();

  AppPermissions getPermissions(String? role) {
    final String normalizedRole = (role ?? '').trim().toLowerCase();

    switch (normalizedRole) {
      case 'administrador':
        return const AppPermissions(
          canAccessAdministration: true,
          canManageUsers: true,
          canCreateAdministrators: true,
          canCreateCoordinators: true,
          canCreateAdvisers: true,
          canManageSites: true,
          canAssignMunicipalitiesToSites: true,
          canRegisterApplicants: true,
          canViewApplicants: true,
          canViewCentralInformation: true,
          canSynchronize: true,
          canAccessBackup: true,
          canAccessReports: true,
        );

      case 'coordinador':
        return const AppPermissions(
          canAccessAdministration: true,
          canManageUsers: true,
          canCreateAdministrators: false,
          canCreateCoordinators: false,
          canCreateAdvisers: true,
          canManageSites: false,
          canAssignMunicipalitiesToSites: false,
          canRegisterApplicants: true,
          canViewApplicants: true,
          canViewCentralInformation: true,
          canSynchronize: true,
          canAccessBackup: true,
          canAccessReports: true,
        );

      case 'asesor':
      case 'asistente':
        return const AppPermissions(
          canAccessAdministration: false,
          canManageUsers: false,
          canCreateAdministrators: false,
          canCreateCoordinators: false,
          canCreateAdvisers: false,
          canManageSites: false,
          canAssignMunicipalitiesToSites: false,
          canRegisterApplicants: true,
          canViewApplicants: true,
          canViewCentralInformation: false,
          canSynchronize: true,
          canAccessBackup: false,
          canAccessReports: true,
        );

      default:
        return const AppPermissions(
          canAccessAdministration: false,
          canManageUsers: false,
          canCreateAdministrators: false,
          canCreateCoordinators: false,
          canCreateAdvisers: false,
          canManageSites: false,
          canAssignMunicipalitiesToSites: false,
          canRegisterApplicants: false,
          canViewApplicants: false,
          canViewCentralInformation: false,
          canSynchronize: false,
          canAccessBackup: false,
          canAccessReports: false,
        );
    }
  }
}
