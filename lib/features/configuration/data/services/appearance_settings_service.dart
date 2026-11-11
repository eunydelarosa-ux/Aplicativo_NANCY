
 // =============================================================
 // APLICATIVO NANCY
 // Servicio de almacenamiento de apariencia
 // =============================================================

import 'package:shared_preferences/shared_preferences.dart';
import 'package:nancy_app/features/session/session_manager.dart';

import '../../models/appearance_settings_model.dart';

class AppearanceSettingsService {
  // =============================================================
  // CLAVE DE ALMACENAMIENTO POR USUARIO
  // =============================================================

  String? _getThemeModeKey() {
    final int? userId = SessionManager.instance.currentUser?.id;

    if (userId == null) {
      return null;
    }

    return 'appearance_theme_mode_user_$userId';
  }

  // =============================================================
  // CARGAR CONFIGURACIÓN
  // =============================================================

  Future<AppearanceSettingsModel> loadSettings() async {
    final String? key = _getThemeModeKey();

    // Sin un identificador de usuario no compartimos preferencias.
    if (key == null) {
      return const AppearanceSettingsModel();
    }

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    final String themeMode =
        preferences.getString(key) ?? 'system';

    // Aceptar solamente valores permitidos.
    if (themeMode != 'system' &&
        themeMode != 'light' &&
        themeMode != 'dark') {
      return const AppearanceSettingsModel();
    }

    return AppearanceSettingsModel(themeMode: themeMode);
  }

  // =============================================================
  // GUARDAR TEMA
  // =============================================================

  Future<void> saveThemeMode(String themeMode) async {
    if (themeMode != 'system' &&
        themeMode != 'light' &&
        themeMode != 'dark') {
      return;
    }

    final String? key = _getThemeModeKey();

    // No guardar una preferencia global si no hay usuario identificado.
    if (key == null) {
      return;
    }

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(key, themeMode);
  }
}
