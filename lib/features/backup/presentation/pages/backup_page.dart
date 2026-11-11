// =============================================================
// APLICATIVO NANCY
// Página - Copias de Seguridad
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../session/session_manager.dart';
import '../../providers/backup_provider.dart';
import 'backup_history_page.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  // =============================================================
  // CREAR COPIA DE SEGURIDAD
  // =============================================================

  Future<void> _createBackup(BuildContext context) async {
    // -----------------------------------------------------------
    // OBTENER PROVIDER
    // -----------------------------------------------------------

    final BackupProvider provider = context.read<BackupProvider>();

    // -----------------------------------------------------------
    // CREAR COPIA
    // -----------------------------------------------------------

    final bool success = await provider.createBackup();

    // -----------------------------------------------------------
    // VERIFICAR SI LA PÁGINA SIGUE ACTIVA
    // -----------------------------------------------------------

    if (!context.mounted) {
      return;
    }

    // -----------------------------------------------------------
    // MOSTRAR RESULTADO
    // -----------------------------------------------------------

    if (success) {
      final String backupName =
          provider.lastBackup?.path.split('/').last ?? 'Copia de seguridad';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2E8B57),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Copia creada correctamente:\n$backupName')),
            ],
          ),
        ),
      );
    } else {
      final String errorMessage =
          provider.errorMessage ??
          'No fue posible crear la copia de seguridad.';

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

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    // =============================================================
    // VERIFICAR PERMISOS DE ACCESO
    // =============================================================

    final SessionManager session = SessionManager.instance;

    final bool canAccessBackup =
        session.hasActiveSession &&
        (session.isAdministrator ||
            (session.isCoordinator && session.currentUser?.id != null));

    if (!canAccessBackup) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(title: const Text('Copias de seguridad')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No tienes permiso para acceder a las copias de seguridad.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // =============================================================
    // ESCUCHAR PROVIDER
    // =============================================================

    final BackupProvider backupProvider = context.watch<BackupProvider>();

    final bool isCreatingBackup = backupProvider.isCreatingBackup;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101820)
          : const Color(0xFFF6F8FB),

      // ===========================================================
      // APPBAR
      // ===========================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF17232E) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFE6EDF5)
            : const Color(0xFF1E293B),

        title: Text(
          'Copias de seguridad',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ),

      // ===========================================================
      // BODY
      // ===========================================================
      body: SafeArea(
        top: false,

        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              // ===================================================
              // ENCABEZADO
              // ===================================================
              Container(
                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF1B2B3A), Color(0xFF1C302F)]
                        : const [Color(0xFFEAF4FF), Color(0xFFEFFAF5)],
                  ),

                  borderRadius: BorderRadius.circular(24),

                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF344657)
                        : const Color(0xFFDCE8F2),
                  ),
                ),

                child: Column(
                  children: [
                    // =================================================
                    // ICONO
                    // =================================================
                    Container(
                      width: 76,
                      height: 76,

                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF263747) : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),

                      child: const Icon(
                        Icons.backup,
                        size: 42,
                        color: Color(0xFF2D8FE5),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // =================================================
                    // TÍTULO
                    // =================================================
                    Text(
                      'Copias de seguridad',
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // =================================================
                    // DESCRIPCIÓN
                    // =================================================
                    Text(
                      'Protege la información almacenada '
                      'en el aplicativo creando una copia '
                      'de seguridad.',
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF64748B),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // =================================================
                    // ETIQUETA
                    // =================================================
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),

                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF203B30)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Text(
                        'COPIAS DISPONIBLES',

                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF2E7D32),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // =====================================================
              // CREAR COPIA DE SEGURIDAD
              // =====================================================
              _BackupOption(
                icon: Icons.add_to_drive_rounded,

                title: isCreatingBackup
                    ? 'Creando copia de seguridad...'
                    : 'Crear copia de seguridad',

                description: isCreatingBackup
                    ? 'Espera mientras se crea la copia de nancy.db.'
                    : 'Guardar una copia de la información '
                          'del aplicativo.',

                color: const Color(0xFF2D8FE5),

                isLoading: isCreatingBackup,

                onTap: isCreatingBackup ? null : () => _createBackup(context),

                trailing: isCreatingBackup
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.white : const Color(0xFF2D8FE5),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF94A3B8),
                      ),
              ),

              // =====================================================
              // RESTAURAR INFORMACIÓN
              // =====================================================
              const _BackupOption(
                icon: Icons.restore_rounded,

                title: 'Restaurar información',

                description:
                    'Recuperar información a partir de '
                    'una copia existente.',

                color: Color(0xFF2E8B57),

                isEnabled: false,
              ),

              // =====================================================
              // HISTORIAL
              // =====================================================
              _BackupOption(
                icon: Icons.history_rounded,

                title: 'Historial de copias',

                description:
                    'Consultar las copias realizadas, '
                    'sus fechas y tamaños.',

                color: const Color(0xFF8B5CF6),

                onTap: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) => const BackupHistoryPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 22),

              // =====================================================
              // ESTADO
              // =====================================================
              Container(
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2936) : Colors.white,

                  borderRadius: BorderRadius.circular(18),

                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF344657)
                        : const Color(0xFFE2E8F0),
                  ),
                ),

                child: Row(
                  children: [
                    Icon(
                      isCreatingBackup
                          ? Icons.sync_rounded
                          : Icons.info_outline_rounded,

                      color: const Color(0xFF2D8FE5),

                      size: 22,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        isCreatingBackup
                            ? 'Creando copia de seguridad. '
                                  'Por favor espera...'
                            : 'Puedes crear una copia de seguridad '
                                  'de toda la información almacenada '
                                  'en NANCY.',

                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // =====================================================
              // BOTÓN VOLVER
              // =====================================================
              OutlinedButton.icon(
                onPressed: isCreatingBackup
                    ? null
                    : () {
                        Navigator.pop(context);
                      },

                icon: const Icon(Icons.arrow_back_rounded),

                label: const Text('Volver'),

                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? Colors.white
                      : const Color(0xFF2563EB),

                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF526779)
                        : const Color(0xFFBFDBFE),
                  ),

                  padding: const EdgeInsets.symmetric(vertical: 14),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// OPCIÓN DE COPIA DE SEGURIDAD
// =============================================================

class _BackupOption extends StatelessWidget {
  final IconData icon;

  final String title;

  final String description;

  final Color color;

  final VoidCallback? onTap;

  final bool isLoading;

  final bool isEnabled;

  final Widget? trailing;

  const _BackupOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.onTap,
    this.isLoading = false,
    this.isEnabled = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = isEnabled && !isLoading;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: isEnabled ? 1 : 0.65,

      child: InkWell(
        onTap: enabled ? onTap : null,

        borderRadius: BorderRadius.circular(18),

        child: Container(
          margin: const EdgeInsets.only(bottom: 12),

          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2936) : Colors.white,

            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: isDark ? const Color(0xFF344657) : const Color(0xFFE2E8F0),
            ),
          ),

          child: Row(
            children: [
              // ===================================================
              // ICONO
              // ===================================================
              Container(
                width: 46,
                height: 46,

                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),

                  borderRadius: BorderRadius.circular(13),
                ),

                child: Icon(icon, color: color, size: 24),
              ),

              const SizedBox(width: 14),

              // ===================================================
              // INFORMACIÓN
              // ===================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF334155),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      description,

                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // ===================================================
              // ICONO FINAL
              // ===================================================
              if (trailing != null)
                trailing!
              else if (!isEnabled)
                Icon(
                  Icons.lock_outline_rounded,
                  size: 19,
                  color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
                )
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: isDark ? Colors.white70 : const Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
