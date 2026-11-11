// ===============================================================
// APLICATIVO NANCY
// Provider de Sedes
// ===============================================================

import 'package:flutter/foundation.dart';

import '../models/site_model.dart';
import '../repositories/site_repository.dart';

class SiteProvider extends ChangeNotifier {
  SiteProvider({SiteRepository? repository})
    : _repository = repository ?? SiteRepository();

  final SiteRepository _repository;

  // =============================================================
  // ESTADO
  // =============================================================

  List<SiteModel> _sites = [];

  bool _isLoading = false;

  String? _errorMessage;

  // =============================================================
  // LECTURA DEL ESTADO
  // =============================================================

  List<SiteModel> get sites => List.unmodifiable(_sites);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // =============================================================
  // CARGAR SEDES
  // =============================================================

  Future<void> loadSites({bool onlyActive = false}) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      _sites = await _repository.getSites(onlyActive: onlyActive);

      notifyListeners();
    } catch (e) {
      _errorMessage = 'No fue posible cargar las sedes.';

      if (kDebugMode) {
        debugPrint('Error al cargar sedes: $e');
      }

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // CREAR SEDE
  // =============================================================

  Future<bool> createSite({required String name, String? address}) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final DateTime now = DateTime.now();

      final SiteModel site = SiteModel(
        name: name.trim(),
        address: address?.trim().isEmpty == true ? null : address?.trim(),
        active: true,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.insertSite(site);

      await _reloadSites();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible crear la sede.';

      if (kDebugMode) {
        debugPrint('Error al crear sede: $e');
      }

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // ACTUALIZAR SEDE
  // =============================================================

  Future<bool> updateSite({required SiteModel site}) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final SiteModel updatedSite = site.copyWith(updatedAt: DateTime.now());

      await _repository.updateSite(updatedSite);

      await _reloadSites();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible actualizar la sede.';

      if (kDebugMode) {
        debugPrint('Error al actualizar sede: $e');
      }

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // ACTIVAR / DESACTIVAR SEDE
  // =============================================================

  Future<bool> setSiteActive({
    required int siteId,
    required bool active,
  }) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      await _repository.setSiteActive(siteId, active);

      await _reloadSites();

      return true;
    } catch (e) {
      _errorMessage = active
          ? 'No fue posible activar la sede.'
          : 'No fue posible desactivar la sede.';

      if (kDebugMode) {
        debugPrint('Error al cambiar estado de sede: $e');
      }

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // ELIMINAR SEDE
  // =============================================================

  Future<bool> deleteSite(int siteId) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      await _repository.deleteSite(siteId);

      await _reloadSites();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible eliminar la sede.';

      if (kDebugMode) {
        debugPrint('Error al eliminar sede: $e');
      }

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // LIMPIAR ERROR
  // =============================================================

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }

  // =============================================================
  // RECARGAR SEDES
  // =============================================================

  Future<void> _reloadSites() async {
    _sites = await _repository.getSites();

    notifyListeners();
  }

  // =============================================================
  // CONTROL INTERNO DE CARGA
  // =============================================================

  void _setLoading(bool value) {
    _isLoading = value;

    notifyListeners();
  }
}
