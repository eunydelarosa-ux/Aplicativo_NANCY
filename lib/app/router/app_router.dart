// =============================================================
// APLICATIVO NANCY
// Configuración de Rutas
// =============================================================

import 'package:go_router/go_router.dart';

import 'package:nancy_app/features/splash/presentation/pages/splash_page.dart';
import 'package:nancy_app/features/auth/presentation/pages/login_page.dart';
import 'package:nancy_app/features/auth/presentation/pages/create_password_page.dart';
import 'package:nancy_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:nancy_app/features/calendar/presentation/pages/calendar_page.dart';

import 'package:nancy_app/features/profile/presentation/pages/profile_page.dart';
import 'package:nancy_app/features/configuration/presentation/pages/configuration_page.dart';
import 'package:nancy_app/features/configuration/presentation/pages/preferences_page.dart';
import 'package:nancy_app/features/configuration/presentation/pages/appearance_page.dart';
import 'package:nancy_app/features/configuration/presentation/pages/notifications_page.dart';
import 'package:nancy_app/features/catalogs/presentation/pages/catalogs_page.dart';

import 'package:nancy_app/features/authorization/presentation/pages/administration_page.dart';
import 'package:nancy_app/features/authorization/presentation/pages/user_management_page.dart';
import 'package:nancy_app/features/sites/presentation/pages/site_management_page.dart';
import 'package:nancy_app/features/applicants/presentation/pages/applicant_register_page.dart';
import 'package:nancy_app/features/applicants/presentation/pages/applicant_list_page.dart';
import 'package:nancy_app/features/applicants/presentation/pages/applicant_detail_page.dart';
import 'package:nancy_app/features/applicants/presentation/pages/sync_page.dart';
import 'package:nancy_app/features/history/presentation/pages/history_page.dart';

import 'package:nancy_app/features/exports/presentation/pages/export_page.dart';
import 'package:nancy_app/features/backup/presentation/pages/backup_page.dart';
import 'package:nancy_app/features/reports/presentation/pages/reports_page.dart';

// =============================================================
// PAPELERA
// =============================================================
import 'package:nancy_app/features/trash/presentation/pages/trash_page.dart';

import 'package:nancy_app/features/applicants/models/applicant_model.dart';
import 'package:nancy_app/features/session/session_manager.dart';
import 'package:nancy_app/features/authorization/services/role_permission_service.dart';

// =============================================================
// ROUTER PRINCIPAL
// =============================================================

