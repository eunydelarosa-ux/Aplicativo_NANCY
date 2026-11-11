// ===============================================================
// APLICATIVO NANCY
// Provider de Veredas o Corregimientos
// ===============================================================

import 'package:flutter/foundation.dart';

import '../repositories/village_repository.dart';

class VillageProvider extends ChangeNotifier {
  VillageProvider({VillageRepository? repository})
    : _repository = repository ?? VillageRepository();

  final VillageRepository _repository;

  // =============================================================
  // ESTADO
  // =============================================================

  List<String> _villages = [];

  bool _isLoading = false;

  String? _errorMessage;

  // =============================================================
  // GETTERS
  // =============================================================

  List<String> get villages => List.unmodifiable(_villages);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // =============================================================
  // CARGAR TODOS
  // =============================================================

  Future<void> loadVillages() async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _villages = await _repository.getAllVillages();
    } catch (error) {
      _errorMessage = 'No fue posible cargar las veredas o corregimientos.';
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // =============================================================
  // BUSCAR
  // =============================================================
  //
  // Se utilizará mientras el usuario escribe en el campo.
  //
  // Ejemplo:
  //
  // Usuario escribe:
  // "Puerto"
  //
  // El Provider devuelve:
  //
  // - Puerto Claver
  // - Puerto López
  // =============================================================

  Future<void> searchVillages(String query) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _villages = await _repository.searchVillages(query);
    } catch (error) {
      _errorMessage = 'No fue posible buscar las veredas o corregimientos.';
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // =============================================================
  // OBTENER O CREAR
  // =============================================================
  //
  // Si existe:
  //
  // → Se utiliza la existente.
  //
  // Si no existe:
  //
  // → Se guarda automáticamente.
  // → Se agrega a la lista.
  //
  // Devuelve el nombre que debe guardarse en el aspirante.
  // =============================================================

  Future<String?> getOrCreateVillage(String name) async {
    final String value = name.trim();

    if (value.isEmpty) {
      return null;
    }

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final String? village = await _repository.getOrCreateVillage(value);

      // ---------------------------------------------------------
      // RECARGAR LA LISTA
      // ---------------------------------------------------------

      _villages = await _repository.getAllVillages();

      return village;
    } catch (error) {
      _errorMessage = 'No fue posible guardar la vereda o corregimiento.';

      return null;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // =============================================================
  // LIMPIAR ERROR
  // =============================================================

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }
}
