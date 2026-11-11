// ===============================================================
// APLICATIVO NANCY
// Provider de Copias de Seguridad
// ===============================================================

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../session/session_manager.dart';
import '../data/services/backup_service.dart';
import '../models/backup_applicant_model.dart';
import '../models/backup_model.dart';

class BackupProvider extends ChangeNotifier {
  // =============================================================
  // SERVICIO
  // =============================================================

  final BackupService _backupService;

  BackupProvider({BackupService? backupService})
    : _backupService = backupService ?? BackupService() {
    _activeSessionKey = _currentSessionKey;
  }

  // =============================================================
  // IDENTIDAD DE LA SESIÓN
  // =============================================================

  String _activeSessionKey = '';

  String get _currentSessionKey {
    final SessionManager session = SessionManager.instance;
    final currentUser = session.currentUser;

    if (currentUser == null) {
      return 'sin-sesion';
    }

    final String userId = currentUser.id?.toString() ?? 'sin-id';
    final String role = currentUser.role.trim().toLowerCase();

    return '$userId|$role';
  }

  bool get _isSameSessionScope => _activeSessionKey == _currentSessionKey;

  bool get _hasBackupPermission {
    final SessionManager session = SessionManager.instance;

    if (!session.hasActiveSession) {
      return false;
    }

    if (session.isAdministrator) {
      return true;
    }

    return session.isCoordinator && session.currentUser?.id != null;
  }

  // =============================================================
  // CAMBIO DE SESIÓN Y LIMPIEZA DE DATOS
  // =============================================================

  void _clearSessionData() {
    _isCreatingBackup = false;
    _isSendingBackup = false;
    _isLoadingBackups = false;
    _isDeletingBackup = false;
    _isLoadingBackupData = false;

    _backupApplicants = [];
    _backups = [];
    _lastBackup = null;
    _errorMessage = null;
  }

  void _synchronizeSessionScope() {
    final String currentKey = _currentSessionKey;

    if (_activeSessionKey == currentKey) {
      return;
    }

    _activeSessionKey = currentKey;

    _clearSessionData();

    notifyListeners();
  }

  bool _prepareAuthorizedOperation() {
    _synchronizeSessionScope();

    try {
      _ensureBackupPermission();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  void _ensureBackupPermission() {
    final SessionManager session = SessionManager.instance;

    if (!session.hasActiveSession) {
      throw StateError(
        'Debes iniciar sesión para utilizar las copias de seguridad.',
      );
    }

    if (session.isAdministrator) {
      return;
    }

    if (session.isCoordinator && session.currentUser?.id != null) {
      return;
    }

    throw StateError(
      'Tu rol no tiene permiso para utilizar las copias de seguridad.',
    );
  }

  bool _requestSessionIsCurrent(String requestKey) {
    return _currentSessionKey == requestKey;
  }

  // =============================================================
  // ESTADO
  // =============================================================

  bool _isCreatingBackup = false;
  bool _isSendingBackup = false;
  bool _isLoadingBackups = false;
  bool _isDeletingBackup = false;

  bool _isLoadingBackupData = false;

  List<BackupApplicantModel> _backupApplicants = [];
  List<BackupModel> _backups = [];

  String? _errorMessage;
  File? _lastBackup;

  // =============================================================
  // GETTERS
  // =============================================================

  bool get isCreatingBackup =>
      _isSameSessionScope && _hasBackupPermission ? _isCreatingBackup : false;

  bool get isSendingBackup =>
      _isSameSessionScope && _hasBackupPermission ? _isSendingBackup : false;

  bool get isLoadingBackups =>
      _isSameSessionScope && _hasBackupPermission ? _isLoadingBackups : false;

  bool get isDeletingBackup =>
      _isSameSessionScope && _hasBackupPermission ? _isDeletingBackup : false;

  bool get isLoadingBackupData => _isSameSessionScope && _hasBackupPermission
      ? _isLoadingBackupData
      : false;

  List<BackupApplicantModel> get backupApplicants {
    if (!_isSameSessionScope || !_hasBackupPermission) {
      return const <BackupApplicantModel>[];
    }

    return List.unmodifiable(_backupApplicants);
  }

  List<BackupModel> get backups {
    if (!_isSameSessionScope || !_hasBackupPermission) {
      return const <BackupModel>[];
    }

    return List.unmodifiable(_backups);
  }

  String? get errorMessage {
    if (!_isSameSessionScope) {
      return null;
    }

    return _errorMessage;
  }

  File? get lastBackup {
    if (!_isSameSessionScope || !_hasBackupPermission) {
      return null;
    }

    return _lastBackup;
  }

  // =============================================================
  // CREAR COPIA DE SEGURIDAD
  // =============================================================

  Future<bool> createBackup() async {
    if (!_prepareAuthorizedOperation()) {
      return false;
    }

    final String requestKey = _currentSessionKey;

    _isCreatingBackup = true;
    _errorMessage = null;
    _lastBackup = null;

    notifyListeners();

    try {
      final File backupFile = await _backupService.createBackup();

      if (!_requestSessionIsCurrent(requestKey)) {
        _synchronizeSessionScope();
        return false;
      }

      _lastBackup = backupFile;

      final List<BackupModel> backups = await _backupService.getBackups();

      if (!_requestSessionIsCurrent(requestKey)) {
        _synchronizeSessionScope();
        return false;
      }

      _backups = backups;

      return true;
    } catch (error) {
      if (!_requestSessionIsCurrent(requestKey)) {
        _synchronizeSessionScope();
        return false;
      }

      _errorMessage = error.toString();

      return false;
    } finally {
      if (_requestSessionIsCurrent(requestKey)) {
        _isCreatingBackup = false;
        notifyListeners();
      } else {
        _synchronizeSessionScope();
      }
    }
  }

  // =============================================================
  // CARGAR HISTORIAL DE COPIAS
  // =============================================================

  Future<void> loadBackups() async {
    if (!_prepareAuthorizedOperation()) {
      return;
    }

    final String requestKey = _currentSessionKey;

    _isLoadingBackups = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final List<BackupModel> backups = await _backupService.getBackups();

      if (!_requestSessionIsCurrent(requestKey)) {
        _synchronizeSessionScope();
        return;
      }

      _backups = backups;
    } catch (error) {
      if (!_requestSessionIsCurrent(requestKey)) {
        _synchronizeSessionScope();
        return;
      }

      _errorMessage = error.toString();
    } finally {
      if (_requestSessionIsCurrent(requestKey)) {
        _isLoadingBackups = false;
        notifyListeners();
      } else {
        _synchronizeSessionScope();
      }
    }
  }

  // =============================================================
  // ELIMINAR COPIA DE SEGURIDAD
  // =============================================================

  Future<bool> deleteBackup(BackupModel backup) async {
    if (!_prepareAuthorizedOperation()) {
      return false;
    }

    final String requestKey = _currentSessionKey;

    _isDeletingBackup = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _backupService.deleteBackup(backup.path);

      if (!_requestSessionIsCurrent(requestKey)) {
        _synchronizeSessionScope();
        return false;
      }

      _backups.removeWhere((BackupModel item) => item.path == backup.path);

      return true;
    } catch (error) {
      if (!_requestSessionIsCurrent(requestKey)) {
        _synchronizeSessionScope();
        return false;
      }

      _errorMessage = error.toString();

      return false;
    } finally {
      if (_requestSessionIsCurrent(requestKey)) {
        _isDeletingBackup = false;
        notifyListeners();
      } else {
        _synchronizeSessionScope();
      }
    }
  }

