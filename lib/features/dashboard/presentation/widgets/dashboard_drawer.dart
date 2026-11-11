// =============================================================
// APLICATIVO NANCY
// Menú lateral principal
// =============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:nancy_app/features/profile/models/user_profile_model.dart';
import 'package:nancy_app/features/profile/providers/user_profile_provider.dart';
import 'package:nancy_app/features/session/session_manager.dart';
import 'package:nancy_app/features/configuration/providers/appearance_provider.dart';

import 'package:nancy_app/features/authorization/models/app_permissions.dart';
import 'package:nancy_app/features/authorization/services/role_permission_service.dart';

class DashboardDrawer extends StatefulWidget {
  const DashboardDrawer({super.key});

  @override
  State<DashboardDrawer> createState() => _DashboardDrawerState();
}

class _DashboardDrawerState extends State<DashboardDrawer> {
  // =============================================================
  // PROVIDER DEL PERFIL
  // =============================================================

  final UserProfileProvider _profileProvider = UserProfileProvider();

  final SessionManager _sessionManager = SessionManager.instance;
  final RolePermissionService _permissionService = RolePermissionService();
  // =============================================================
  // CICLO DE VIDA
  // =============================================================

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  // =============================================================
  // CARGAR PERFIL
  // =============================================================

  Future<void> _loadProfile() async {
    await _profileProvider.loadProfile();

    if (!mounted) return;

    setState(() {});
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final AppPermissions permissions = _permissionService.getPermissions(
      _sessionManager.currentRole,
    );

    return Drawer(
      width: 330,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF101820)
          : const Color(0xFFF7F9FD),

      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          child: Column(
            children: [
              // ===================================================
              // PERFIL DEL USUARIO
              // ===================================================
              _buildProfileHeader(context),

              // ===================================================
              // CONTENIDO DEL MENÚ
              // ===================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // =================================================
                    // PRINCIPAL
                    // =================================================
                    _buildSectionTitle(context, 'PRINCIPAL'),

                    const SizedBox(height: 8),

                    _buildMenuGroup(
                      context,
                      children: [
                        _buildMenuItem(
                          context,
                          icon: Icons.home_rounded,
                          title: 'Inicio',
                          color: const Color(0xFF2D8FE5),
                          selected: true,
                          onTap: () {
                            Navigator.pop(context);

                            if (GoRouterState.of(context).uri.path !=
                                '/dashboard') {
                              context.go('/dashboard');
                            }
                          },
                        ),

                        _buildDivider(context),

                        _buildMenuItem(
                          context,
                          icon: Icons.person_outline_rounded,
                          title: 'Mi Perfil',
                          color: const Color(0xFF64748B),
                          onTap: () async {
                            await context.push('/profile');
                          },
                        ),

                        _buildDivider(context),

                        _buildMenuItem(
                          context,
                          icon: Icons.settings_outlined,
                          title: 'Configuración',
                          color: const Color(0xFF64748B),
                          showArrow: true,
                          onTap: () async {
                            await context.push('/configuration');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // =================================================
                    // GESTIONAR DATOS
                    // =================================================
                    _buildSectionTitle(context, 'GESTIONAR DATOS'),

                    const SizedBox(height: 8),

                    _buildMenuGroup(
                      context,
                      children: [
                        _buildMenuItem(
                          context,
                          icon: Icons.menu_book_outlined,
                          title: 'Gestionar Datos',
                          color: const Color(0xFF8B5CF6),
                          showArrow: true,
                          onTap: () async {
                            await context.push('/catalogs');
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    if (permissions.canAccessAdministration) ...[
                      const SizedBox(height: 24),

                      // =================================================
                      // ADMINISTRACIÓN
                      // =================================================
                      _buildSectionTitle(context, 'ADMINISTRACIÓN'),

                      const SizedBox(height: 8),

                      _buildMenuGroup(
                        context,
                        children: [
                          _buildMenuItem(
                            context,
                            icon: Icons.admin_panel_settings_outlined,
                            title: 'Administración',
                            color: const Color(0xFF2563EB),
                            showArrow: true,
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/administration');
                            },
                          ),
                        ],
                      ),
                    ],

                    // =================================================
                    // HERRAMIENTAS
                    // =================================================
                    _buildSectionTitle(context, 'HERRAMIENTAS'),

                    const SizedBox(height: 8),

                    _buildMenuGroup(
                      context,
                      children: [
                        // =================================================
                        // EXPORTACIONES
                        // =================================================
                        _buildMenuItem(
                          context,
                          icon: Icons.file_upload_outlined,
                          title: 'Exportaciones',
                          color: const Color(0xFF4CAF50),
                          showArrow: true,
                          onTap: () async {
                            await context.push('/exports');
                          },
                        ),

                        _buildDivider(context),

                        // =================================================
                        // PAPELERA
                        // =================================================
                        _buildMenuItem(
                          context,
                          icon: Icons.delete_outline_rounded,
                          title: 'Papelera',
                          color: const Color(0xFFEF6C57),
                          showArrow: true,
                          onTap: () async {
                            await context.push('/trash');
                          },
                        ),
                        _buildDivider(context),

                        // =================================================
                        // COPIAS DE SEGURIDAD
                        // =================================================
                        if (permissions.canAccessBackup) ...[
                          _buildMenuItem(
                            context,
                            icon: Icons.cloud_upload_outlined,
                            title: 'Copias de seguridad',
                            color: const Color(0xFF3B82F6),
                            showArrow: true,
                            onTap: () async {
                              await context.push('/backup');
                            },
                          ),

                          _buildDivider(context),
                        ],

                        // =================================================
                        // ESTADÍSTICAS / REPORTES
                        // =================================================
                        _buildMenuItem(
                          context,
                          icon: Icons.bar_chart_rounded,
                          title: 'Estadísticas / Reportes',
                          color: const Color(0xFF8B5CF6),
                          showArrow: true,
                          onTap: () async {
                            await context.push('/reports');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ===================================================
              // CERRAR SESIÓN
              // ===================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),

                child: _buildLogoutButton(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // ENCABEZADO DEL PERFIL
  // =============================================================

  Widget _buildProfileHeader(BuildContext context) {
    final UserProfileModel? profile = _profileProvider.profile;

    final String name = profile?.name.isNotEmpty == true
        ? profile!.name
        : 'Usuario Nancy';

    final String role = profile?.role.isNotEmpty == true
        ? profile!.role
        : 'Sin rol registrado';

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: () {
          _showProfileDetails();
        },

        child: Container(
          width: double.infinity,

          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),

          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? const [Color(0xFF17232E), Color(0xFF1B2B35)]
                  : const [Color(0xFFF7FBFF), Color(0xFFF0F9F7)],
            ),

            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),

          child: Column(
            children: [
              Row(
                children: [
                  // =================================================
                  // FOTO
                  // =================================================
                  _buildSmallProfileImage(profile),

                  const SizedBox(width: 14),

                  // =================================================
                  // INFORMACIÓN
                  // =================================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          name,

                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF1F2A44),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          role,

                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFFB0BECC)
                                : const Color(0xFF7B879A),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: const [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 14,
                              color: Color(0xFF2D8FE5),
                            ),

                            SizedBox(width: 5),

                            Text(
                              'Ver perfil',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D8FE5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFB0BECC)
                        : const Color(0xFF8793A3),
                    size: 24,
                  ),
                ],
              ),

              const SizedBox(height: 17),

              // =====================================================
              // LÍNEA DECORATIVA
              // =====================================================
              Container(
                height: 4,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),

                  gradient: const LinearGradient(
                    colors: [Color(0xFFAEDFFF), Color(0xFFCBEFE4)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // FOTO PEQUEÑA DEL PERFIL
  // =============================================================

  Widget _buildSmallProfileImage(UserProfileModel? profile) {
    Widget imageWidget;

    if (profile?.imagePath != null && profile!.imagePath!.isNotEmpty) {
      final File imageFile = File(profile.imagePath!);

      if (imageFile.existsSync()) {
        imageWidget = Image.file(
          imageFile,
          width: 62,
          height: 62,
          fit: BoxFit.cover,
        );
      } else {
        imageWidget = _defaultSmallProfileIcon();
      }
    } else {
      imageWidget = _defaultSmallProfileIcon();
    }

    return Container(
      width: 68,
      height: 68,

      padding: const EdgeInsets.all(3),

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [Color(0xFF8DD8FF), Color(0xFFB8E8D6)],
        ),
      ),

      child: Container(
        padding: const EdgeInsets.all(2),

        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF17232E)
              : Colors.white,
        ),

        child: ClipOval(child: imageWidget),
      ),
    );
  }

  // =============================================================
  // ICONO PEQUEÑO POR DEFECTO
  // =============================================================

  Widget _defaultSmallProfileIcon() {
    return Container(
      width: 62,
      height: 62,

      color: const Color(0xFFEAF2F8),

      child: const Icon(
        Icons.person_rounded,
        size: 34,
        color: Color(0xFF7B8BA0),
      ),
    );
  }

  // =============================================================
  // VENTANA DE INFORMACIÓN DEL PERFIL
  // =============================================================

  void _showProfileDetails() {
    final UserProfileModel? profile = _profileProvider.profile;

    final String name = profile?.name.isNotEmpty == true
        ? profile!.name
        : 'Usuario Nancy';

    final String role = profile?.role.isNotEmpty == true
        ? profile!.role
        : 'Sin rol registrado';

    final String cedula = profile?.cedula?.isNotEmpty == true
        ? profile!.cedula!
        : 'Sin registrar';

    final String email = profile?.email.isNotEmpty == true
        ? profile!.email
        : 'Sin registrar';

    final String phone = profile?.phone.isNotEmpty == true
        ? profile!.phone
        : 'Sin registrar';
    showDialog(
      context: context,

      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,

          insetPadding: const EdgeInsets.symmetric(horizontal: 24),

          child: Container(
            width: 420,

            padding: const EdgeInsets.all(24),

            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1B2733)
                  : Colors.white,

              borderRadius: BorderRadius.circular(28),

              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3D5263)
                    : const Color(0xFFE2EAF3),
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),

            child: SingleChildScrollView(
              child: Column(
                children: [
                  // =================================================
                  // CERRAR
                  // =================================================
                  Align(
                    alignment: Alignment.topRight,

                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },

                      icon: Icon(
                        Icons.close_rounded,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),

                  // =================================================
                  // FOTO GRANDE
                  // =================================================
                  _buildLargeDialogProfileImage(profile),

                  const SizedBox(height: 18),

                  // =================================================
                  // NOMBRE
                  // =================================================
                  Text(
                    name,
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF1F2A44),
                    ),
                  ),

                  const SizedBox(height: 5),

                  // =================================================
                  // ROL
                  // =================================================
                  Text(
                    role,
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFB0BECC)
                          : const Color(0xFF7B879A),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =================================================
                  // INFORMACIÓN
                  // =================================================
                  _buildProfileDetailRow(
                    context: context,
                    icon: Icons.badge_outlined,
                    label: 'Cédula',
                    value: cedula,
                  ),

                  _buildProfileDetailRow(
                    context: context,
                    icon: Icons.work_outline_rounded,
                    label: 'Rol',
                    value: role,
                  ),

                  _buildProfileDetailRow(
                    context: context,
                    icon: Icons.email_outlined,
                    label: 'Correo',
                    value: email,
                  ),

                  _buildProfileDetailRow(
                    context: context,
                    icon: Icons.phone_outlined,
                    label: 'Teléfono',
                    value: phone,
                  ),

                  const SizedBox(height: 10),

                  // =================================================
                  // AVISO
                  // =================================================
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF243341)
                          : const Color(0xFFF5F9FD),
                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFF2D8FE5),
                        ),

                        SizedBox(width: 9),

                        Expanded(
                          child: Text(
                            'Para modificar esta información '
                            'entra en Mi Perfil.',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // FOTO GRANDE DEL DIÁLOGO
  // =============================================================

  Widget _buildLargeDialogProfileImage(UserProfileModel? profile) {
    Widget imageWidget;

    if (profile?.imagePath != null && profile!.imagePath!.isNotEmpty) {
      final File imageFile = File(profile.imagePath!);

      if (imageFile.existsSync()) {
        imageWidget = Image.file(
          imageFile,
          width: 132,
          height: 132,
          fit: BoxFit.cover,
        );
      } else {
        imageWidget = _defaultLargeProfileIcon();
      }
    } else {
      imageWidget = _defaultLargeProfileIcon();
    }

    return Container(
      width: 142,
      height: 142,

      padding: const EdgeInsets.all(4),

      decoration: const BoxDecoration(
        shape: BoxShape.circle,

        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [Color(0xFF8DD8FF), Color(0xFFB7E8D5)],
        ),
      ),

      child: Container(
        padding: const EdgeInsets.all(4),

        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),

        child: ClipOval(child: imageWidget),
      ),
    );
  }

  // =============================================================
  // ICONO GRANDE POR DEFECTO
  // =============================================================

  Widget _defaultLargeProfileIcon() {
    return Container(
      width: 132,
      height: 132,

      color: const Color(0xFFEAF3FA),

      child: const Icon(
        Icons.person_rounded,
        size: 70,
        color: Color(0xFF7B8BA0),
      ),
    );
  }

  // =============================================================
  // FILA DEL PERFIL EN VENTANA
  // =============================================================

  Widget _buildProfileDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF243341)
            : const Color(0xFFF7F9FD),

        borderRadius: BorderRadius.circular(15),

        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF344654)
              : const Color(0xFFE5EBF2),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(11),
            ),

            child: Icon(icon, color: const Color(0xFF2D8FE5), size: 20),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  label,

                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFB8C6D4)
                        : const Color(0xFF68788C),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFF8FAFC)
                        : const Color(0xFF26364F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // TÍTULO DE SECCIÓN
  // =============================================================

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),

      child: Text(
        title,

        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFB0BFCC)
              : const Color(0xFF788497),
        ),
      ),
    );
  }

