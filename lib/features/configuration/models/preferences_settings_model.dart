// =============================================================
// APLICATIVO NANCY
// Modelo de preferencias de la aplicación
// =============================================================

class PreferencesSettingsModel {
  // ===========================================================
  // CONFIGURACIONES
  // ===========================================================

  /// Sincroniza automáticamente cuando vuelva la conexión.
  final bool automaticSync;

  /// Guarda borradores de formularios.
  final bool saveDrafts;

  /// Muestra una confirmación antes de realizar eliminaciones.
  final bool confirmDeletion;

  /// Muestra mensajes de confirmación después de guardar.
  final bool showSuccessMessages;

  // ===========================================================
  // CONSTRUCTOR
  // ===========================================================

  const PreferencesSettingsModel({
    this.automaticSync = true,
    this.saveDrafts = true,
    this.confirmDeletion = true,
    this.showSuccessMessages = true,
  });

  // ===========================================================
  // COPIA DEL MODELO
  // ===========================================================

  PreferencesSettingsModel copyWith({
    bool? automaticSync,
    bool? saveDrafts,
    bool? confirmDeletion,
    bool? showSuccessMessages,
  }) {
    return PreferencesSettingsModel(
      automaticSync: automaticSync ?? this.automaticSync,
      saveDrafts: saveDrafts ?? this.saveDrafts,
      confirmDeletion: confirmDeletion ?? this.confirmDeletion,
      showSuccessMessages: showSuccessMessages ?? this.showSuccessMessages,
    );
  }
}
