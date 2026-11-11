// ===============================================================
// APLICATIVO NANCY
// Administración
// ===============================================================

import 'package:flutter/material.dart';

import '../../models/app_permissions.dart';
import '../../services/role_permission_service.dart';
import '../../../session/session_manager.dart';
import 'user_management_page.dart';

class AdministrationPage extends StatelessWidget {
  const AdministrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SessionManager sessionManager = SessionManager.instance;

    final RolePermissionService permissionService =
        const RolePermissionService();

    final AppPermissions permissions = permissionService.getPermissions(
      sessionManager.currentRole,
    );

    if (!permissions.canAccessAdministration) {
      return Scaffold(
        appBar: AppBar(title: const Text('Administración')),
        body: const Center(
          child: Text('No tienes permisos para acceder a esta sección.'),
        ),
      );
    }

    return const UserManagementPage();
  }
}
