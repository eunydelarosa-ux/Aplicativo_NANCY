// ===============================================================
// APLICATIVO NANCY
// Provider de la Papelera
// ===============================================================
//
// Responsabilidad:
// - Cargar aspirantes eliminados.
// - Restaurar aspirantes.
// - Eliminar aspirantes definitivamente.
// - Vaciar la papelera.
// - Mantener el contador de elementos eliminados.
//
// Flujo:
//
// TrashPage
//     ↓
// TrashProvider
//     ↓
// ApplicantRepository
//     ↓
// SQLite
// ===============================================================

import 'package:flutter/foundation.dart';

import '../../applicants/models/applicant_model.dart';
import '../../applicants/repositories/applicant_repository.dart';

class TrashProvider extends ChangeNotifier {
  TrashProvider({ApplicantRepository? repository})
    : _repository = repository ?? ApplicantRepository();

  final ApplicantRepository _repository;

  // =============================================================
  // ESTADO
  // =============================================================

  List<ApplicantModel> _deletedApplicants = [];

  bool _isLoading = false;

  String? _errorMessage;

  // =============================================================
  // LECTURA DEL ESTADO
  // =============================================================

  List<ApplicantModel> get deletedApplicants => _deletedApplicants;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  int get trashCount => _deletedApplicants.length;

  bool get isEmpty => _deletedApplicants.isEmpty;

  // =============================================================
  // CARGAR PAPELERA
  // =============================================================

  Future<void> loadTrash() async {
    _setLoading(true);

    try {
      _errorMessage = null;

      _deletedApplicants = await _repository.getDeletedApplicants();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'No fue posible cargar la papelera.';

      if (kDebugMode) {
        debugPrint('Error al cargar papelera: $e');
      }

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // RESTAURAR ASPIRANTE
  // =============================================================

  Future<bool> restoreApplicant(String id) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final int affectedRows = await _repository.restoreApplicant(id);

      if (affectedRows == 0) {
        _errorMessage = 'No fue posible restaurar el aspirante.';

        notifyListeners();

        return false;
      }

      await loadTrash();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible restaurar el aspirante.';

      if (kDebugMode) {
        debugPrint('Error al restaurar aspirante: $e');
      }

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // ELIMINAR DEFINITIVAMENTE
  // =============================================================

  Future<bool> deletePermanently(String id) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final int affectedRows = await _repository.deleteApplicantPermanently(id);

      if (affectedRows == 0) {
        _errorMessage =
            'No fue posible eliminar definitivamente '
            'el aspirante.';

        notifyListeners();

        return false;
      }

      await loadTrash();

      return true;
    } catch (e) {
      _errorMessage =
          'No fue posible eliminar definitivamente '
          'el aspirante.';

      if (kDebugMode) {
        debugPrint('Error al eliminar definitivamente: $e');
      }

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // VACIAR PAPELERA
  // =============================================================

  Future<bool> emptyTrash() async {
    _setLoading(true);

    try {
      _errorMessage = null;

      await _repository.emptyTrash();

      _deletedApplicants = [];

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible vaciar la papelera.';

      if (kDebugMode) {
        debugPrint('Error al vaciar papelera: $e');
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
  // CONTROL INTERNO DE CARGA
  // =============================================================

  void _setLoading(bool value) {
    _isLoading = value;

    notifyListeners();
  }
}
