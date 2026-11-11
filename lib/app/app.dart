// =============================================================
// APLICATIVO NANCY
// Aplicación principal
// =============================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

import '../features/applicants/providers/applicant_provider.dart';
import '../features/backup/providers/backup_provider.dart';
import '../features/configuration/data/services/app_preferences_service.dart';
import '../features/configuration/providers/appearance_provider.dart';
import '../features/sites/providers/site_municipality_provider.dart';
import '../features/sites/providers/site_provider.dart';
import '../features/location/providers/location_provider.dart';
import '../features/profile/providers/user_profile_provider.dart';

class NancyApp extends StatefulWidget {
  const NancyApp({super.key});

  @override
  State<NancyApp> createState() => _NancyAppState();
}

class _NancyAppState extends State<NancyApp> {
  // ===========================================================
  // PROVIDER GLOBAL DE APARIENCIA
  // ===========================================================

  final AppearanceProvider _appearanceProvider = AppearanceProvider.instance;

  // ===========================================================
  // SINCRONIZACIÓN AUTOMÁTICA GLOBAL
  // ===========================================================

  final ApplicantProvider _automaticSyncProvider = ApplicantProvider();

  final AppPreferencesService _preferencesService = AppPreferencesService();

  final InternetConnection _internetConnection = InternetConnection();

  StreamSubscription<InternetStatus>? _internetSubscription;

  bool _wasConnected = false;

  bool _automaticSyncRunning = false;

  // ===========================================================
  // CICLO DE VIDA
  // ===========================================================

  @override
  void initState() {
    super.initState();

    _appearanceProvider.loadAppearance();

    _startAutomaticSynchronization();
  }

  // ===========================================================
  // INICIAR MONITOREO GLOBAL DE INTERNET
  // ===========================================================

  Future<void> _startAutomaticSynchronization() async {
    try {
      final bool initialConnection =
          await _internetConnection.hasInternetAccess;

      _wasConnected = initialConnection;

      _internetSubscription = _internetConnection.onStatusChange.listen((
        InternetStatus status,
      ) async {
        final bool connected = status == InternetStatus.connected;

        if (connected == _wasConnected) {
          return;
        }

        final bool wasDisconnected = !_wasConnected;

        _wasConnected = connected;

        if (!wasDisconnected || !connected) {
          return;
        }

        await _runAutomaticSynchronization();
      });

      if (_wasConnected) {
        await _runAutomaticSynchronization();
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Error iniciando monitoreo automático: $error');
      }
    }
  }

  // ===========================================================
  // EJECUTAR SINCRONIZACIÓN AUTOMÁTICA
  // ===========================================================

  Future<void> _runAutomaticSynchronization() async {
    if (_automaticSyncRunning) {
      return;
    }

    final bool automaticSyncEnabled = await _preferencesService.getAutoSync();

    if (!automaticSyncEnabled) {
      return;
    }

    final bool connected = await _internetConnection.hasInternetAccess;

    if (!connected) {
      return;
    }

    _automaticSyncRunning = true;

    try {
      final result = await _automaticSyncProvider.synchronizeApplicants();

      if (kDebugMode) {
        debugPrint(
          'Sincronización automática: '
          'total=${result.total}, '
          'exitosos=${result.successful}, '
          'errores=${result.failed}',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Error en sincronización automática: $error');
      }
    } finally {
      _automaticSyncRunning = false;
    }
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // =====================================================
        // PROVIDER DE COPIAS DE SEGURIDAD
        // =====================================================
        ChangeNotifierProvider(create: (_) => BackupProvider()),

        // =====================================================
        // PROVIDERS DE SEDES
        // =====================================================
        ChangeNotifierProvider(create: (_) => SiteProvider()),

        ChangeNotifierProvider(create: (_) => SiteMunicipalityProvider()),

        // =====================================================
        // PROVIDER DE UBICACIONES
        // =====================================================
        ChangeNotifierProvider(create: (_) => LocationProvider()),

        // =====================================================
        // PROVIDER DEL PERFIL DEL USUARIO
        // =====================================================
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ],
      child: AnimatedBuilder(
        animation: _appearanceProvider,
        builder: (context, child) {
          return MaterialApp.router(
            title: 'NANCY',

            debugShowCheckedModeBanner: false,

            theme: AppTheme.lightTheme,

            darkTheme: AppTheme.darkTheme,

            themeMode: _getThemeMode(),

            // =================================================
            // IDIOMA DE LA APLICACIÓN
            // =================================================
            localizationsDelegates: GlobalMaterialLocalizations.delegates,

            supportedLocales: const [Locale('es', 'CO')],

            routerConfig: appRouter,
          );
        },
      ),
    );
  }

  // ===========================================================
  // CONVERTIR CONFIGURACIÓN A THEMEMODE
  // ===========================================================

  ThemeMode _getThemeMode() {
    switch (_appearanceProvider.settings.themeMode) {
      case 'light':
        return ThemeMode.light;

      case 'dark':
        return ThemeMode.dark;

      case 'system':
      default:
        // NANCY usa el modo claro por defecto,
        // aunque el teléfono esté configurado en oscuro.
        return ThemeMode.light;
    }
  }

  // ===========================================================
  // LIBERAR RECURSOS
  // ===========================================================

  @override
  void dispose() {
    unawaited(_internetSubscription?.cancel());

    _automaticSyncProvider.dispose();

    super.dispose();
  }
}
