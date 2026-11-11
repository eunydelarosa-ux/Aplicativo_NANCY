// ===============================================================
// APLICATIVO NANCY
// Provider de relación Sede - Municipio
// ===============================================================

import 'package:flutter/foundation.dart';

import '../repositories/site_municipality_repository.dart';

class SiteMunicipalityProvider extends ChangeNotifier {
  SiteMunicipalityProvider({SiteMunicipalityRepository? repository})
    : _repository = repository ?? SiteMunicipalityRepository();

  final SiteMunicipalityRepository _repository;

  // =============================================================
  // ESTADO
  // =============================================================

  List<int> _municipalityIds = [];

  bool _isLoading = false;

  String? _errorMessage;

  // =============================================================
  // LECTURA DEL ESTADO
  // =============================================================

  List<int> get municipalityIds => List.unmodifiable(_municipalityIds);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // =============================================================
  // CARGAR MUNICIPIOS DE UNA SEDE
  // =============================================================

  Future<void> loadMunicipalitiesBySite(int siteId) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      _municipalityIds = await _repository.getMunicipalityIdsBySite(siteId);

      notifyListeners();
    } catch (e) {
      _errorMessage = 'No fue posible cargar los municipios de la sede.';

      if (kDebugMode) {
        debugPrint('Error al cargar municipios de la sede: $e');
      }

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // ASOCIAR MUNICIPIO A SEDE
  // =============================================================

  Future<bool> addMunicipality({
    required int siteId,
    required int municipalityId,
  }) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      await _repository.addMunicipalityToSite(siteId, municipalityId);

      await _reloadMunicipalities(siteId);

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible asociar el municipio a la sede.';

      if (kDebugMode) {
        debugPrint('Error al asociar municipio a sede: $e');
      }

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // QUITAR MUNICIPIO DE SEDE
  // =============================================================

  Future<bool> removeMunicipality({
    required int siteId,
    required int municipalityId,
  }) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      await _repository.removeMunicipalityFromSite(siteId, municipalityId);

      await _reloadMunicipalities(siteId);

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible quitar el municipio de la sede.';

      if (kDebugMode) {
        debugPrint('Error al quitar municipio de sede: $e');
      }

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // REEMPLAZAR MUNICIPIOS DE UNA SEDE
  // =============================================================

  Future<bool> replaceMunicipalities({
    required int siteId,
    required List<int> municipalityIds,
  }) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      await _repository.replaceMunicipalitiesForSite(siteId, municipalityIds);

      await _reloadMunicipalities(siteId);

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible actualizar los municipios de la sede.';

      if (kDebugMode) {
        debugPrint('Error al actualizar municipios de sede: $e');
      }

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // COMPROBAR RELACIÓN
  // =============================================================

  Future<bool> isMunicipalityAssigned({
    required int siteId,
    required int municipalityId,
  }) async {
    try {
      return await _repository.isMunicipalityAssignedToSite(
        siteId,
        municipalityId,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al comprobar relación sede-municipio: $e');
      }

      return false;
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
  // RECARGAR MUNICIPIOS
  // =============================================================

  Future<void> _reloadMunicipalities(int siteId) async {
    _municipalityIds = await _repository.getMunicipalityIdsBySite(siteId);

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
