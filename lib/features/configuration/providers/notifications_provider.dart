// =============================================================
// APLICATIVO NANCY
// Proveedor de configuración de notificaciones
// =============================================================

import 'package:flutter/material.dart';

import '../data/services/notifications_settings_service.dart';
import '../models/notifications_settings_model.dart';

class NotificationsProvider extends ChangeNotifier {
  // ===========================================================
  // SERVICIO
  // ===========================================================

  final NotificationsSettingsService _service = NotificationsSettingsService();

  // ===========================================================
  // ESTADO
  // ===========================================================

  NotificationsSettingsModel _settings = const NotificationsSettingsModel();

  bool _isLoading = true;

  // ===========================================================
  // GETTERS
  // ===========================================================

  NotificationsSettingsModel get settings => _settings;

  bool get isLoading => _isLoading;

  // ===========================================================
  // CARGAR CONFIGURACIÓN
  // ===========================================================

  Future<void> loadSettings() async {
    _isLoading = true;

    notifyListeners();

    try {
      _settings = await _service.loadSettings();
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ===========================================================
  // ACTIVAR / DESACTIVAR NOTIFICACIONES
  // ===========================================================

  Future<void> setEnabled(bool value) async {
    _settings = _settings.copyWith(enabled: value);

    notifyListeners();

    await _service.saveEnabled(value);
  }

  // ===========================================================
  // ACTIVAR / DESACTIVAR SONIDO
  // ===========================================================

  Future<void> setSound(bool value) async {
    _settings = _settings.copyWith(sound: value);

    notifyListeners();

    await _service.saveSound(value);
  }

  // ===========================================================
  // ACTIVAR / DESACTIVAR VIBRACIÓN
  // ===========================================================

  Future<void> setVibration(bool value) async {
    _settings = _settings.copyWith(vibration: value);

    notifyListeners();

    await _service.saveVibration(value);
  }

  // ===========================================================
  // RESTABLECER CONFIGURACIÓN
  // ===========================================================

  Future<void> resetToDefaults() async {
    await _service.resetToDefaults();

    _settings = const NotificationsSettingsModel();

    notifyListeners();
  }
}