  // =============================================================
  // PREPARAR COPIA PARA COMPARTIR
  // =============================================================

  Future<File?> prepareBackupForSharing(BackupModel backup) async {
    if (!_prepareAuthorizedOperation()) {
      return null;
    }

    final String requestKey = _currentSessionKey;

    _isSendingBackup = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final File zipFile = await _backupService.createBackupZip(backup);

      if (!_requestSessionIsCurrent(requestKey)) {
        _synchronizeSessionScope();
        return null;
      }

      return zipFile;
    } catch (error) {
      if (!_requestSessionIsCurrent(requestKey)) {
        _synchronizeSessionScope();
        return null;
      }

      _errorMessage = error.toString();

      return null;
    } finally {
      if (_requestSessionIsCurrent(requestKey)) {
        _isSendingBackup = false;
        notifyListeners();
      } else {
        _synchronizeSessionScope();
      }
    }
  }

  // =============================================================
  // CARGAR DATOS DE UNA COPIA DE SEGURIDAD
  // =============================================================

  Future<bool> loadBackupApplicants(BackupModel backup) async {
    if (!_prepareAuthorizedOperation()) {
      return false;
    }

    final String requestKey = _currentSessionKey;

    _isLoadingBackupData = true;
    _errorMessage = null;
    _backupApplicants = [];

    notifyListeners();

    try {
      final List<BackupApplicantModel> applicants = await _backupService
          .getBackupApplicants(backup.path);

      if (!_requestSessionIsCurrent(requestKey)) {
        _synchronizeSessionScope();
        return false;
      }

      _backupApplicants = applicants;

      return true;
    } catch (error) {
      if (!_requestSessionIsCurrent(requestKey)) {
        _synchronizeSessionScope();
        return false;
      }

      _errorMessage = error.toString();
      _backupApplicants = [];

      return false;
    } finally {
      if (_requestSessionIsCurrent(requestKey)) {
        _isLoadingBackupData = false;
        notifyListeners();
      } else {
        _synchronizeSessionScope();
      }
    }
  }

  // =============================================================
  // LIMPIAR ERROR
  // =============================================================

  void clearError() {
    _synchronizeSessionScope();

    _errorMessage = null;

    notifyListeners();
  }
}
