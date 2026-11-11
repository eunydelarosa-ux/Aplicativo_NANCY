// =============================================================
// APLICATIVO NANCY
// Modelo de configuración de apariencia
// =============================================================

class AppearanceSettingsModel {
  // ===========================================================
  // TEMA
  // ===========================================================

  /// system = según el dispositivo
  /// light  = claro
  /// dark   = oscuro
  final String themeMode;

  // ===========================================================
  // CONSTRUCTOR
  // ===========================================================

  const AppearanceSettingsModel({this.themeMode = 'system'});

  // ===========================================================
  // COPIAR CONFIGURACIÓN
  // ===========================================================

  AppearanceSettingsModel copyWith({String? themeMode}) {
    return AppearanceSettingsModel(themeMode: themeMode ?? this.themeMode);
  }
}