final GoRouter appRouter = GoRouter(
  initialLocation: '/',

  redirect: (context, state) {
    final SessionManager session = SessionManager.instance;

    final bool hasSession = session.hasActiveSession;
    final bool mustChangePassword =
        session.currentUser?.mustChangePassword ?? false;
    final bool isProfileComplete =
        session.currentUser?.isProfileComplete ?? false;

    final String location = state.uri.path;

    final bool isLoginRoute = location == '/login';
    final bool isSplashRoute = location == '/';
    final bool isCreatePasswordRoute = location == '/create-password';
    final bool isProfileRoute = location == '/profile';

    // ---------------------------------------------------------
    // SIN SESIÓN
    // ---------------------------------------------------------
    if (!hasSession) {
      if (isLoginRoute || isSplashRoute) {
        return null;
      }

      return '/login';
    }

    // ---------------------------------------------------------
    // SESIÓN ACTIVA
    // ---------------------------------------------------------
    final bool isAdministrator =
        session.currentUser?.role.trim().toLowerCase() == 'administrador';

    // ---------------------------------------------------------
    // USUARIO NO ADMINISTRADOR DEBE CREAR CONTRASEÑA
    // ---------------------------------------------------------
    if (mustChangePassword && !isAdministrator) {
      if (isCreatePasswordRoute) {
        return null;
      }

      return '/create-password';
    }

    // ---------------------------------------------------------
    // USUARIO NO ADMINISTRADOR DEBE COMPLETAR SU PERFIL
    // ---------------------------------------------------------
    if (!isAdministrator && !isProfileComplete) {
      if (isProfileRoute) {
        return null;
      }

      return '/profile';
    }

    // ---------------------------------------------------------
    // EVITAR VOLVER AL LOGIN CON UNA SESIÓN ACTIVA
    // ---------------------------------------------------------
    if (isLoginRoute || isCreatePasswordRoute) {
      return '/dashboard';
    }

    // ---------------------------------------------------------
    // PERMISOS DEL USUARIO ACTUAL
    // ---------------------------------------------------------
    final permissions = const RolePermissionService().getPermissions(
      session.currentRole,
    );

    bool allowed = true;

    switch (location) {
      case '/administration':
        allowed = permissions.canAccessAdministration;
        break;

      case '/administration/users':
        allowed =
            permissions.canAccessAdministration && permissions.canManageUsers;
        break;

      case '/administration/sites':
        allowed =
            permissions.canAccessAdministration && permissions.canManageSites;
        break;

      case '/register-applicant':
        allowed = permissions.canRegisterApplicants;
        break;

      case '/applicants':
      case '/applicant-detail':
        allowed = permissions.canViewApplicants;
        break;

      case '/edit-applicant':
        allowed =
            permissions.canViewApplicants && permissions.canRegisterApplicants;
        break;

      case '/sync':
      case '/history':
        allowed = permissions.canSynchronize;
        break;

      case '/backup':
        allowed = permissions.canAccessBackup;
        break;

      case '/reports':
        allowed = permissions.canAccessReports;
        break;

      case '/exports':
      case '/trash':
        allowed = permissions.canViewApplicants;
        break;
    }

    // ---------------------------------------------------------
    // BLOQUEAR ACCESOS SIN PERMISO
    // ---------------------------------------------------------
    if (!allowed) {
      return '/dashboard';
    }

    return null;
  },

  routes: [
    // =========================================================
    // SPLASH
    // =========================================================
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),

    // =========================================================
    // LOGIN
    // =========================================================
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),

    // =========================================================
    // CREAR CONTRASEÑA PERSONAL
    // =========================================================
    GoRoute(
      path: '/create-password',
      builder: (context, state) => const CreatePasswordPage(),
    ),
    // =========================================================
    // DASHBOARD
    // =========================================================
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),

    // =========================================================
    // CALENDARIO
    // =========================================================
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const CalendarPage(),
    ),

    // =========================================================
    // PERFIL
    // =========================================================
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),

    // =========================================================
    // CATÁLOGOS
    // =========================================================
    GoRoute(
      path: '/catalogs',
      builder: (context, state) => const CatalogsPage(),
    ),

    // =========================================================
    // ADMINISTRACIÓN
    // =========================================================
    GoRoute(
      path: '/administration',
      builder: (context, state) => const AdministrationPage(),
    ),
    GoRoute(
      path: '/administration/users',
      builder: (context, state) => const UserManagementPage(),
    ),
    GoRoute(
      path: '/administration/sites',
      builder: (context, state) => const SiteManagementPage(),
    ),

    // =========================================================
    // CONFIGURACIÓN
    // =========================================================
    GoRoute(
      path: '/configuration',
      builder: (context, state) => const ConfigurationPage(),
    ),

    GoRoute(
      path: '/configuration/preferences',
      builder: (context, state) => const PreferencesPage(),
    ),

    GoRoute(
      path: '/configuration/appearance',
      builder: (context, state) => const AppearancePage(),
    ),

    GoRoute(
      path: '/configuration/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),

    // =========================================================
    // ASPIRANTES
    // =========================================================
    GoRoute(
      path: '/register-applicant',
      builder: (context, state) => const ApplicantRegisterPage(),
    ),

    GoRoute(
      path: '/applicants',
      builder: (context, state) {
        final initialSearch = state.uri.queryParameters['search'];

        return ApplicantListPage(initialSearch: initialSearch);
      },
    ),

    GoRoute(
      path: '/applicant-detail',
      builder: (context, state) {
        final applicant = state.extra as ApplicantModel;

        return ApplicantDetailPage(applicant: applicant);
      },
    ),

    GoRoute(
      path: '/edit-applicant',
      builder: (context, state) {
        final applicant = state.extra as ApplicantModel;

        return ApplicantRegisterPage(applicant: applicant);
      },
    ),

    GoRoute(path: '/sync', builder: (context, state) => const SyncPage()),

    GoRoute(path: '/history', builder: (context, state) => const HistoryPage()),

    // =========================================================
    // EXPORTACIONES
    // =========================================================
    GoRoute(path: '/exports', builder: (context, state) => const ExportPage()),

    // =========================================================
    // COPIAS DE SEGURIDAD
    // =========================================================
    GoRoute(path: '/backup', builder: (context, state) => const BackupPage()),

    // =========================================================
    // ESTADÍSTICAS / REPORTES
    // =========================================================
    GoRoute(path: '/reports', builder: (context, state) => const ReportsPage()),

    // =========================================================
    // PAPELERA
    // =========================================================
    GoRoute(path: '/trash', builder: (context, state) => const TrashPage()),
  ],
);
