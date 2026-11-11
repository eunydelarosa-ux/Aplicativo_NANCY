// =============================================================
// APLICATIVO NANCY
// Provider de preferencias
// =============================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/preferences_settings_model.dart';
import '../data/services/app_preferences_service.dart';

class PreferencesProvider extends ChangeNotifier {
  // ===========================================================
  // CLAVES ANTERIORES (COMPATIBILIDAD)
  // ===========================================================

  static const String _automaticSyncKey = 'preferences_automatic_sync';

  static const String _confirmDeletionKey = 'preferences_confirm_deletion';

  static const String _showSuccessMessagesKey =
      'preferences_show_success_messages';

  // ===========================================================
  // SERVICIO
  // ===========================================================

  final AppPreferencesService _preferencesService = AppPreferencesService();

  // ===========================================================
  // ESTADO
  // ===========================================================

  PreferencesSettingsModel _settings = const PreferencesSettingsModel();

  bool _isLoading = true;

  // ===========================================================
  // GETTERS
  // ===========================================================

  PreferencesSettingsModel get settings => _settings;

  bool get isLoading => _isLoading;

  // ===========================================================
  // CARGAR PREFERENCIAS
  // ===========================================================

  Future<void> loadPreferences() async {
    _isLoading = true;
    notifyListeners();

    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();

      final bool automaticSync = preferences.containsKey(_automaticSyncKey)
          ? preferences.getBool(_automaticSyncKey) ?? true
          : await _preferencesService.getAutoSync();

      final bool confirmDeletion = preferences.containsKey(_confirmDeletionKey)
          ? preferences.getBool(_confirmDeletionKey) ?? true
          : await _preferencesService.getConfirmDelete();

      final bool showSuccessMessages =
          preferences.containsKey(_showSuccessMessagesKey)
          ? preferences.getBool(_showSuccessMessagesKey) ?? true
          : await _preferencesService.getShowSaveConfirmation();

      final bool saveDrafts = await _preferencesService.getSaveDrafts();

      _settings = PreferencesSettingsModel(
        automaticSync: automaticSync,
        saveDrafts: saveDrafts,
        confirmDeletion: confirmDeletion,
        showSuccessMessages: showSuccessMessages,
      );

      // Migrar los valores anteriores al almacenamiento del servicio.
      await _preferencesService.setAutoSync(automaticSync);
      await _preferencesService.setConfirmDelete(confirmDeletion);
      await _preferencesService.setShowSaveConfirmation(showSuccessMessages);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================
  // SINCRONIZACIÓN AUTOMÁTICA
  // ===========================================================

  Future<void> setAutomaticSync(bool value) async {
    _settings = _settings.copyWith(automaticSync: value);
    notifyListeners();

    await _preferencesService.setAutoSync(value);
  }

  // ===========================================================
  // GUARDAR BORRADORES
  // ===========================================================

  Future<void> setSaveDrafts(bool value) async {
    _settings = _settings.copyWith(saveDrafts: value);
    notifyListeners();

    await _preferencesService.setSaveDrafts(value);
  }

  // ===========================================================
  // CONFIRMAR ELIMINACIÓN
  // ===========================================================

  Future<void> setConfirmDeletion(bool value) async {
    _settings = _settings.copyWith(confirmDeletion: value);
    notifyListeners();

    await _preferencesService.setConfirmDelete(value);
  }

  // ===========================================================
  // MENSAJES DE ÉXITO
  // ===========================================================

  Future<void> setShowSuccessMessages(bool value) async {
    _settings = _settings.copyWith(showSuccessMessages: value);
    notifyListeners();

    await _preferencesService.setShowSaveConfirmation(value);
  }
}
