// ===============================================================
// APLICATIVO NANCY
// Provider de Aspirantes
// ===============================================================

import 'package:flutter/foundation.dart';

import '../models/applicant_model.dart';
import '../repositories/applicant_repository.dart';
import '../services/sync_result.dart';
import '../services/sync_service.dart';
import '../../session/session_manager.dart';

class ApplicantProvider extends ChangeNotifier {
  ApplicantProvider({ApplicantRepository? repository, SyncService? syncService})
    : _repository = repository ?? ApplicantRepository(),
      _syncService =
          syncService ?? SyncService(sendApplicant: _sendApplicantToCentral);

  final ApplicantRepository _repository;
  final SyncService _syncService;

  static Future<void> _sendApplicantToCentral(ApplicantModel applicant) async {
    throw StateError(
      'La conexión con el sistema central aún no está configurada.',
    );
  }
  // ===============================================================
  // ESTADO
  // ===============================================================

  List<ApplicantModel> _applicants = [];

  bool _isLoading = false;

  String? _errorMessage;

  // ===============================================================
  // LECTURA DEL ESTADO
  // ===============================================================

  List<ApplicantModel> get applicants {
    final SessionManager session = SessionManager.instance;
    final int? currentUserId = session.currentUser?.id;

    if (currentUserId == null) {
      return [];
    }

    if (session.isAdministrator) {
      return List<ApplicantModel>.unmodifiable(_applicants);
    }

    if (session.isCoordinator || session.isAdviser) {
      return _applicants
          .where((applicant) => applicant.createdByUserId == currentUserId)
          .toList(growable: false);
    }

    return [];
  }

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  int get totalApplicants => applicants.length;

  int get pendingSyncCount {
    return applicants.where((applicant) {
      return applicant.syncStatus.toLowerCase().trim() == 'pendiente';
    }).length;
  }

  int get syncingCount {
    return applicants.where((applicant) {
      return applicant.syncStatus.toLowerCase().trim() == 'sincronizando';
    }).length;
  }

  int get syncedCount {
    return applicants.where((applicant) {
      return applicant.syncStatus.toLowerCase().trim() == 'sincronizado' ||
          applicant.syncStatus.toLowerCase().trim() == 'synced';
    }).length;
  }

  int get syncErrorCount {
    return applicants.where((applicant) {
      return applicant.syncStatus.toLowerCase().trim() == 'error';
    }).length;
  }
  // ===============================================================
  // CARGAR ASPIRANTES ACTIVOS
  // ===============================================================

  Future<void> loadApplicants() async {
    _setLoading(true);

    try {
      _errorMessage = null;

      _applicants = await _repository.getAllApplicants();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'No fue posible cargar los aspirantes.';

      if (kDebugMode) {
        debugPrint('Error al cargar aspirantes: $e');
      }

      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ===============================================================
  // GUARDAR ASPIRANTE
  // ===============================================================

  Future<bool> addApplicant(ApplicantModel applicant) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      await _repository.insertApplicant(applicant);

      // Volvemos a cargar únicamente los aspirantes activos.
      _applicants = await _repository.getAllApplicants();

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible guardar el aspirante.';

      if (kDebugMode) {
        debugPrint('Error al guardar aspirante: $e');
      }

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ===============================================================
  // ACTUALIZAR ASPIRANTE
  // ===============================================================

  Future<bool> updateApplicant(ApplicantModel applicant) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final int affectedRows = await _repository.updateApplicant(applicant);

      if (affectedRows == 0) {
        _errorMessage = 'No fue posible actualizar el aspirante.';

        notifyListeners();

        return false;
      }

      // Recargamos la lista de aspirantes activos.
      _applicants = await _repository.getAllApplicants();

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible actualizar el aspirante.';

      if (kDebugMode) {
        debugPrint('Error al actualizar aspirante: $e');
      }

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ===============================================================
  // MOVER ASPIRANTE A PAPELERA
  // ===============================================================

  Future<bool> moveToTrash(String id) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final int affectedRows = await _repository.moveToTrash(id);

      // Si SQLite no modificó ningún registro,
      // consideramos que la operación no fue exitosa.
      if (affectedRows == 0) {
        _errorMessage = 'No fue posible mover el aspirante a la papelera.';

        notifyListeners();

        return false;
      }

      // El aspirante ahora tiene is_deleted = 1,
      // por lo tanto ya no aparecerá en la lista normal.
      _applicants = await _repository.getAllApplicants();

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'No fue posible mover el aspirante a la papelera.';

      if (kDebugMode) {
        debugPrint('Error al mover aspirante a papelera: $e');
      }

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ===============================================================
  // ELIMINAR ASPIRANTE
  // ===============================================================

  Future<bool> deleteApplicant(String id) async {
    return moveToTrash(id);
  }

  // ===============================================================
  // SINCRONIZACIÓN MANUAL
  // ===============================================================

  Future<SyncResult> synchronizeApplicants() async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final SyncResult result = await _syncService.synchronize();

      // Recargamos los aspirantes para reflejar inmediatamente
      // los nuevos estados de sincronización.
      _applicants = await _repository.getAllApplicants();

      if (result.fatalError != null) {
        _errorMessage = result.fatalError;
      } else if (result.failed > 0) {
        _errorMessage =
            '${result.failed} aspirante(s) presentaron error '
            'durante la sincronización.';
      }

      notifyListeners();

      return result;
    } catch (e) {
      _errorMessage = 'No fue posible ejecutar la sincronización.';

      if (kDebugMode) {
        debugPrint('Error al sincronizar aspirantes: $e');
      }

      notifyListeners();

      return SyncResult(
        total: 0,
        successful: 0,
        failed: 0,
        startedAt: DateTime.now(),
        finishedAt: DateTime.now(),
        fatalError: _errorMessage,
      );
    } finally {
      _setLoading(false);
    }
  }

  // ===============================================================
  // REINTENTAR SINCRONIZACIÓN
  // ===============================================================

  Future<SyncResult> retrySynchronization() async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final SyncResult result = await _syncService.retry();

      _applicants = await _repository.getAllApplicants();

      if (result.fatalError != null) {
        _errorMessage = result.fatalError;
      } else if (result.failed > 0) {
        _errorMessage =
            '${result.failed} aspirante(s) presentaron error '
            'durante el reintento.';
      }

      notifyListeners();

      return result;
    } catch (e) {
      _errorMessage = 'No fue posible reintentar la sincronización.';

      if (kDebugMode) {
        debugPrint('Error al reintentar sincronización: $e');
      }

      notifyListeners();

      return SyncResult(
        total: 0,
        successful: 0,
        failed: 0,
        startedAt: DateTime.now(),
        finishedAt: DateTime.now(),
        fatalError: _errorMessage,
      );
    } finally {
      _setLoading(false);
    }
  }

  // ===============================================================
  // OBTENER ASPIRANTE POR ID
  // ===============================================================

  Future<ApplicantModel?> getApplicantById(String id) async {
    try {
      return await _repository.getApplicantById(id);
    } catch (e) {
      _errorMessage = 'No fue posible consultar el aspirante.';

      if (kDebugMode) {
        debugPrint('Error al consultar aspirante: $e');
      }

      notifyListeners();

      return null;
    }
  }

  // ===============================================================
  // LIMPIAR MENSAJE DE ERROR
  // ===============================================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ===============================================================
  // CONTROL INTERNO DE CARGA
  // ===============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
