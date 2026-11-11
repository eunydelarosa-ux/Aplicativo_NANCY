// =============================================================
// APLICATIVO NANCY
// Página - Historial de Copias de Seguridad
// =============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../session/session_manager.dart';
import '../../models/backup_model.dart';
import '../../providers/backup_provider.dart';
import 'backup_data_page.dart';
// =============================================================
// PÁGINA
// =============================================================

class BackupHistoryPage extends StatefulWidget {
  const BackupHistoryPage({super.key});

  @override
  State<BackupHistoryPage> createState() => _BackupHistoryPageState();
}

class _BackupHistoryPageState extends State<BackupHistoryPage> {
  // ===========================================================
  // CICLO DE VIDA
  // ===========================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<BackupProvider>().loadBackups();
    });
  }

  // ===========================================================
  // VERIFICAR PERMISOS
  // ===========================================================

  bool get _canAccessBackupHistory {
    final SessionManager session = SessionManager.instance;

    return session.hasActiveSession &&
        (session.isAdministrator ||
            (session.isCoordinator && session.currentUser?.id != null));
  }

  // ===========================================================
  // ENVIAR COPIA DE SEGURIDAD
  // ===========================================================

  Future<void> _shareBackup(BackupModel backup) async {
    try {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: Duration(minutes: 1),
          content: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Preparando copia para compartir...')),
            ],
          ),
        ),
      );

      // El ZIP debe ser preparado por el proveedor
      // y el servicio protegido, nunca directamente aquí.
      final BackupProvider provider = context.read<BackupProvider>();

      final File? zipFile = await provider.prepareBackupForSharing(backup);

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (zipFile == null) {
        throw Exception(
          provider.errorMessage ??
              'No fue posible preparar la copia para compartir.',
        );
      }

      await SharePlus.instance.share(
        ShareParams(
          title: 'Copia de seguridad NANCY',
          text:
              'Copia de seguridad del aplicativo NANCY.\n\n'
              'Archivo: ${backup.name}',
          files: [XFile(zipFile.path, mimeType: 'application/zip')],
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('No fue posible enviar la copia: $error')),
            ],
          ),
        ),
      );
    }
  }

  // ===========================================================
  // VER DATOS DE LA COPIA
  // ===========================================================

  void _viewBackupData(BackupModel backup) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BackupDataPage(backup: backup)),
    );
  }

  // ===========================================================
  // CONFIRMAR ELIMINACIÓN
  // ===========================================================

  Future<void> _confirmDelete(BackupModel backup) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar copia de seguridad'),
          content: Text(
            '¿Estás seguro de que deseas eliminar '
            'esta copia?\n\n'
            '${backup.name}\n\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final BackupProvider provider = context.read<BackupProvider>();

    final bool success = await provider.deleteBackup(backup);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2E8B57),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'La copia de seguridad fue '
                  'eliminada correctamente.',
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final String errorMessage =
          provider.errorMessage ??
          'No fue posible eliminar la copia de seguridad.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(errorMessage)),
            ],
          ),
        ),
      );
    }
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    // Esta comprobación pertenece a la pantalla del historial,
    // no a la tarjeta individual.
    if (!_canAccessBackupHistory) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(title: const Text('Historial de copias')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No tienes permiso para consultar el historial de copias.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final BackupProvider backupProvider = context.watch<BackupProvider>();

    final List<BackupModel> backups = backupProvider.backups;

    final bool isLoading = backupProvider.isLoadingBackups;

    final bool isSending = backupProvider.isSendingBackup;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101820)
          : const Color(0xFFF6F8FB),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF17232E) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFE6EDF5)
            : const Color(0xFF1E293B),
        title: Text(
          'Historial de copias',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: isLoading
                ? null
                : () {
                    context.read<BackupProvider>().loadBackups();
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      // ========================================================
      // CONTENIDO
      // ========================================================
      body: RefreshIndicator(
        onRefresh: () {
          return context.read<BackupProvider>().loadBackups();
        },
        child: _buildBody(context, backups, isLoading, isSending),
      ),
    );
  }

  // ===========================================================
  // CONSTRUIR CONTENIDO
  // ===========================================================

  Widget _buildBody(
    BuildContext context,
    List<BackupModel> backups,
    bool isLoading,
    bool isSending,
  ) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando historial de copias...'),
          ],
        ),
      );
    }

    // =========================================================
    // SIN COPIAS
    // =========================================================

    if (backups.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF20364A)
                        : const Color(0xFFEAF4FF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.folder_open_rounded,
                    size: 44,
                    color: Color(0xFF2D8FE5),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No hay copias de seguridad',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cuando crees una copia de '
                  'seguridad, aparecerá '
                  'automáticamente en este '
                  'historial.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFB6C2CE)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // =========================================================
    // LISTA DE COPIAS
    // =========================================================

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${backups.length} '
          '${backups.length == 1 ? 'copia disponible' : 'copias disponibles'}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFB6C2CE)
                : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),

        // Tarjetas de las copias.
        ...backups.map((BackupModel backup) {
          return _BackupHistoryCard(
            backup: backup,
            isSending: isSending,
            onView: () {
              _viewBackupData(backup);
            },
            onSend: () {
              _shareBackup(backup);
            },
            onDelete: () {
              _confirmDelete(backup);
            },
          );
        }),

        const SizedBox(height: 30),
      ],
    );
  }
}

