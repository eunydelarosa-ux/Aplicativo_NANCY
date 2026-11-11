// =============================================================
// APLICATIVO NANCY
// Servicio de almacenamiento de notificaciones
// =============================================================

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/notifications_settings_model.dart';

class NotificationsSettingsService {
  // ===========================================================
  // CLAVES DE ALMACENAMIENTO
  // ===========================================================

  static const String _enabledKey = 'notifications_enabled';

  static const String _soundKey = 'notifications_sound';

  static const String _vibrationKey = 'notifications_vibration';

  // ===========================================================
  // CARGAR CONFIGURACIÓN
  // ===========================================================

  Future<NotificationsSettingsModel> loadSettings() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    final bool enabled = preferences.getBool(_enabledKey) ?? true;

    final bool sound = preferences.getBool(_soundKey) ?? true;

    final bool vibration = preferences.getBool(_vibrationKey) ?? true;

    return NotificationsSettingsModel(
      enabled: enabled,
      sound: sound,
      vibration: vibration,
    );
  }

  // ===========================================================
  // GUARDAR NOTIFICACIONES
  // ===========================================================

  Future<void> saveEnabled(bool value) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_enabledKey, value);
  }

  // ===========================================================
  // GUARDAR SONIDO
  // ===========================================================

  Future<void> saveSound(bool value) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_soundKey, value);
  }

  // ===========================================================
  // GUARDAR VIBRACIÓN
  // ===========================================================

  Future<void> saveVibration(bool value) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_vibrationKey, value);
  }

  // ===========================================================
  // RESTABLECER VALORES
  // ===========================================================

  Future<void> resetToDefaults() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_enabledKey, true);

    await preferences.setBool(_soundKey, true);

    await preferences.setBool(_vibrationKey, true);
  }
}
