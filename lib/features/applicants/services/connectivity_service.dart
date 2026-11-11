import 'dart:async';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService {
  final InternetConnection _internetConnection;

  StreamSubscription<InternetStatus>? _subscription;

  bool _isConnected = false;

  ConnectivityService({InternetConnection? internetConnection})
    : _internetConnection = internetConnection ?? InternetConnection();

  bool get isConnected => _isConnected;

  Future<bool> checkConnection() async {
    _isConnected = await _internetConnection.hasInternetAccess;
    return _isConnected;
  }

  Future<void> startMonitoring({
    required Future<void> Function() onReconnected,
  }) async {
    await stopMonitoring();

    await checkConnection();

    bool wasConnected = _isConnected;

    _subscription = _internetConnection.onStatusChange.listen((
      InternetStatus status,
    ) async {
      final bool connected = status == InternetStatus.connected;

      final bool reconnected = !wasConnected && connected;

      if (connected == _isConnected) {
        return;
      }

      _isConnected = connected;
      wasConnected = connected;

      if (reconnected) {
        await onReconnected();
      }
    });
  }

  Future<void> stopMonitoring() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> dispose() async {
    await stopMonitoring();
  }
}