// =============================================================
// TARJETA DE COPIA
// =============================================================

class _BackupHistoryCard extends StatelessWidget {
  final BackupModel backup;
  final VoidCallback onView;
  final VoidCallback onSend;
  final VoidCallback onDelete;
  final bool isSending;

  const _BackupHistoryCard({
    required this.backup,
    required this.onView,
    required this.onSend,
    required this.onDelete,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    // Esta clase dibuja solamente una tarjeta.
    // Los permisos y la lista pertenecen a BackupHistoryPage.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2936) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF344657) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // ENCABEZADO
          // ====================================================
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF20364A)
                      : const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.backup_rounded,
                  color: Color(0xFF2D8FE5),
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Copia de seguridad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF334155),
                  ),
                ),
              ),

              // Ver datos.
              IconButton(
                tooltip: 'Ver datos de la copia',
                onPressed: isSending ? null : onView,
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: Color(0xFF2E8B57),
                ),
              ),

              // Enviar.
              IconButton(
                tooltip: 'Enviar copia',
                onPressed: isSending ? null : onSend,
                icon: const Icon(Icons.share_rounded, color: Color(0xFF2D8FE5)),
              ),

              // Eliminar.
              IconButton(
                tooltip: 'Eliminar copia',
                onPressed: isSending ? null : onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFC62828),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ====================================================
          // INFORMACIÓN DEL ARCHIVO
          // ====================================================
          _InfoRow(
            icon: Icons.insert_drive_file_outlined,
            title: 'Archivo',
            value: backup.name,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            title: 'Fecha',
            value: backup.formattedDate,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.access_time_rounded,
            title: 'Hora',
            value: backup.formattedTime,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.storage_rounded,
            title: 'Tamaño',
            value: backup.formattedSize,
          ),

          const SizedBox(height: 20),

          // ====================================================
          // BOTÓN VER DATOS
          // ====================================================
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSending ? null : onView,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Ver datos de la copia'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E8B57),
                side: const BorderSide(color: Color(0xFFA7D7B4)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ====================================================
          // BOTÓN ENVIAR
          // ====================================================
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSending ? null : onSend,
              icon: const Icon(Icons.share_rounded),
              label: const Text('Enviar copia'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// FILA DE INFORMACIÓN
// =============================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? const Color(0xFF9FB0C0) : const Color(0xFF64748B),
        ),
        const SizedBox(width: 10),
        Text(
          '$title: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFD5DEE8) : const Color(0xFF475569),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFB6C2CE) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}
