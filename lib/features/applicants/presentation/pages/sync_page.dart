// =============================================================
// APLICATIVO NANCY
// Página - Sincronización
// =============================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../../../history/presentation/pages/history_page.dart';

import '../../models/applicant_model.dart';
import '../../providers/applicant_provider.dart';
import '../../repositories/applicant_repository.dart';
import '../../services/sync_result.dart';

import 'applicant_detail_page.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // =============================================================
  // PROVIDER
  // =============================================================

  final ApplicantProvider _applicantProvider = ApplicantProvider();

  // =============================================================
  // HISTORIAL DE SINCRONIZACIÓN
  // =============================================================

  final ApplicantRepository _applicantRepository = ApplicantRepository();

  int _syncedCount = 0;
  DateTime? _lastSynchronization;

  // =============================================================
  // CONEXIÓN A INTERNET
  // =============================================================

  final InternetConnection _internetConnection = InternetConnection();

  StreamSubscription<InternetStatus>? _internetSubscription;

  bool _isConnected = false;
  bool _checkingConnection = true;
  bool _isSynchronizing = false;

  // =============================================================
  // CICLO DE VIDA
  // =============================================================

  @override
  void initState() {
    super.initState();

    _loadApplicants();
    _startInternetMonitoring();
  }

  // =============================================================
  // CARGAR ASPIRANTES
  // =============================================================

  Future<void> _loadApplicants() async {
    await _applicantProvider.loadApplicants();
    await _loadSyncHistorySummary();

    if (mounted) {
      setState(() {});
    }
  }

  // =============================================================
  // CARGAR RESUMEN DEL HISTORIAL
  // =============================================================

  Future<void> _loadSyncHistorySummary() async {
    try {
      final List<Map<String, dynamic>> rows = await _applicantRepository
          .getSyncHistory();

      int successfulCount = 0;
      DateTime? lastSynchronization;

      for (final Map<String, dynamic> row in rows) {
        final String status = (row['status'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        final DateTime? syncedAt = DateTime.tryParse(
          (row['synced_at'] ?? '').toString(),
        );

        final bool successful =
            status == 'sincronizado' ||
            status == 'sincronizados' ||
            status == 'synced';

        if (!successful) {
          continue;
        }

        successfulCount++;

        if (syncedAt != null &&
            (lastSynchronization == null ||
                syncedAt.isAfter(lastSynchronization))) {
          lastSynchronization = syncedAt;
        }
      }

      if (!mounted) return;

      setState(() {
        _syncedCount = successfulCount;
        _lastSynchronization = lastSynchronization;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _syncedCount = 0;
        _lastSynchronization = null;
      });

      if (kDebugMode) {
        debugPrint('Error cargando resumen del historial: $error');
      }
    }
  }

  // =============================================================
  // SINCRONIZACIÓN MANUAL
  // =============================================================

  Future<void> _synchronizeManually() async {
    if (_isSynchronizing) {
      return;
    }

    if (!_isConnected) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sin conexión a Internet. '
            'Los aspirantes permanecerán pendientes.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSynchronizing = true;
    });

    try {
      final SyncResult result = await _applicantProvider
          .synchronizeApplicants();

      await _loadSyncHistorySummary();

      if (!mounted) return;

      setState(() {});

      if (result.skippedBecauseAlreadyRunning) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya existe una sincronización en curso.'),
          ),
        );

        return;
      }

      if (result.total == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay aspirantes pendientes de sincronización.'),
          ),
        );

        return;
      }

      if (result.fatalError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.fatalError!)));

        return;
      }

      if (result.failed > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.failed} aspirante(s) presentaron '
              'error durante la sincronización.',
            ),
          ),
        );

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.successful} aspirante(s) '
            'sincronizado(s) correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error en sincronización manual: $e');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _applicantProvider.errorMessage ??
                'No fue posible ejecutar la sincronización.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSynchronizing = false;
        });
      }
    }
  }

  // =============================================================
  // REINTENTAR SINCRONIZACIÓN
  // =============================================================

  Future<void> _retrySynchronization() async {
    if (_isSynchronizing) {
      return;
    }

    if (!_isConnected) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sin conexión a Internet. '
            'Los aspirantes con error permanecerán pendientes '
            'para un nuevo intento.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSynchronizing = true;
    });

    try {
      final SyncResult result = await _applicantProvider.retrySynchronization();

      await _loadSyncHistorySummary();

      if (!mounted) return;

      setState(() {});

      if (result.skippedBecauseAlreadyRunning) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya existe una sincronización en curso.'),
          ),
        );

        return;
      }

      if (result.total == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay aspirantes para reintentar.')),
        );

        return;
      }

      if (result.fatalError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.fatalError!)));

        return;
      }

      if (result.failed > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.failed} aspirante(s) '
              'continúan con error.',
            ),
          ),
        );

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.successful} aspirante(s) '
            'reintentado(s) correctamente.',
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error al reintentar sincronización: $e');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _applicantProvider.errorMessage ??
                'No fue posible reintentar la sincronización.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSynchronizing = false;
        });
      }
    }
  }

  // =============================================================
  // MONITOREAR INTERNET
  // =============================================================

  Future<void> _startInternetMonitoring() async {
    await _checkInternet();

    _internetSubscription = _internetConnection.onStatusChange.listen((
      InternetStatus status,
    ) {
      if (!mounted) return;

      setState(() {
        _isConnected = status == InternetStatus.connected;

        _checkingConnection = false;
      });
    });
  }

  // =============================================================
  // COMPROBAR INTERNET MANUALMENTE
  // =============================================================

  Future<void> _checkInternet() async {
    if (mounted) {
      setState(() {
        _checkingConnection = true;
      });
    }

    final bool connected = await _internetConnection.hasInternetAccess;

    if (!mounted) return;

    setState(() {
      _isConnected = connected;
      _checkingConnection = false;
    });
  }

  // =============================================================
  // LIBERAR RECURSOS
  // =============================================================

  @override
  void dispose() {
    _internetSubscription?.cancel();
    _applicantProvider.dispose();

    super.dispose();
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final List<ApplicantModel> applicants = _applicantProvider.applicants;

    // ===========================================================
    // CONTADORES
    // ===========================================================

    final int pendingCount = _applicantProvider.pendingSyncCount;

    final int syncingCount = _applicantProvider.syncingCount;

    final int syncedCount = _syncedCount;

    final int errorCount = _applicantProvider.syncErrorCount;

    final DateTime? lastSynchronization = _lastSynchronization;

    return Scaffold(
      backgroundColor: _isDark
          ? const Color(0xFF101820)
          : const Color(0xFFF6F8FB),

      // =========================================================
      // BARRA SUPERIOR
      // =========================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _isDark ? const Color(0xFF18232F) : Colors.white,
        foregroundColor: _isDark ? Colors.white : Colors.black87,
        title: Text(
          'Sincronización',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: _isDark ? Colors.white : null,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sincronizar ahora',
            onPressed: !_isConnected || _isSynchronizing
                ? null
                : _synchronizeManually,
            icon: _isSynchronizing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () async {
              await _loadApplicants();
              await _checkInternet();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      // =========================================================
      // CONTENIDO
      // =========================================================
      body: _applicantProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(
              applicants: applicants,
              pendingCount: pendingCount,
              syncingCount: syncingCount,
              syncedCount: syncedCount,
              errorCount: errorCount,
              lastSynchronization: lastSynchronization,
            ),
    );
  }

  // =============================================================
  // CONTENIDO PRINCIPAL
  // =============================================================

  Widget _buildContent({
    required List<ApplicantModel> applicants,
    required int pendingCount,
    required int syncingCount,
    required int syncedCount,
    required int errorCount,
    required DateTime? lastSynchronization,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadApplicants();
        await _checkInternet();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =====================================================
            // CONEXIÓN A INTERNET
            // =====================================================
            _buildInteractiveStatusCard(
              icon: _checkingConnection
                  ? Icons.sync_rounded
                  : _isConnected
                  ? Icons.wifi_rounded
                  : Icons.wifi_off_rounded,
              title: 'Conexión a Internet',
              value: _checkingConnection
                  ? 'Comprobando conexión...'
                  : _isConnected
                  ? 'Conectado a Internet'
                  : 'Sin conexión a Internet',
              color: _checkingConnection
                  ? const Color(0xFF64748B)
                  : _isConnected
                  ? const Color(0xFF059669)
                  : const Color(0xFFDC2626),
              onTap: _checkInternet,
            ),

            const SizedBox(height: 14),

            // =====================================================
            // SINCRONIZAR AHORA
            // =====================================================
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: !_isConnected || _isSynchronizing
                    ? null
                    : _synchronizeManually,
                icon: _isSynchronizing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync_rounded),
                label: Text(
                  _isSynchronizing
                      ? 'Sincronizando...'
                      : _isConnected
                      ? 'Sincronizar ahora'
                      : 'Sin conexión a Internet',
                ),
              ),
            ),

            if (errorCount > 0) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: !_isConnected || _isSynchronizing
                      ? null
                      : _retrySynchronization,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    _isSynchronizing
                        ? 'Procesando...'
                        : 'Reintentar errores ($errorCount)',
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // =====================================================
            // PENDIENTES
            // =====================================================
            _buildInteractiveStatusCard(
              icon: Icons.schedule_rounded,
              title: 'Pendientes',
              value: '$pendingCount aspirantes',
              color: const Color(0xFFF59E0B),
              onTap: () {
                _showApplicantsByStatus(
                  title: 'Aspirantes pendientes',
                  applicants: applicants
                      .where(
                        (applicant) =>
                            applicant.syncStatus.toLowerCase() == 'pendiente',
                      )
                      .toList(),
                  emptyMessage:
                      'No hay aspirantes pendientes '
                      'de sincronización.',
                  color: const Color(0xFFF59E0B),
                );
              },
            ),

            const SizedBox(height: 14),

            // =====================================================
            // SINCRONIZACIÓN EN PROCESO
            // =====================================================
            _buildInteractiveStatusCard(
              icon: Icons.cloud_upload_outlined,
              title: 'Sincronización en proceso',
              value: '$syncingCount aspirantes',
              color: const Color(0xFF2563EB),
              onTap: () {
                _showApplicantsByStatus(
                  title: 'Aspirantes en proceso de sincronización',
                  applicants: applicants.where((applicant) {
                    final String status = applicant.syncStatus.toLowerCase();

                    return status == 'sincronizando' || status == 'syncing';
                  }).toList(),
                  emptyMessage:
                      'No hay aspirantes en proceso de sincronización.',
                  color: const Color(0xFF2563EB),
                );
              },
            ),

            const SizedBox(height: 14),

            // =====================================================
            // SINCRONIZADOS
            // =====================================================
            _buildInteractiveStatusCard(
              icon: Icons.check_circle_outline_rounded,

              title: 'Sincronizados',

              value: '$syncedCount registros',

              color: const Color(0xFF059669),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              },
            ),

            const SizedBox(height: 14),

            // =====================================================
            // ERRORES
            // =====================================================
            _buildInteractiveStatusCard(
              icon: Icons.error_outline_rounded,
              title: 'Errores',
              value: '$errorCount aspirantes',
              color: const Color(0xFFDC2626),
              onTap: () {
                _showApplicantsByStatus(
                  title: 'Aspirantes con error',
                  applicants: applicants
                      .where(
                        (applicant) =>
                            applicant.syncStatus.toLowerCase() == 'error',
                      )
                      .toList(),
                  emptyMessage:
                      'No hay aspirantes con errores '
                      'de sincronización.',
                  color: const Color(0xFFDC2626),
                );
              },
            ),

            const SizedBox(height: 24),

            // =====================================================
            // ÚLTIMA SINCRONIZACIÓN
            // =====================================================
            _buildInteractiveStatusCard(
              icon: Icons.history_rounded,
              title: 'Última sincronización',
              value: lastSynchronization == null
                  ? 'Aún no hay sincronizaciones exitosas'
                  : _formatSynchronizationDateTime(lastSynchronization),
              color: const Color(0xFF7C3AED),
              onTap: () {},
            ),

            const SizedBox(height: 24),

            // =====================================================
            // INFORMACIÓN
            // =====================================================
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _isDark
                    ? const Color(0xFF1E3042)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isDark
                      ? const Color(0xFF344B62)
                      : const Color(0xFFBFDBFE),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: _isDark ? Colors.white : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Los aspirantes se guardan localmente '
                      'y se sincronizan cuando hay conexión.',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isDark ? Colors.white : const Color(0xFF1E40AF),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // TARJETA INTERACTIVA
  // =============================================================

  Widget _buildInteractiveStatusCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF1B2733) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isDark
                  ? const Color(0xFF344454)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: _isDark ? Colors.white : color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _isDark ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _isDark ? Colors.white : color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _isDark ? Colors.white : const Color(0xFF94A3B8),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // MOSTRAR ASPIRANTES POR ESTADO
  // =============================================================

  void _showApplicantsByStatus({
    required String title,
    required List<ApplicantModel> applicants,
    required String emptyMessage,
    required Color color,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: BoxDecoration(
            color: _isDark ? const Color(0xFF101820) : const Color(0xFFF6F8FB),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // ===================================================
              // BARRA SUPERIOR
              // ===================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.people_alt_outlined, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: _isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.close_rounded,
                        color: _isDark ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ===================================================
              // LISTA
              // ===================================================
              Expanded(
                child: applicants.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 60,
                                color: color,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                emptyMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _isDark
                                      ? Colors.white
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(18),
                        itemCount: applicants.length,
                        itemBuilder: (context, index) {
                          final ApplicantModel applicant = applicants[index];

                          return _buildApplicantMiniCard(
                            applicant: applicant,
                            color: color,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =============================================================
  // TARJETA PEQUEÑA DE ASPIRANTE
  // =============================================================

  Widget _buildApplicantMiniCard({
    required ApplicantModel applicant,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: _isDark ? const Color(0xFF1B2733) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isDark ? const Color(0xFF344454) : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pop(context);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApplicantDetailPage(applicant: applicant),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ---------------------------------------------------
              // ICONO
              // ---------------------------------------------------
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: _isDark ? Colors.white : color,
                ),
              ),

              const SizedBox(width: 12),

              // ---------------------------------------------------
              // INFORMACIÓN
              // ---------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${applicant.firstName} '
                      '${applicant.lastName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${applicant.documentType}: '
                      '${applicant.documentNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        color: _isDark ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      applicant.program,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isDark ? Colors.white : color,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: _isDark ? Colors.white : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // FORMATO DE FECHA Y HORA
  // =============================================================

  String _formatSynchronizationDateTime(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');

    final String month = dateTime.month.toString().padLeft(2, '0');

    final String year = dateTime.year.toString();

    final String hour = dateTime.hour.toString().padLeft(2, '0');

    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
