// ===============================================================
// APLICATIVO NANCY
// Gestión de Usuarios
// ===============================================================

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:crypto/crypto.dart';

import '../../models/app_permissions.dart';
import '../../providers/user_management_provider.dart';
import '../../services/role_permission_service.dart';
import '../../../session/session_manager.dart';
import '../../../profile/models/user_profile_model.dart';
import '../../../sites/models/site_model.dart';
import '../../../sites/providers/site_provider.dart';
import '../../../sites/providers/site_municipality_provider.dart';
import '../../../location/models/municipality_model.dart';
import '../../../location/providers/location_provider.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  // =============================================================
  // SERVICIOS
  // =============================================================

  final SessionManager _sessionManager = SessionManager.instance;

  final RolePermissionService _permissionService =
      const RolePermissionService();

  final UserManagementProvider _userProvider = UserManagementProvider();
  final SiteProvider _siteProvider = SiteProvider();

  // =============================================================
  // BÚSQUEDA Y PAGINACIÓN
  // =============================================================

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedSection = '';
  int _currentPage = 0;

  static const int _usersPerPage = 10;

  // =============================================================
  // CICLO DE VIDA
  // =============================================================

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadSites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userProvider.dispose();
    _siteProvider.dispose();
    super.dispose();
  }

  // =============================================================
  // CARGAR USUARIOS
  // =============================================================
  Future<void> _loadUsers() async {
    await _userProvider.loadUsers();

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _loadSites() async {
    await _siteProvider.loadSites();

    if (!mounted) return;

    setState(() {});
  }

  // =============================================================
  // CONSTRUIR
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final AppPermissions permissions = _permissionService.getPermissions(
      _sessionManager.currentRole,
    );

    if (!permissions.canManageUsers) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de Usuarios')),
        body: const Center(
          child: Text('No tienes permisos para administrar usuarios.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
          onPressed: () {
            if (_selectedSection.isNotEmpty) {
              setState(() {
                _selectedSection = '';
                _searchQuery = '';
                _searchController.clear();
                _currentPage = 0;
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Administración',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(onRefresh: _loadUsers, child: _buildBody()),
      ),
    );
  }

  // =============================================================
  // CUERPO
  // =============================================================
  Widget _buildBody() {
    if (_userProvider.isLoading && _userProvider.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userProvider.errorMessage != null && _userProvider.users.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _userProvider.errorMessage!,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _loadUsers,
              child: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }

    final bool isAdmin = _sessionManager.isAdministrator;

    final List<UserProfileModel> visibleUsers = isAdmin
        ? _userProvider.users
        : _userProvider.users
              .where(
                (UserProfileModel user) =>
                    user.role.trim().toLowerCase() == 'asesor',
              )
              .toList();

    // =============================================================
    // SECCIÓN MOSTRADA POR DEFECTO
    // =============================================================

    final String activeSection = isAdmin
        ? (_selectedSection.isEmpty ? 'coordinadores' : _selectedSection)
        : 'asesores';

    // =============================================================
    // USUARIOS DE LA SECCIÓN ACTUAL
    // =============================================================

    final List<UserProfileModel> sectionUsers = isAdmin
        ? visibleUsers.where((UserProfileModel user) {
            final String role = user.role.trim().toLowerCase();

            if (activeSection == 'coordinadores') {
              return role == 'coordinador';
            }

            if (activeSection == 'asesores') {
              return role == 'asesor';
            }

            return false;
          }).toList()
        : visibleUsers;

    // =============================================================
    // CONTADORES DE LA SECCIÓN ACTUAL
    // =============================================================

    final int totalCount = sectionUsers.length;

    final int activeCount = sectionUsers
        .where((UserProfileModel user) => user.isActive)
        .length;

    final int inactiveCount = sectionUsers
        .where((UserProfileModel user) => !user.isActive)
        .length;

    // =============================================================
    // BÚSQUEDA
    // =============================================================

    final String query = _normalizeSearchText(
      _searchQuery.trim(),
    ).replaceAll(RegExp(r'\s+'), ' ');

    final List<String> queryParts = query
        .split(' ')
        .where((String part) => part.isNotEmpty)
        .toList();

    final List<UserProfileModel> filteredUsers = sectionUsers.where((
      UserProfileModel user,
    ) {
      if (queryParts.isEmpty) {
        return true;
      }

      final String searchableText = _normalizeSearchText(
        [
          user.id,
          user.name,
          user.role,
          user.username,
          user.email,
          user.phone,
          user.cedula,
          user.municipalityId ?? '',
          user.siteId ?? '',
          user.createdByUserId ?? '',
        ].join(' '),
      ).replaceAll(RegExp(r'\s+'), ' ');

      return queryParts.every((String part) => searchableText.contains(part));
    }).toList();

    final int totalPages = (filteredUsers.length / _usersPerPage).ceil();

    if (totalPages == 0 && _currentPage != 0) {
      _currentPage = 0;
    } else if (totalPages > 0 && _currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }

    final int startIndex = _currentPage * _usersPerPage;

    final int endIndex = (startIndex + _usersPerPage) > filteredUsers.length
        ? filteredUsers.length
        : startIndex + _usersPerPage;

    final List<UserProfileModel> pageUsers = filteredUsers.sublist(
      startIndex,
      endIndex,
    );

    // =============================================================
    // VISTA
    // =============================================================

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // =========================================================
        // TARJETA PRINCIPAL
        // =========================================================
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1976D2).withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // =====================================================
              // ICONO + TÍTULO + INFORMACIÓN
              // =====================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.people_outline_rounded,
                      color: Colors.white,
                      size: 31,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdmin
                              ? 'Gestión de Usuarios'
                              : 'Gestión de Asesores',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          isAdmin
                              ? 'Crear, consultar, actualizar y '
                                    'administrar las cuentas de los usuarios.'
                              : 'Crear, consultar y administrar las '
                                    'cuentas de los asesores.',
                          maxLines: 3,
                          softWrap: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // =====================================================
              // BOTÓN CREAR
              // =====================================================
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _showCreateUserDialog,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: Color(0xFF1C4F8F),
                            size: 19,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            isAdmin ? 'Crear usuario' : 'Crear asesor',
                            style: const TextStyle(
                              color: Color(0xFF1C4F8F),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =====================================================
              // ESTADÍSTICAS
              // =====================================================
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryStat(value: totalCount, label: 'Total'),
                  ),

                  Container(
                    width: 1,
                    height: 38,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),

                  Expanded(
                    child: _buildSummaryStat(
                      value: activeCount,
                      label: 'Activos',
                      indicator: Colors.green,
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 38,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),

                  Expanded(
                    child: _buildSummaryStat(
                      value: inactiveCount,
                      label: 'Inactivos',
                      indicator: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // =========================================================
        // BUSCADOR
        // =========================================================
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE0E7EF)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (String value) {
              setState(() {
                _searchQuery = value;
                _currentPage = 0;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, documento o usuario...',
              hintStyle: const TextStyle(
                color: Color(0xFF8D98A8),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF425C7A),
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _currentPage = 0;
                        });
                      },
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // =========================================================
        // SELECTORES
        // =========================================================
        if (isAdmin) ...[
          Row(
            children: [
              Expanded(
                child: _buildSectionSelector(
                  title: 'Coordinadores',
                  subtitle: 'Gestiona los coordinadores',
                  count: visibleUsers
                      .where(
                        (UserProfileModel user) =>
                            user.role.trim().toLowerCase() == 'coordinador',
                      )
                      .length,
                  color: const Color(0xFF1976D2),
                  icon: Icons.supervisor_account_rounded,
                  selected: activeSection == 'coordinadores',
                  onTap: () {
                    setState(() {
                      _selectedSection = 'coordinadores';
                      _searchQuery = '';
                      _searchController.clear();
                      _currentPage = 0;
                    });
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildSectionSelector(
                  title: 'Asesores',
                  subtitle: 'Gestiona los asesores',
                  count: visibleUsers
                      .where(
                        (UserProfileModel user) =>
                            user.role.trim().toLowerCase() == 'asesor',
                      )
                      .length,
                  color: const Color(0xFF15966A),
                  icon: Icons.support_agent_rounded,
                  selected: activeSection == 'asesores',
                  onTap: () {
                    setState(() {
                      _selectedSection = 'asesores';
                      _searchQuery = '';
                      _searchController.clear();
                      _currentPage = 0;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _buildAccountSelector(),
        ] else ...[
          _buildSectionSelector(
            title: 'Asesores',
            subtitle: 'Mis asesores',
            count: visibleUsers.length,
            color: const Color(0xFF15966A),
            icon: Icons.support_agent_rounded,
            selected: true,
            onTap: null,
          ),

          const SizedBox(height: 8),

          _buildAccountSelector(),
        ],

        const SizedBox(height: 12),

        // =========================================================
        // LISTADO
        // =========================================================
        if (pageUsers.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE1E8F0)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 48,
                  color: const Color(0xFF6F839A).withValues(alpha: 0.55),
                ),
                const SizedBox(height: 12),
                Text(
                  activeSection == 'coordinadores'
                      ? 'No hay coordinadores registrados.'
                      : 'No hay asesores registrados.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF304761),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        else
          ...pageUsers.map((UserProfileModel user) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildUserCard(user),
            );
          }),

        // =========================================================
        // PAGINACIÓN
        // =========================================================
        if (filteredUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Página anterior',
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() {
                            _currentPage--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: const Color(0xFF6C819A),
                ),
                const SizedBox(width: 8),
                Text(
                  'Página ${_currentPage + 1} de $totalPages',
                  style: const TextStyle(
                    color: Color(0xFF425C7A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Página siguiente',
                  onPressed: _currentPage + 1 < totalPages
                      ? () {
                          setState(() {
                            _currentPage++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: const Color(0xFF6C819A),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // =============================================================
  // ESTADÍSTICA DE RESUMEN
  // =============================================================

  Widget _buildSummaryStat({
    required int value,
    required String label,
    Color? indicator,
  }) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (indicator != null) ...[
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: indicator,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =============================================================
  // SELECTOR DE SECCIÓN
  // =============================================================

  Widget _buildSectionSelector({
    required String title,
    required String subtitle,
    required int count,
    required Color color,
    required IconData icon,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 78,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? color : color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.16),
                width: selected ? 1.2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.18)
                        : color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 24,
                    color: selected ? Colors.white : color,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF203550),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        '$count usuarios',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.92)
                              : const Color(0xFF647892),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // =============================================================
  // CUENTA ACTUAL
  // =============================================================

  Widget _buildAccountSelector() {
    final UserProfileModel? currentUser = _sessionManager.currentUser;

    final String name = currentUser?.name.trim().isNotEmpty == true
        ? currentUser!.name.trim()
        : 'Mi cuenta';

    final String role = currentUser?.role.trim().isNotEmpty == true
        ? currentUser!.role.trim()
        : 'Usuario';

    final String initial = name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : 'U';

    final bool isAdministrator = role.toLowerCase() == 'administrador';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE7F1FF), Color(0xFFD5E7FF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF70A6E8), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // =====================================================
          // AVATAR DE CUENTA PRINCIPAL
          // =====================================================
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFF2D7EDB),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // =====================================================
          // INFORMACIÓN
          // =====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF16375E),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF315C8E),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF18A35F),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Activo',
                      style: TextStyle(
                        color: Color(0xFF15966A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // =====================================================
          // TRES PUNTICOS
          // =====================================================
          PopupMenuButton<String>(
            tooltip: 'Cuenta protegida',
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Color(0xFF16375E),
              size: 26,
            ),
            onSelected: (String value) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Acción no permitida. Tu cuenta está protegida '
                    'y no puede modificarse ni eliminarse desde esta sección.',
                  ),
                ),
              );
            },
            itemBuilder: (BuildContext context) => [
              if (!isAdministrator)
                const PopupMenuItem<String>(
                  value: 'recovery',
                  child: Row(
                    children: [
                      Icon(Icons.key_rounded, size: 20),
                      SizedBox(width: 10),
                      Expanded(child: Text('Generar código de recuperación')),
                      SizedBox(width: 10),
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: Color(0xFF7A8798),
                      ),
                    ],
                  ),
                ),

              const PopupMenuItem<String>(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(Icons.block_rounded, size: 20),
                    SizedBox(width: 10),
                    Expanded(child: Text('Desactivar')),
                    SizedBox(width: 10),
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: Color(0xFF7A8798),
                    ),
                  ],
                ),
              ),

              if (!isAdministrator)
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 20),
                      SizedBox(width: 10),
                      Expanded(child: Text('Eliminar')),
                      SizedBox(width: 10),
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: Color(0xFF7A8798),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================================
  // TARJETA DE USUARIO
  // =============================================================
  Widget _buildUserCard(UserProfileModel user) {
    final bool isAdministrator =
        user.role.trim().toLowerCase() == 'administrador';

    final Color roleColor = _roleColor(user.role);

    final String cleanName = user.name.trim().isEmpty
        ? 'Sin nombre'
        : user.name.trim();

    final String initial = cleanName.substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B2733)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF344654)
              : const Color(0xFFE1E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // =======================================================
          // AVATAR
          // =======================================================
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                color: roleColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // =======================================================
          // INFORMACIÓN
          // =======================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cleanName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  user.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: roleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  '@${user.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF71839A),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // =======================================================
          // ESTADO
          // =======================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: user.isActive
                  ? const Color(0xFFE7F7EF)
                  : const Color(0xFFFFE9EC),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? const Color(0xFF16A05D)
                        : const Color(0xFFF12D3A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  user.isActive ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: user.isActive
                        ? const Color(0xFF15966A)
                        : const Color(0xFFD92335),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // =======================================================
          // MENÚ DE ACCIONES
          // =======================================================
          if (_sessionManager.isAdministrator || _sessionManager.isCoordinator)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'toggle') {
                  _toggleUser(user);
                } else if (value == 'delete') {
                  _confirmDelete(user);
                } else if (value == 'recovery') {
                  if (user.role.trim().toLowerCase() == 'administrador') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No se puede generar un código de recuperación '
                          'para la cuenta del Administrador.',
                        ),
                      ),
                    );
                    return;
                  }

                  _confirmGenerateRecoveryCode(user);
                }
              },
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.more_vert_rounded,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFEAF2FA)
                    : const Color(0xFF173050),
                size: 24,
              ),
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'recovery',
                  height: 64,
                  child: Row(
                    children: [
                      Icon(Icons.key_rounded, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Generar código de recuperación',
                          maxLines: 2,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'toggle',
                  child: Text(user.isActive ? 'Desactivar' : 'Activar'),
                ),
                if (!isAdministrator)
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Eliminar'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
  // =============================================================
  // CREAR USUARIO
  // =============================================================

  Future<void> _showCreateUserDialog() async {
    await _siteProvider.loadSites();

    if (!mounted) return;

    String selectedRole = _sessionManager.isAdministrator
        ? 'Coordinador'
        : 'Asesor';

    int? selectedSiteId;

    String name = '';
    String username = '';
    String email = '';
    String phone = '';

    String? validationMessage;
    String? generatedActivationCode;

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final Size screenSize = MediaQuery.sizeOf(dialogContext);

            final double dialogMaxHeight = (screenSize.height * 0.78).clamp(
              460.0,
              620.0,
            );

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
              actionsPadding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
              actionsAlignment: MainAxisAlignment.spaceBetween,

              title: Text(
                'Crear usuario',
                style: TextStyle(
                  color: Theme.of(dialogContext).brightness == Brightness.dark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF162F4E),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),

              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: dialogMaxHeight,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (validationMessage != null) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF3B8C0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFD92335),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  validationMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFB42332),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // =====================================================
                      // ROL
                      // =====================================================
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 6),
                            child: Text(
                              'Rol',
                              style: TextStyle(
                                color:
                                    Theme.of(dialogContext).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF1D3557),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          SizedBox(
                            height: 58,

                            child: DropdownButtonFormField<String>(
                              initialValue: selectedRole,
                              dropdownColor:
                                  Theme.of(dialogContext).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF293541)
                                  : Colors.white,
                              style: const TextStyle(
                                color: Color(0xFF24364D),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              selectedItemBuilder: (BuildContext context) {
                                final List<String> roles =
                                    _sessionManager.isAdministrator
                                    ? ['Coordinador', 'Asesor']
                                    : ['Asesor'];

                                return roles.map((String role) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      role,
                                      style: const TextStyle(
                                        color: Color(0xFF24364D),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList();
                              },
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF667A90),
                                size: 24,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: Color(0xFF1976D2),
                                  size: 22,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD8E3EF),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD8E3EF),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1976D2),
                                    width: 1.6,
                                  ),
                                ),
                              ),
                              items: _sessionManager.isAdministrator
                                  ? [
                                      DropdownMenuItem<String>(
                                        value: 'Coordinador',
                                        child: Text(
                                          'Coordinador',
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                      dialogContext,
                                                    ).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFFFFFFFF)
                                                : const Color(0xFF24364D),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'Asesor',
                                        child: Text(
                                          'Asesor',
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                      dialogContext,
                                                    ).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFFFFFFFF)
                                                : const Color(0xFF24364D),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ]
                                  : [
                                      DropdownMenuItem<String>(
                                        value: 'Asesor',
                                        child: Text(
                                          'Asesor',
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                      dialogContext,
                                                    ).brightness ==
                                                    Brightness.dark
                                                ? const Color(0xFFFFFFFF)
                                                : const Color(0xFF24364D),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                              onChanged: (String? value) {
                                if (value == null) return;

                                setDialogState(() {
                                  selectedRole = value;

                                  if (selectedRole != 'Coordinador') {
                                    selectedSiteId = null;
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // =====================================================
                      // SEDE
                      // =====================================================
                      if (selectedRole == 'Coordinador')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 6,
                              ),
                              child: Text(
                                'Sede',
                                style: TextStyle(
                                  color:
                                      Theme.of(dialogContext).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFFFFFFFF)
                                      : const Color(0xFF1D3557),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),

                            SizedBox(
                              height: 58,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  final int? siteId =
                                      await _showSelectSiteDialog(
                                        dialogContext,
                                      );

                                  if (!mounted || !dialogContext.mounted) {
                                    return;
                                  }

                                  if (siteId == null) {
                                    return;
                                  }

                                  setDialogState(() {
                                    selectedSiteId = siteId;
                                    validationMessage = null;
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFD8E3EF),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_city_outlined,
                                        color: Color(0xFF1976D2),
                                        size: 23,
                                      ),

                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: Text(
                                          selectedSiteId == null
                                              ? 'Seleccionar sede'
                                              : _siteProvider.sites
                                                    .firstWhere(
                                                      (SiteModel site) =>
                                                          site.id ==
                                                          selectedSiteId,
                                                    )
                                                    .name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF24364D),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Color(0xFF667A90),
                                        size: 26,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (selectedRole == 'Coordinador')
                        const SizedBox(height: 12),

                      // =====================================================
                      // NOMBRE COMPLETO
                      // =====================================================
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 6),
                            child: Text(
                              'Nombre completo',
                              style: TextStyle(
                                color:
                                    Theme.of(dialogContext).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF1D3557),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 58,
                            child: TextField(
                              onChanged: (String value) {
                                setDialogState(() {
                                  name = value;
                                  username = _buildUsernameBase(value);
                                  validationMessage = null;
                                });
                              },
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(
                                color: Color(0xFF24364D),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: Color(0xFF1976D2),
                                  size: 22,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD8E3EF),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD8E3EF),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1976D2),
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      // =====================================================
                      // USUARIO AUTOMÁTICO
                      // =====================================================
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 6),
                            child: Text(
                              'Usuario',
                              style: TextStyle(
                                color:
                                    Theme.of(dialogContext).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF1D3557),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          Container(
                            height: 58,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F7FC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFD8E3EF),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  color: Color(0xFF1976D2),
                                  size: 22,
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Text(
                                    username.isEmpty
                                        ? 'Asignado por NANCY'
                                        : username,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: username.isEmpty
                                          ? const Color(0xFF71839A)
                                          : const Color(0xFF24364D),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Color(0xFF7A8798),
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 6),
                            child: Text(
                              'Correo',
                              style: TextStyle(
                                color:
                                    Theme.of(dialogContext).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF1D3557),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          SizedBox(
                            height: 58,
                            child: TextField(
                              onChanged: (String value) {
                                setDialogState(() {
                                  email = value;
                                  validationMessage = null;
                                });
                              },
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                color: Color(0xFF24364D),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  color: Color(0xFF1976D2),
                                  size: 22,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD8E3EF),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD8E3EF),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1976D2),
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // =====================================================
                      // TELÉFONO
                      // =====================================================
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 6),
                            child: Text(
                              'Teléfono',
                              style: TextStyle(
                                color:
                                    Theme.of(dialogContext).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFFFFFFFF)
                                    : const Color(0xFF1D3557),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 58,
                            child: TextField(
                              onChanged: (String value) {
                                setDialogState(() {
                                  phone = value;
                                  validationMessage = null;
                                });
                              },
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                color: Color(0xFF24364D),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.phone_outlined,
                                  color: Color(0xFF1976D2),
                                  size: 22,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD8E3EF),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD8E3EF),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1976D2),
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 2),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(140, 50),
                    padding: EdgeInsets.zero,
                    foregroundColor: const Color(0xFF1976D2),
                    side: const BorderSide(color: Color(0xFFBFD3E8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: () async {
                    final String cleanName = name.trim();

                    if (cleanName.isEmpty) {
                      setDialogState(() {
                        validationMessage =
                            'El nombre completo es obligatorio.';
                      });
                      return;
                    }

                    if (selectedRole == 'Coordinador' &&
                        selectedSiteId == null) {
                      setDialogState(() {
                        validationMessage =
                            'Debes seleccionar una sede para el coordinador.';
                      });
                      return;
                    }

                    final String cleanEmail = email.trim();
                    final String cleanPhone = phone.trim();

                    if (cleanEmail.isEmpty || cleanPhone.isEmpty) {
                      setDialogState(() {
                        validationMessage = 'Debes completar todos los campos.';
                      });
                      return;
                    }

                    try {
                      username = await _generateAvailableUsername(cleanName);
                    } catch (error) {
                      if (!dialogContext.mounted) return;

                      setDialogState(() {
                        validationMessage =
                            'No fue posible generar automáticamente '
                            'el nombre de usuario.';
                      });

                      return;
                    }

                    generatedActivationCode = _generateActivationCode();

                    final UserProfileModel user = UserProfileModel(
                      name: cleanName,
                      role: selectedRole,
                      username: username,
                      email: cleanEmail,
                      phone: cleanPhone,
                      siteId: selectedRole == 'Coordinador'
                          ? selectedSiteId
                          : null,

                      passwordHash: '',

                      activationCodeHash: sha256
                          .convert(utf8.encode(generatedActivationCode!))
                          .toString(),

                      mustChangePassword: true,

                      isActive: true,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    final bool success = await _userProvider.createUser(user);

                    if (!mounted || !dialogContext.mounted) return;

                    if (success) {
                      Navigator.of(dialogContext).pop(true);
                    } else {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            _userProvider.errorMessage ??
                                'No fue posible crear el usuario.',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(140, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      await _loadUsers();

      if (!mounted || generatedActivationCode == null) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (codeDialogContext) {
          return AlertDialog(
            title: Text(
              'Usuario creado',
              style: TextStyle(
                color: Theme.of(codeDialogContext).brightness == Brightness.dark
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFF162F4E),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guarda o comparte estos datos antes de cerrar '
                  'esta ventana.',
                ),
                const SizedBox(height: 16),

                Text(
                  'Usuario',
                  style: TextStyle(
                    color:
                        Theme.of(codeDialogContext).brightness ==
                            Brightness.dark
                        ? const Color(0xFFEAF2FA)
                        : const Color(0xFF647892),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                SelectableText(
                  username.trim(),
                  style: TextStyle(
                    color:
                        Theme.of(codeDialogContext).brightness ==
                            Brightness.dark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF173050),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Código de activación',
                  style: TextStyle(
                    color:
                        Theme.of(codeDialogContext).brightness ==
                            Brightness.dark
                        ? const Color(0xFFEAF2FA)
                        : const Color(0xFF647892),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  generatedActivationCode!,
                  style: TextStyle(
                    color:
                        Theme.of(codeDialogContext).brightness ==
                            Brightness.dark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF173050),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'El usuario deberá ingresar con su nombre de usuario '
                  'y este código para crear su contraseña personal.',
                ),
              ],
            ),

            actions: [
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text:
                          'Usuario: ${username.trim()}\n'
                          'Código de activación: '
                          '${generatedActivationCode!}',
                    ),
                  );

                  if (!codeDialogContext.mounted) return;

                  ScaffoldMessenger.of(codeDialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Usuario y código copiados al portapapeles.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copiar'),
              ),

              TextButton.icon(
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          'Activación de cuenta NANCY\n'
                          'Usuario: ${username.trim()}\n'
                          'Código: $generatedActivationCode\n\n'
                          'Ingresa con tu usuario y este código '
                          'para crear tu contraseña personal.',
                      subject: 'Código de activación NANCY',
                    ),
                  );
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text('Compartir'),
              ),

              FilledButton(
                onPressed: () {
                  Navigator.of(codeDialogContext).pop();
                },
                child: const Text('Entendido'),
              ),
            ],
          );
        },
      );
    }
  }

  String _normalizeUsernamePart(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _buildUsernameBase(String fullName) {
    final List<String> parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '';
    }

    final String firstName = _normalizeUsernamePart(parts.first);

    if (firstName.isEmpty) {
      return '';
    }

    if (parts.length == 1) {
      return '$firstName.ideco';
    }

    final String lastName = _normalizeUsernamePart(parts.last);

    if (lastName.isEmpty) {
      return '$firstName.ideco';
    }

    return '$firstName.$lastName.ideco';
  }

  Future<String> _generateAvailableUsername(String fullName) async {
    final String baseUsername = _buildUsernameBase(fullName);

    if (baseUsername.isEmpty) {
      throw StateError('No fue posible construir el nombre de usuario.');
    }

    String candidate = baseUsername;
    int suffix = 2;

    while (await _userProvider.usernameExists(candidate)) {
      final String baseWithoutSuffix = baseUsername.endsWith('.ideco')
          ? baseUsername.substring(0, baseUsername.length - '.ideco'.length)
          : baseUsername;

      candidate = '$baseWithoutSuffix$suffix.ideco';
      suffix++;
    }

    return candidate;
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
  // SEDE DEL COORDINADOR
  // =============================================================

  Future<int?> _showSelectSiteDialog(BuildContext parentDialogContext) async {
    if (!mounted || !parentDialogContext.mounted) {
      return null;
    }

    final SiteMunicipalityProvider relationProvider =
        SiteMunicipalityProvider();
    final LocationProvider locationProvider = LocationProvider();

    final TextEditingController siteNameController = TextEditingController();
    final TextEditingController municipalitySearchController =
        TextEditingController();

    final Set<int> selectedMunicipalityIds = <int>{};

    String siteSearch = '';
    String municipalitySearch = '';
    bool saving = false;

    // La ventana abre inmediatamente. Las ubicaciones cargan dentro del diálogo.
    final Future<void> locationsFuture = locationProvider
        .loadDepartmentsAndMunicipalities();

    try {
      return await showDialog<int>(
        context: parentDialogContext,
        builder: (siteDialogContext) {
          return StatefulBuilder(
            builder: (siteDialogContext, setSiteDialogState) {
              final String normalizedSiteSearch = _normalizeSearchText(
                siteSearch,
              );

              final List<SiteModel> activeSites = _siteProvider.sites
                  .where((SiteModel site) => site.active && site.id != null)
                  .toList();

              final List<SiteModel> matchingSites = normalizedSiteSearch.isEmpty
                  ? <SiteModel>[]
                  : activeSites
                        .where((SiteModel site) {
                          return _normalizeSearchText(
                            site.name,
                          ).contains(normalizedSiteSearch);
                        })
                        .take(5)
                        .toList();

              return AlertDialog(
                title: const Text('Sede'),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                    maxHeight: 620,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // -------------------------------------------------
                        // NOMBRE DE LA SEDE
                        // -------------------------------------------------
                        TextField(
                          controller: siteNameController,
                          enabled: !saving,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (String value) {
                            setSiteDialogState(() {
                              siteSearch = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la sede',
                            hintText: 'Escribe el nombre de la sede',
                            prefixIcon: Icon(Icons.location_city_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        // -------------------------------------------------
                        // COINCIDENCIAS DE SEDES EXISTENTES
                        // -------------------------------------------------
                        if (matchingSites.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Sedes existentes',
                            style: Theme.of(siteDialogContext)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          ...matchingSites.map((SiteModel site) {
                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              leading: Icon(
                                Icons.location_city_outlined,
                                color: Theme.of(
                                  siteDialogContext,
                                ).colorScheme.primary,
                              ),
                              title: Text(
                                site.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: const Text('Usar esta sede'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: saving
                                  ? null
                                  : () {
                                      Navigator.of(
                                        siteDialogContext,
                                      ).pop(site.id);
                                    },
                            );
                          }),
                        ],

                        const SizedBox(height: 18),

                        // -------------------------------------------------
                        // MUNICIPIOS
                        // -------------------------------------------------
                        Text(
                          'Municipios que abarca la sede',
                          style: Theme.of(siteDialogContext)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),

                        const SizedBox(height: 10),

                        // Municipios elegidos: se pueden quitar con la X.
                        if (selectedMunicipalityIds.isNotEmpty)
                          FutureBuilder<void>(
                            future: locationsFuture,
                            builder:
                                (
                                  BuildContext context,
                                  AsyncSnapshot<void> snapshot,
                                ) {
                                  if (snapshot.connectionState !=
                                      ConnectionState.done) {
                                    return const SizedBox.shrink();
                                  }

                                  final List<MunicipalityModel>
                                  allMunicipalities = locationProvider
                                      .municipalities
                                      .where(
                                        (MunicipalityModel municipality) =>
                                            municipality.id != null,
                                      )
                                      .toList();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: selectedMunicipalityIds.map((
                                        int municipalityId,
                                      ) {
                                        MunicipalityModel? municipality;

                                        for (final MunicipalityModel item
                                            in allMunicipalities) {
                                          if (item.id == municipalityId) {
                                            municipality = item;
                                            break;
                                          }
                                        }

                                        if (municipality == null) {
                                          return const SizedBox.shrink();
                                        }

                                        return Chip(
                                          label: Text(municipality.name),
                                          onDeleted: saving
                                              ? null
                                              : () {
                                                  setSiteDialogState(() {
                                                    selectedMunicipalityIds
                                                        .remove(municipalityId);
                                                  });
                                                },
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                          ),

                        FutureBuilder<void>(
                          future: locationsFuture,
                          builder:
                              (
                                BuildContext context,
                                AsyncSnapshot<void> snapshot,
                              ) {
                                if (snapshot.connectionState !=
                                    ConnectionState.done) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 18),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'No fue posible cargar los municipios.',
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }

                                final List<MunicipalityModel> municipalities =
                                    locationProvider.municipalities
                                        .where(
                                          (MunicipalityModel municipality) =>
                                              municipality.id != null,
                                        )
                                        .toList();

                                final String query = _normalizeSearchText(
                                  municipalitySearch,
                                );

                                if (query.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final List<MunicipalityModel>
                                filteredMunicipalities = municipalities
                                    .where(
                                      (MunicipalityModel municipality) =>
                                          _normalizeSearchText(
                                            municipality.name,
                                          ).contains(query),
                                    )
                                    .take(12)
                                    .toList();

                                if (filteredMunicipalities.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'No se encontró ese municipio.',
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: filteredMunicipalities.map((
                                    MunicipalityModel municipality,
                                  ) {
                                    final int municipalityId = municipality.id!;

                                    final bool selected =
                                        selectedMunicipalityIds.contains(
                                          municipalityId,
                                        );

                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        selected
                                            ? Icons.check_circle_rounded
                                            : Icons.add_circle_outline_rounded,
                                        color: selected
                                            ? Theme.of(
                                                siteDialogContext,
                                              ).colorScheme.primary
                                            : null,
                                      ),
                                      title: Text(municipality.name),
                                      trailing: selected
                                          ? IconButton(
                                              tooltip: 'Quitar municipio',
                                              onPressed: saving
                                                  ? null
                                                  : () {
                                                      setSiteDialogState(() {
                                                        selectedMunicipalityIds
                                                            .remove(
                                                              municipalityId,
                                                            );
                                                      });
                                                    },
                                              icon: const Icon(
                                                Icons.close_rounded,
                                              ),
                                            )
                                          : IconButton(
                                              tooltip: 'Agregar municipio',
                                              onPressed: saving
                                                  ? null
                                                  : () {
                                                      setSiteDialogState(() {
                                                        selectedMunicipalityIds
                                                            .add(
                                                              municipalityId,
                                                            );
                                                        municipalitySearch = '';
                                                        municipalitySearchController
                                                            .clear();
                                                      });
                                                    },
                                              icon: const Icon(
                                                Icons.add_rounded,
                                              ),
                                            ),
                                      onTap: saving
                                          ? null
                                          : () {
                                              setSiteDialogState(() {
                                                if (selected) {
                                                  selectedMunicipalityIds
                                                      .remove(municipalityId);
                                                } else {
                                                  selectedMunicipalityIds.add(
                                                    municipalityId,
                                                  );
                                                  municipalitySearch = '';
                                                  municipalitySearchController
                                                      .clear();
                                                }
                                              });
                                            },
                                    );
                                  }).toList(),
                                );
                              },
                        ),

                        // -------------------------------------------------
                        // BUSCAR MUNICIPIO
                        // -------------------------------------------------
                        const SizedBox(height: 10),

                        TextField(
                          controller: municipalitySearchController,
                          enabled: !saving,
                          onChanged: (String value) {
                            setSiteDialogState(() {
                              municipalitySearch = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Buscar municipio',
                            hintText: 'Ej. Caucasia, El Bagre, Nechí',
                            prefixIcon: Icon(Icons.search_rounded),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () {
                            Navigator.of(siteDialogContext).pop();
                          },
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            final String cleanName = siteNameController.text
                                .trim();

                            if (cleanName.isEmpty) {
                              ScaffoldMessenger.of(
                                siteDialogContext,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Escribe el nombre de la sede.',
                                  ),
                                ),
                              );
                              return;
                            }
                            // -------------------------------------------------
                            // BUSCAR SI LA SEDE YA EXISTE
                            // -------------------------------------------------
                            //
                            // Si existe, NO se crea otra.
                            // Se actualizan los municipios de esa sede
                            // y luego se devuelve su ID.
                            SiteModel? exactSite;

                            final String normalizedCleanName =
                                _normalizeSearchText(cleanName);

                            for (final SiteModel site in activeSites) {
                              if (_normalizeSearchText(site.name) ==
                                  normalizedCleanName) {
                                exactSite = site;
                                break;
                              }
                            }

                            if (exactSite?.id != null) {
                              if (selectedMunicipalityIds.isEmpty) {
                                ScaffoldMessenger.of(
                                  siteDialogContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Agrega al menos un municipio a la sede.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setSiteDialogState(() {
                                saving = true;
                              });

                              final bool relationSuccess =
                                  await relationProvider.replaceMunicipalities(
                                    siteId: exactSite!.id!,
                                    municipalityIds: selectedMunicipalityIds
                                        .toList(),
                                  );

                              if (!mounted || !siteDialogContext.mounted) {
                                return;
                              }

                              if (!relationSuccess) {
                                setSiteDialogState(() {
                                  saving = false;
                                });

                                ScaffoldMessenger.of(
                                  siteDialogContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No se pudieron asociar los municipios a la sede.',
                                    ),
                                  ),
                                );

                                return;
                              }

                              Navigator.of(siteDialogContext).pop(exactSite.id);

                              return;
                            }

                            setSiteDialogState(() {
                              saving = true;
                            });

                            final bool success = await _siteProvider.createSite(
                              name: cleanName,
                              address: null,
                            );

                            if (!mounted || !siteDialogContext.mounted) {
                              return;
                            }

                            if (!success) {
                              setSiteDialogState(() {
                                saving = false;
                              });

                              ScaffoldMessenger.of(
                                siteDialogContext,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _siteProvider.errorMessage ??
                                        'No fue posible agregar la sede.',
                                  ),
                                ),
                              );
                              return;
                            }

                            await _siteProvider.loadSites();

                            if (!mounted || !siteDialogContext.mounted) {
                              return;
                            }

                            SiteModel? createdSite;

                            for (final SiteModel site in _siteProvider.sites) {
                              if (site.id != null &&
                                  site.name.trim().toLowerCase() ==
                                      cleanName.toLowerCase()) {
                                createdSite = site;
                                break;
                              }
                            }

                            if (createdSite?.id == null) {
                              setSiteDialogState(() {
                                saving = false;
                              });

                              ScaffoldMessenger.of(
                                siteDialogContext,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'La sede fue agregada, pero no se pudo obtener su identificador.',
                                  ),
                                ),
                              );
                              return;
                            }

                            final bool relationSuccess = await relationProvider
                                .replaceMunicipalities(
                                  siteId: createdSite!.id!,
                                  municipalityIds: selectedMunicipalityIds
                                      .toList(),
                                );

                            if (!mounted || !siteDialogContext.mounted) {
                              return;
                            }

                            if (!relationSuccess) {
                              setSiteDialogState(() {
                                saving = false;
                              });

                              ScaffoldMessenger.of(
                                siteDialogContext,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'La sede fue agregada, pero no se pudieron asociar los municipios.',
                                  ),
                                ),
                              );
                              return;
                            }

                            Navigator.of(siteDialogContext).pop(createdSite.id);
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_business_outlined),
                    label: Text(saving ? 'Guardando...' : 'Agregar sede'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      relationProvider.dispose();
      locationProvider.dispose();
    }
  }

  // =============================================================
  // GENERAR CÓDIGO DE RECUPERACIÓN
  // =============================================================

  Future<void> _confirmGenerateRecoveryCode(UserProfileModel user) async {
    if (user.id == null || !mounted) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Generar código de recuperación'),
          content: Text(
            '¿Deseas generar un nuevo código de recuperación '
            'para ${user.name}?\n\n'
            'Si existe un código anterior, deberá utilizarse '
            'el nuevo código.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Generar código'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      final recoveryCode = await _userProvider.generateRecoveryCode(user.id!);

      if (!mounted) return;

      if (recoveryCode == null || recoveryCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _userProvider.errorMessage ??
                  'No fue posible generar el código de recuperación.',
            ),
          ),
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Código de recuperación generado'),
            content: SelectableText(
              'Usuario: ${user.name}\n\n'
              'Código de recuperación:\n$recoveryCode\n\n'
              'Entrega este código únicamente al usuario '
              'correspondiente.',
            ),

            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: recoveryCode));

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('Copiar código'),
              ),
              TextButton.icon(
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          'Recuperación de cuenta NANCY\n'
                          'Usuario: ${user.username}\n'
                          'Código de recuperación: $recoveryCode\n\n'
                          'Ingresa con tu usuario y este código para '
                          'establecer una nueva contraseña personal.',
                      subject: 'Código de recuperación NANCY',
                    ),
                  );
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text('Compartir'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      await _loadUsers();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar el código de recuperación: $e'),
        ),
      );
    }
  }

  // =============================================================
  // ACTIVAR / DESACTIVAR
  // =============================================================

  Future<void> _toggleUser(UserProfileModel user) async {
    if (user.id == null) return;

    final bool isAdministrator =
        user.role.trim().toLowerCase() == 'administrador';

    final bool newActiveState = !user.isActive;

    // No permitir desactivar la cuenta del administrador.
    if (isAdministrator && !newActiveState) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede desactivar la cuenta del administrador.'),
        ),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            newActiveState ? 'Activar usuario' : 'Desactivar usuario',
          ),
          content: Text(
            newActiveState
                ? '¿Deseas activar la cuenta de ${user.name}? '
                      'El usuario podrá iniciar sesión nuevamente.'
                : '¿Deseas desactivar la cuenta de ${user.name}? '
                      'El usuario no podrá iniciar sesión mientras esté desactivado.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(newActiveState ? 'Sí, activar' : 'Sí, desactivar'),
            ),
          ],
        );
      },
    );

    // Si cancela o cierra el diálogo, no se modifica nada.
    if (confirmed != true) return;

    final bool success = await _userProvider.setUserActive(
      userId: user.id!,
      active: newActiveState,
    );

    if (!mounted) return;

    if (success) {
      await _loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _userProvider.errorMessage ??
                'No fue posible cambiar el estado del usuario.',
          ),
        ),
      );
    }
  }

  // =============================================================
  // ELIMINAR USUARIO DEFINITIVAMENTE
  // =============================================================
  Future<void> _confirmDelete(UserProfileModel user) async {
    if (user.id == null || !mounted) return;

    // Utilizar el mismo Provider que carga la lista de usuarios.
    final provider = _userProvider;
    String confirmationText = '';

    try {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Eliminar usuario definitivamente'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Deseas eliminar definitivamente la cuenta de '
                    '${user.name}?\n\n'
                    'Esta acción es permanente y no se puede deshacer.',
                  ),
                  const SizedBox(height: 16),
                  const Text('Escribe ELIMINAR para confirmar:'),
                  const SizedBox(height: 8),
                  TextField(
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) {
                      confirmationText = value;
                    },
                    decoration: const InputDecoration(
                      hintText: 'ELIMINAR',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (confirmationText.trim() == 'ELIMINAR') {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
                child: const Text('Eliminar definitivamente'),
              ),
            ],
          );
        },
      );

      // Si cancela, termina sin eliminar.
      if (confirmed != true || !mounted) return;

      // Ejecutar la eliminación.
      final bool success = await provider.deleteUser(user.id!);

      if (!mounted) return;

      if (success) {
        // Actualizar la lista antes de mostrar el mensaje.
        await _loadUsers();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado definitivamente.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ?? 'No fue posible eliminar el usuario.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el usuario: $e')),
      );
    }
  }

  // =============================================================
  // COLOR SEGÚN ROL
  // =============================================================

  Color _roleColor(String role) {
    switch (role.trim().toLowerCase()) {
      case 'administrador':
        return const Color(0xFF2D8FE5);
      case 'coordinador':
        return const Color(0xFF8B5CF6);
      case 'asesor':
      case 'asistente':
        return const Color(0xFF2EAD72);
      default:
        return const Color(0xFF64748B);
    }
  }

  // =============================================================
  // NORMALIZAR TEXTO PARA BÚSQUEDAS
  // =============================================================

  String _normalizeSearchText(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ñ', 'n');
  }
}
