// ===============================================================
// APLICATIVO NANCY
// Resultado de una ejecución de sincronización
// ===============================================================

class SyncResult {
  final int total;
  final int successful;
  final int failed;
  final DateTime startedAt;
  final DateTime finishedAt;
  final bool skippedBecauseAlreadyRunning;
  final String? fatalError;

  const SyncResult({
    required this.total,
    required this.successful,
    required this.failed,
    required this.startedAt,
    required this.finishedAt,
    this.skippedBecauseAlreadyRunning = false,
    this.fatalError,
  });

  int get processed => successful + failed;

  bool get hasErrors => failed > 0 || fatalError != null;

  bool get isSuccessful =>
      !skippedBecauseAlreadyRunning && fatalError == null && failed == 0;

  Duration get duration => finishedAt.difference(startedAt);
}
