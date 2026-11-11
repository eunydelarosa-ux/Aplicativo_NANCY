// ===============================================================
// APLICATIVO NANCY
// Motor de sincronización de aspirantes
// ===============================================================
import '../models/applicant_model.dart';
import '../repositories/applicant_repository.dart';
import 'connectivity_service.dart';
import 'sync_result.dart';

class SyncService {
  final ApplicantRepository _repository;
  final Future<void> Function(ApplicantModel applicant) _sendApplicant;
  final ConnectivityService _connectivityService;

  static bool _isSynchronizingGlobally = false;
  bool _automaticSyncEnabled = false;

  SyncService({
    ApplicantRepository? repository,
    required this._sendApplicant,
    ConnectivityService? connectivityService,
  }) : _repository = repository ?? ApplicantRepository(),
       _connectivityService = connectivityService ?? ConnectivityService();

  bool get isSynchronizing => _isSynchronizingGlobally;

  bool get automaticSyncEnabled => _automaticSyncEnabled;

  Future<List<ApplicantModel>> getPendingApplicants() async {
    return _repository.getPendingSyncApplicants();
  }

  Future<SyncResult> synchronize() async {
    final DateTime startedAt = DateTime.now();

    if (_isSynchronizingGlobally) {
      return SyncResult(
        total: 0,
        successful: 0,
        failed: 0,
        startedAt: startedAt,
        finishedAt: DateTime.now(),
        skippedBecauseAlreadyRunning: true,
      );
    }

    _isSynchronizingGlobally = true;

    int successful = 0;
    int failed = 0;
    int total = 0;
    String? fatalError;

    try {
      final bool hasConnection = await _connectivityService.checkConnection();

      if (!hasConnection) {
        fatalError =
            'No hay conexión a internet. Los aspirantes permanecen guardados en el dispositivo.';
      } else {
        final List<ApplicantModel> applicants = await _repository
            .getPendingSyncApplicants();

        total = applicants.length;

        for (final ApplicantModel applicant in applicants) {
          final int markedSyncing = await _repository.markApplicantSyncing(
            applicant.id,
          );

          if (markedSyncing == 0) {
            continue;
          }

          try {
            await _sendApplicant(applicant);

            final int markedSynced = await _repository.markApplicantSynced(
              applicant.id,
            );

            if (markedSynced > 0) {
              successful++;
            } else {
              failed++;

              await _repository.markApplicantSyncError(
                applicant.id,
                'No fue posible confirmar el estado sincronizado.',
              );
            }
          } catch (error) {
            failed++;

            final String message = error.toString().trim().isEmpty
                ? 'Error desconocido durante la sincronización.'
                : error.toString().trim();

            await _repository.markApplicantSyncError(applicant.id, message);
          }
        }
      }
    } catch (error) {
      fatalError = error.toString().trim().isEmpty
          ? 'Error general durante la sincronización.'
          : error.toString().trim();
    } finally {
      _isSynchronizingGlobally = false;
    }

    return SyncResult(
      total: total,
      successful: successful,
      failed: failed,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
      fatalError: fatalError,
    );
  }

  Future<SyncResult> retry() async {
    return synchronize();
  }

  Future<void> startAutomaticSync({required bool enabled}) async {
    _automaticSyncEnabled = enabled;

    await _connectivityService.stopMonitoring();

    if (!enabled) {
      return;
    }

    await _connectivityService.startMonitoring(
      onReconnected: _synchronizeAutomatically,
    );

    if (_connectivityService.isConnected) {
      await _synchronizeAutomatically();
    }
  }

  Future<void> setAutomaticSyncEnabled(bool enabled) async {
    await startAutomaticSync(enabled: enabled);
  }

  Future<void> _synchronizeAutomatically() async {
    if (!_automaticSyncEnabled) {
      return;
    }

    if (!_connectivityService.isConnected) {
      return;
    }

    await synchronize();
  }

  Future<void> dispose() async {
    await _connectivityService.dispose();
  }
}
