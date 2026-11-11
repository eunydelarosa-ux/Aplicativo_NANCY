
 // =============================================================
 // APLICATIVO NANCY
 // Proveedor de Apariencia
 // =============================================================

import 'package:flutter/material.dart';
import 'package:nancy_app/features/session/session_manager.dart';

import '../data/services/appearance_settings_service.dart';
import '../models/appearance_settings_model.dart';

class AppearanceProvider extends ChangeNotifier {
  // =============================================================
  // INSTANCIA ÚNICA
  // =============================================================

  static final AppearanceProvider instance = AppearanceProvider._internal();

  AppearanceProvider._internal();

  // =============================================================
  // SERVICIO
  // =============================================================

  final AppearanceSettingsService _service = AppearanceSettingsService();

  // =============================================================
  // ESTADO
  // =============================================================

  AppearanceSettingsModel _settings = const AppearanceSettingsModel();

  bool _isLoading = true;

  int? _loadedUserId;

  int _loadGeneration = 0;

  // =============================================================
  // GETTERS
  // =============================================================

  AppearanceSettingsModel get settings => _settings;

  bool get isLoading => _isLoading;

  // =============================================================
  // CARGAR APARIENCIA DEL USUARIO ACTUAL
  // =============================================================

  Future<void> loadAppearance() async {
    final int generation = ++_loadGeneration;
    final int? requestedUserId = SessionManager.instance.currentUser?.id;

    _isLoading = true;
    notifyListeners();

    try {
      final AppearanceSettingsModel loadedSettings =
          await _service.loadSettings();

      // Ignorar respuestas de cargas anteriores.
      if (generation != _loadGeneration) {
        return;
      }

      // No conservar la configuración si cambió la cuenta.
      if (SessionManager.instance.currentUser?.id != requestedUserId) {
        _settings = const AppearanceSettingsModel();
        _loadedUserId = null;
        return;
      }

      _settings = loadedSettings;
      _loadedUserId = requestedUserId;
    } catch (_) {
      if (generation != _loadGeneration) {
        return;
      }

      _settings = const AppearanceSettingsModel();

      _loadedUserId =
          SessionManager.instance.currentUser?.id == requestedUserId
          ? requestedUserId
          : null;
    } finally {
      if (generation == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // =============================================================
  // CAMBIAR TEMA
  // =============================================================

  Future<void> setThemeMode(String themeMode) async {
    // Aceptar solamente valores permitidos.
    if (themeMode != 'system' &&
        themeMode != 'light' &&
        themeMode != 'dark') {
      return;
    }

    final int? currentUserId = SessionManager.instance.currentUser?.id;

    // No guardar ni mantener una preferencia compartida sin usuario.
    if (currentUserId == null) {
      _settings = const AppearanceSettingsModel();
      _loadedUserId = null;
      notifyListeners();
      return;
    }

    // Asegurarse de haber cargado la configuración de esta cuenta.
    if (_loadedUserId != currentUserId) {
      await loadAppearance();

      if (SessionManager.instance.currentUser?.id != currentUserId ||
          _loadedUserId != currentUserId) {
        return;
      }
    }

    // Actualizar la interfaz.
    _settings = _settings.copyWith(themeMode: themeMode);
    notifyListeners();

    // Guardar en la clave correspondiente al usuario actual.
    await _service.saveThemeMode(themeMode);
  }
}
