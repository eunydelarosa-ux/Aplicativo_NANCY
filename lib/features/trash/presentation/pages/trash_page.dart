// ===============================================================
// APLICATIVO NANCY
// Página - Papelera de Aspirantes
// ===============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/trash_provider.dart';
import '../../../applicants/models/applicant_model.dart';

class TrashPage extends StatelessWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TrashProvider()..loadTrash(),
      child: const _TrashView(),
    );
  }
}

class _TrashView extends StatelessWidget {
  const _TrashView();

  // =============================================================
  // CONFIRMAR RESTAURACIÓN
  // =============================================================

  Future<void> _confirmRestore(
    BuildContext context,
    ApplicantModel applicant,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restaurar aspirante'),
          content: Text(
            '¿Desea restaurar a '
            '${applicant.firstName} ${applicant.lastName}?\n\n'
            'El aspirante volverá a aparecer en el listado normal.',
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
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final TrashProvider provider = context.read<TrashProvider>();

    final bool success = await provider.restoreApplicant(applicant.id);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success
            ? const Color(0xFF2E8B57)
            : const Color(0xFFC62828),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(
              success
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success
                    ? 'Aspirante restaurado correctamente.'
                    : provider.errorMessage ??
                          'No fue posible restaurar el aspirante.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101820)
          : const Color(0xFFF6F8FB),

      // =========================================================
      // APP BAR
      // =========================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF17232E) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFE6EDF5)
            : const Color(0xFF1E293B),

        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),

        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFE11D48),
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            Text(
              'Papelera',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),

        // ---------------------------------------------------------
        // IMPORTANTE:
        // No hay botón "Vaciar papelera".
        // ---------------------------------------------------------
      ),

      // =========================================================
      // BODY
      // =========================================================
      body: Consumer<TrashProvider>(
        builder: (context, provider, child) {
          // -----------------------------------------------------
          // CARGANDO
          // -----------------------------------------------------

          if (provider.isLoading && provider.deletedApplicants.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // -----------------------------------------------------
          // ERROR
          // -----------------------------------------------------

          if (provider.errorMessage != null &&
              provider.deletedApplicants.isEmpty) {
            return _buildError(context, provider);
          }

          // -----------------------------------------------------
          // PAPELERA VACÍA
          // -----------------------------------------------------

          if (provider.isEmpty) {
            return _buildEmptyState(context);
          }

          // -----------------------------------------------------
          // LISTA
          // -----------------------------------------------------

          return RefreshIndicator(
            onRefresh: provider.loadTrash,
            child: ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: provider.deletedApplicants.length,
              itemBuilder: (context, index) {
                final ApplicantModel applicant =
                    provider.deletedApplicants[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildApplicantCard(context, applicant),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // =============================================================
  // TARJETA DEL ASPIRANTE
  // =============================================================

  Widget _buildApplicantCard(BuildContext context, ApplicantModel applicant) {
    final String location =
        [
              applicant.department,
              applicant.municipality,
              applicant.corregimiento,
              applicant.village,
            ]
            .where((String value) => value.trim().isNotEmpty)
            .map((String value) => value.trim())
            .join(' → ');

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
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
          // =====================================================
          // ENCABEZADO
          // =====================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3A2630)
                      : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFFE11D48),
                  size: 26,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${applicant.firstName} '
                      '${applicant.lastName}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Documento: ${applicant.documentNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFB6C2CE)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // =====================================================
          // ESCOLARIDAD
          // =====================================================
          if (applicant.schooling.trim().isNotEmpty) ...[
            _InfoRow(
              icon: Icons.menu_book_outlined,
              title: 'Escolaridad',
              value: applicant.schooling,
            ),
            const SizedBox(height: 10),
          ],

          // =====================================================
          // PROGRAMA
          // =====================================================
          if (applicant.program.trim().isNotEmpty) ...[
            _InfoRow(
              icon: Icons.school_outlined,
              title: 'Programa',
              value: applicant.program,
            ),
            const SizedBox(height: 10),
          ],

          // =====================================================
          // UBICACIÓN
          // =====================================================
          if (location.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.location_on_outlined,
              title: 'Ubicación',
              value: location,
            ),
            const SizedBox(height: 10),
          ],

          // =====================================================
          // RESPONSABLE
          // =====================================================
          if (applicant.responsibleName.trim().isNotEmpty) ...[
            _InfoRow(
              icon: Icons.person_outline_rounded,
              title: 'Responsable',
              value: applicant.responsibleName,
            ),
            const SizedBox(height: 10),
          ],

          // =====================================================
          // CARGO
          // =====================================================
          if (applicant.responsibleRole.trim().isNotEmpty) ...[
            _InfoRow(
              icon: Icons.badge_outlined,
              title: 'Cargo',
              value: applicant.responsibleRole,
            ),
            const SizedBox(height: 10),
          ],

          // =====================================================
          // FECHA DE ELIMINACIÓN
          // =====================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 17,
                  color: isDark
                      ? const Color(0xFFB6C2CE)
                      : const Color(0xFF64748B),
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Text(
                    'Eliminado: '
                    '${_formatDeletedAt(applicant.deletedAt)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFFB6C2CE)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // =====================================================
          // RESTAURAR
          // =====================================================
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _confirmRestore(context, applicant);
              },
              icon: const Icon(Icons.restore_rounded, size: 19),
              label: const Text('Restaurar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF15803D),
                side: const BorderSide(color: Color(0xFF86EFAC)),
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

  // =============================================================
  // ESTADO VACÍO
  // =============================================================

  Widget _buildEmptyState(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'No hay aspirantes eliminados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF334155),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Los aspirantes que muevas a la papelera '
              'permanecerán registrados y podrán '
              'restaurarse posteriormente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // ERROR
  // =============================================================

  Widget _buildError(BuildContext context, TrashProvider provider) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.redAccent,
            ),

            const SizedBox(height: 16),

            Text(
              provider.errorMessage ?? 'Ocurrió un error.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF475569),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: provider.loadTrash,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Intentar nuevamente'),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // FORMATO DE FECHA DE ELIMINACIÓN
  // =============================================================

  String _formatDeletedAt(DateTime? date) {
    if (date == null) {
      return 'Fecha no disponible';
    }

    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    final String year = date.year.toString();

    final String hour = date.hour.toString().padLeft(2, '0');

    final String minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
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
          color: isDark ? const Color(0xFFB6C2CE) : const Color(0xFF64748B),
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
