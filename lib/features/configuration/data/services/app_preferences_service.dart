// =============================================================
// APLICATIVO NANCY
// Servicio de preferencias de la aplicación
// =============================================================

import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  // =============================================================
  // CLAVES DE ALMACENAMIENTO
  // =============================================================

  static const String _autoSyncKey = 'preference_auto_sync';

  static const String _saveDraftsKey = 'preference_save_drafts';

  static const String _confirmDeleteKey = 'preference_confirm_delete';

  static const String _showSaveConfirmationKey =
      'preference_show_save_confirmation';

  // =============================================================
  // VALORES PREDETERMINADOS
  // =============================================================

  static const bool defaultAutoSync = true;

  static const bool defaultSaveDrafts = true;

  static const bool defaultConfirmDelete = true;

  static const bool defaultShowSaveConfirmation = true;

  // =============================================================
  // SINCRONIZACIÓN AUTOMÁTICA
  // =============================================================

  Future<bool> getAutoSync() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_autoSyncKey) ?? defaultAutoSync;
  }

  Future<void> setAutoSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_autoSyncKey, value);
  }

  // =============================================================
  // GUARDAR BORRADORES
  // =============================================================

  Future<bool> getSaveDrafts() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_saveDraftsKey) ?? defaultSaveDrafts;
  }

  Future<void> setSaveDrafts(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_saveDraftsKey, value);
  }

  // =============================================================
  // CONFIRMAR ELIMINACIÓN
  // =============================================================

  Future<bool> getConfirmDelete() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_confirmDeleteKey) ?? defaultConfirmDelete;
  }

  Future<void> setConfirmDelete(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_confirmDeleteKey, value);
  }

  // =============================================================
  // CONFIRMACIÓN AL GUARDAR
  // =============================================================

  Future<bool> getShowSaveConfirmation() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_showSaveConfirmationKey) ??
        defaultShowSaveConfirmation;
  }

  Future<void> setShowSaveConfirmation(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_showSaveConfirmationKey, value);
  }

  // =============================================================
  // RESTABLECER PREFERENCIAS
  // =============================================================

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_autoSyncKey, defaultAutoSync);

    await prefs.setBool(_saveDraftsKey, defaultSaveDrafts);

    await prefs.setBool(_confirmDeleteKey, defaultConfirmDelete);

    await prefs.setBool(_showSaveConfirmationKey, defaultShowSaveConfirmation);
  }
}
