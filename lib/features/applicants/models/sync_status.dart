// ===============================================================
// APLICATIVO NANCY
// Estados de sincronización
// ===============================================================

enum SyncStatus {
  pendiente,
  sincronizando,
  sincronizado,
  error;

  /// Valor que se almacenará en la base de datos.
  String get value {
    switch (this) {
      case SyncStatus.pendiente:
        return 'pendiente';

      case SyncStatus.sincronizando:
        return 'sincronizando';

      case SyncStatus.sincronizado:
        return 'sincronizado';

      case SyncStatus.error:
        return 'error';
    }
  }

  /// Texto que se mostrará al usuario.
  String get label {
    switch (this) {
      case SyncStatus.pendiente:
        return 'Pendiente';

      case SyncStatus.sincronizando:
        return 'Sincronizando';

      case SyncStatus.sincronizado:
        return 'Sincronizado';

      case SyncStatus.error:
        return 'Error';
    }
  }

  /// Convierte textos existentes del aplicativo al estado correcto.
  static SyncStatus fromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'pendiente':
      case 'pending':
        return SyncStatus.pendiente;

      case 'sincronizando':
      case 'syncing':
        return SyncStatus.sincronizando;

      case 'sincronizado':
      case 'synced':
        return SyncStatus.sincronizado;

      case 'error':
        return SyncStatus.error;

      default:
        return SyncStatus.pendiente;
    }
  }
}
