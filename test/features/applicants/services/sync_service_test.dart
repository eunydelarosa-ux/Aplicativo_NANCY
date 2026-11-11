import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nancy_app/features/applicants/models/applicant_model.dart';
import 'package:nancy_app/features/applicants/repositories/applicant_repository.dart';
import 'package:nancy_app/features/applicants/services/sync_service.dart';

void main() {
  group('SyncService', () {
    test('PENDIENTE -> SINCRONIZANDO -> SINCRONIZADO', () async {
      final FakeApplicantRepository repository = FakeApplicantRepository(
        _createApplicant(),
      );

      final SyncService service = SyncService(
        repository: repository,
        sendApplicant: (_) async {},
      );

      final result = await service.synchronize();

      expect(result.total, 1);
      expect(result.successful, 1);
      expect(result.failed, 0);
      expect(result.isSuccessful, true);

      expect(repository.applicant.syncStatus, 'sincronizado');

      expect(repository.applicant.syncAttempts, 1);

      expect(repository.applicant.lastSyncAttempt, isNotNull);

      expect(repository.applicant.syncedAt, isNotNull);

      expect(repository.applicant.lastSyncError, isNull);
    });

    test('PENDIENTE -> SINCRONIZANDO -> ERROR', () async {
      final FakeApplicantRepository repository = FakeApplicantRepository(
        _createApplicant(),
      );

      final SyncService service = SyncService(
        repository: repository,
        sendApplicant: (_) async {
          throw Exception('Fallo de prueba');
        },
      );

      final result = await service.synchronize();

      expect(result.total, 1);
      expect(result.successful, 0);
      expect(result.failed, 1);
      expect(result.hasErrors, true);

      expect(repository.applicant.syncStatus, 'error');

      expect(repository.applicant.syncAttempts, 1);

      expect(repository.applicant.lastSyncError, contains('Fallo de prueba'));

      expect(repository.applicant.syncedAt, isNull);
    });

    test('No permite dos sincronizaciones simultáneas', () async {
      final FakeApplicantRepository repository = FakeApplicantRepository(
        _createApplicant(),
      );

      final Completer<void> started = Completer<void>();
      final Completer<void> release = Completer<void>();

      final SyncService service = SyncService(
        repository: repository,
        sendApplicant: (_) async {
          if (!started.isCompleted) {
            started.complete();
          }

          await release.future;
        },
      );

      final Future<dynamic> firstSynchronization = service.synchronize();

      await started.future;

      final resultSecondSynchronization = await service.synchronize();

      expect(resultSecondSynchronization.skippedBecauseAlreadyRunning, true);

      release.complete();

      final firstResult = await firstSynchronization;

      expect(firstResult.successful, 1);
    });
  });
}

ApplicantModel _createApplicant() {
  final DateTime now = DateTime.now();

  return ApplicantModel(
    id: 'TEST-SYNC-001',
    documentType: 'CC',
    documentNumber: '123456789',
    firstName: 'Prueba',
    lastName: 'Sincronizacion',
    birthDate: DateTime(2000, 1, 1),
    gender: 'Femenino',
    schooling: 'Bachiller',
    program: 'Programa de prueba',
    phone: '3000000000',
    email: 'prueba@nancy.local',
    address: 'Dirección de prueba',
    department: 'Antioquia',
    municipality: 'Caucasia',
    corregimiento: '',
    village: '',
    responsibleName: 'Usuario prueba',
    responsibleRole: 'Asesor',
    responsibleCedula: '1111111111',
    observations: '',
    syncStatus: 'pendiente',
    syncAttempts: 0,
    createdAt: now,
    updatedAt: now,
    isDeleted: false,
  );
}

class FakeApplicantRepository extends ApplicantRepository {
  ApplicantModel applicant;

  FakeApplicantRepository(this.applicant);

  @override
  Future<List<ApplicantModel>> getPendingSyncApplicants() async {
    final String status = applicant.syncStatus.toLowerCase().trim();

    if (applicant.isDeleted) {
      return [];
    }

    if (status == 'pendiente' || status == 'error') {
      return [applicant];
    }

    return [];
  }

  @override
  Future<int> markApplicantSyncing(String id) async {
    if (applicant.id != id || applicant.isDeleted) {
      return 0;
    }

    applicant = applicant.copyWith(
      syncStatus: 'sincronizando',
      syncAttempts: applicant.syncAttempts + 1,
      lastSyncAttempt: DateTime.now(),
      clearLastSyncError: true,
    );

    return 1;
  }

  @override
  Future<int> markApplicantSynced(String id) async {
    if (applicant.id != id || applicant.isDeleted) {
      return 0;
    }

    applicant = applicant.copyWith(
      syncStatus: 'sincronizado',
      syncedAt: DateTime.now(),
      clearLastSyncError: true,
    );

    return 1;
  }

  @override
  Future<int> markApplicantSyncError(String id, String errorMessage) async {
    if (applicant.id != id || applicant.isDeleted) {
      return 0;
    }

    applicant = applicant.copyWith(
      syncStatus: 'error',
      lastSyncError: errorMessage,
      clearSyncedAt: true,
    );

    return 1;
  }
}