  // =============================================================
  // GRUPO DE OPCIONES
  // =============================================================

  Widget _buildMenuGroup(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B2733)
            : const Color(0xFFFCFDFE),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF344654)
              : const Color(0xFFE1E8F0),
          width: 1,
        ),
      ),

      child: Column(children: children),
    );
  }

  // =============================================================
  // OPCIÓN DEL MENÚ
  // =============================================================

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool selected = false,
    bool showArrow = false,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(20),

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

          decoration: BoxDecoration(
            color: selected
                ? (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF203B50)
                      : const Color(0xFFEAF4FF))
                : Colors.transparent,

            borderRadius: BorderRadius.circular(20),
          ),

          child: Row(
            children: [
              // =================================================
              // ICONO
              // =================================================
              Container(
                width: 40,
                height: 40,

                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),

                  borderRadius: BorderRadius.circular(12),
                ),

                child: Icon(icon, color: color, size: 23),
              ),

              const SizedBox(width: 14),

              // =================================================
              // TEXTO
              // =================================================
              Expanded(
                child: Text(
                  title,

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 16,

                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,

                    color: selected
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF75C2FF)
                              : const Color(0xFF2584D8))
                        : (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFF8FAFC)
                              : const Color(0xFF26364F)),
                  ),
                ),
              ),

              // =================================================
              // FLECHA
              // =================================================
              if (showArrow)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFB8C6D4)
                      : const Color(0xFF8793A3),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // SEPARADOR
  // =============================================================

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 0.7,
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF344654)
            : const Color(0xFFE5EAF0),
      ),
    );
  }

  // =============================================================
  // CERRAR SESIÓN
  // =============================================================

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: () async {
  await _sessionManager.clearSession();

  await AppearanceProvider.instance.loadAppearance();

  if (!context.mounted) {
    return;
  }

  Navigator.pop(context);
  context.go('/login');
},
        borderRadius: BorderRadius.circular(18),

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF302329)
                : const Color(0xFFFFF6F6),

            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF58383D)
                  : const Color(0xFFF5DADA),
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,

                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8E8),

                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFE45757),
                  size: 23,
                ),
              ),

              const SizedBox(width: 14),

              const Text(
                'Cerrar Sesión',

                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE45757),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
