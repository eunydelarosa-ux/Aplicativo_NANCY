// =============================================================
// APLICATIVO NANCY
// Modelo de configuración de notificaciones
// =============================================================

class NotificationsSettingsModel {
  // ===========================================================
  // CONFIGURACIÓN
  // ===========================================================

  /// Indica si las notificaciones están activadas.
  final bool enabled;

  /// Indica si las notificaciones pueden emitir sonido.
  final bool sound;

  /// Indica si las notificaciones pueden utilizar vibración.
  final bool vibration;

  // ===========================================================
  // CONSTRUCTOR
  // ===========================================================

  const NotificationsSettingsModel({
    this.enabled = true,
    this.sound = true,
    this.vibration = true,
  });

  // ===========================================================
  // COPIAR CONFIGURACIÓN
  // ===========================================================

  NotificationsSettingsModel copyWith({
    bool? enabled,
    bool? sound,
    bool? vibration,
  }) {
    return NotificationsSettingsModel(
      enabled: enabled ?? this.enabled,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
    );
  }
}
