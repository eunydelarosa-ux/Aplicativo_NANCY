// =============================================================
// APLICATIVO NANCY
// Página - Detalle del Aspirante
// =============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/applicant_model.dart';
import '../../providers/applicant_provider.dart';

class ApplicantDetailPage extends StatefulWidget {
  final ApplicantModel applicant;

  const ApplicantDetailPage({super.key, required this.applicant});

  @override
  State<ApplicantDetailPage> createState() => _ApplicantDetailPageState();
}

class _ApplicantDetailPageState extends State<ApplicantDetailPage> {
  // =============================================================
  // ASPIRANTE ACTUAL
  // =============================================================

  late ApplicantModel _applicant;
  bool _isDark = false;
  bool _isVerifyingAccess = true;
  bool _accessDenied = false;

  // =============================================================
  // INICIALIZAR
  // =============================================================

  @override
  void initState() {
    super.initState();
    _applicant = widget.applicant;
    _verifyApplicantAccess();
  }

  // =============================================================
  // VERIFICAR ACCESO AL ASPIRANTE
  // =============================================================

  Future<void> _verifyApplicantAccess() async {
    final ApplicantProvider provider = ApplicantProvider();
    ApplicantModel? authorizedApplicant;

    try {
      authorizedApplicant = await provider.getApplicantById(
        widget.applicant.id,
      );
    } catch (_) {
      authorizedApplicant = null;
    } finally {
      provider.dispose();
    }

    if (!mounted) return;

    setState(() {
      _isVerifyingAccess = false;
      _accessDenied = authorizedApplicant == null;

      if (authorizedApplicant != null) {
        _applicant = authorizedApplicant;
      }
    });
  }

  // =============================================================
  // MOVER ASPIRANTE A PAPELERA
  // =============================================================

  Future<void> _deleteApplicant() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Mover a la papelera',
            style: TextStyle(
              color: _isDark ? Colors.white : const Color(0xFF243447),
            ),
          ),
          content: Text(
            'El aspirante '
            '${_applicant.firstName} '
            '${_applicant.lastName} '
            'se moverá a la papelera y podrá recuperarse posteriormente.\n\n'
            '¿Desea continuar?',
            style: TextStyle(
              color: _isDark ? Colors.white : const Color(0xFF243447),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: _isDark ? Colors.white : null,
              ),
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Mover a papelera'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final ApplicantProvider provider = ApplicantProvider();

      final bool success = await provider.moveToTrash(_applicant.id);

      if (!mounted) {
        return;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El aspirante fue movido a la papelera.'),
          ),
        );

        context.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.errorMessage ??
                  'No se pudo mover el aspirante a la papelera.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo mover el aspirante a la papelera: $e'),
        ),
      );
    }
  }

  // =============================================================
  // EDITAR ASPIRANTE
  // =============================================================

  Future<void> _editApplicant() async {
    final result = await context.push('/edit-applicant', extra: _applicant);

    if (!mounted) {
      return;
    }

    // ===========================================================
    // RECIBIR ASPIRANTE ACTUALIZADO
    // ===========================================================

    if (result is ApplicantModel) {
      setState(() {
        _applicant = result;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Aspirante actualizado correctamente.')),
        );
    }
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;

    // No mostrar información mientras se verifica el permiso.
    if (_isVerifyingAccess) {
      return Scaffold(
        backgroundColor: _isDark
            ? const Color(0xFF101820)
            : const Color(0xFFF1F8FB),
        appBar: AppBar(
          backgroundColor: _isDark
              ? const Color(0xFF18232F)
              : const Color(0xFFF7FBFD),
          foregroundColor: _isDark ? Colors.white : const Color(0xFF243447),
          title: const Text('Detalle del Aspirante'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Si no hay autorización, no mostrar los datos del aspirante.
    if (_accessDenied) {
      return Scaffold(
        backgroundColor: _isDark
            ? const Color(0xFF101820)
            : const Color(0xFFF1F8FB),
        appBar: AppBar(
          backgroundColor: _isDark
              ? const Color(0xFF18232F)
              : const Color(0xFFF7FBFD),
          foregroundColor: _isDark ? Colors.white : const Color(0xFF243447),
          title: const Text('Detalle del Aspirante'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 54,
                  color: _isDark ? Colors.white70 : const Color(0xFF2563A8),
                ),
                const SizedBox(height: 16),
                Text(
                  'Este aspirante no está disponible o no tienes '
                  'permiso para consultarlo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: _isDark ? Colors.white : const Color(0xFF243447),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final applicant = _applicant;

    return Scaffold(
      backgroundColor: _isDark
          ? const Color(0xFF101820)
          : const Color(0xFFF1F8FB),

      // =========================================================
      // APP BAR
      // =========================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _isDark
            ? const Color(0xFF18232F)
            : const Color(0xFFF7FBFD),
        foregroundColor: _isDark ? Colors.white : const Color(0xFF243447),

        titleSpacing: 0,

        title: Text(
          'Detalle del Aspirante',
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: _isDark ? Colors.white : const Color(0xFF30475A),
            letterSpacing: -0.2,
          ),
        ),

        actions: [
          // =====================================================
          // EDITAR
          // =====================================================
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _buildActionButton(
              icon: Icons.edit_outlined,
              tooltip: 'Editar aspirante',
              backgroundColor: _isDark
                  ? const Color(0xFF263747)
                  : const Color(0xFFEAF5FC),
              borderColor: _isDark
                  ? const Color(0xFF3A4B5C)
                  : const Color(0xFFD0E7F3),
              iconColor: _isDark ? Colors.white : const Color(0xFF2874B8),
              onPressed: _editApplicant,
            ),
          ),

          // =====================================================
          // ELIMINAR / PAPELERA
          // =====================================================
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _buildActionButton(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Mover a papelera',
              backgroundColor: _isDark
                  ? const Color(0xFF3A292D)
                  : const Color(0xFFFFF4F4),
              borderColor: _isDark
                  ? const Color(0xFF5A3A40)
                  : const Color(0xFFF2D1D1),
              iconColor: _isDark ? Colors.white : const Color(0xFFD65C5C),
              onPressed: _deleteApplicant,
            ),
          ),
        ],
      ),

      // =========================================================
      // CONTENIDO
      // =========================================================
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =================================================
              // INFORMACIÓN PERSONAL
              // =================================================
              _buildSectionCard(
                title: 'Información personal',
                icon: Icons.person_outline_rounded,
                iconBackground: const Color(0xFFEAF5FC),
                iconColor: const Color(0xFF327DB6),
                children: [
                  _buildInfoRow('Tipo de documento', applicant.documentType),
                  _buildInfoRow(
                    'Número de documento',
                    applicant.documentNumber,
                  ),
                  _buildInfoRow('Nombre(s)', applicant.firstName),
                  _buildInfoRow('Apellidos', applicant.lastName),
                  _buildInfoRow(
                    'Fecha de nacimiento',
                    _formatDate(applicant.birthDate),
                  ),
                  _buildInfoRow('Género', applicant.gender),
                ],
              ),

              const SizedBox(height: 8),

              // =================================================
              // INFORMACIÓN ACADÉMICA
              // =================================================
              _buildSectionCard(
                title: 'Información académica',
                icon: Icons.school_outlined,
                iconBackground: const Color(0xFFEDF9F4),
                iconColor: const Color(0xFF318565),
                children: [
                  _buildInfoRow('Escolaridad', applicant.schooling),
                  _buildInfoRow('Programa', applicant.program),
                ],
              ),

              const SizedBox(height: 8),

              // =================================================
              // INFORMACIÓN DE CONTACTO
              // =================================================
              _buildSectionCard(
                title: 'Información de contacto',
                icon: Icons.contact_phone_outlined,
                iconBackground: const Color(0xFFF1EEFC),
                iconColor: const Color(0xFF7054B5),
                children: [
                  _buildInfoRow('Teléfono', applicant.phone),
                  _buildInfoRow('Correo electrónico', applicant.email),
                  _buildInfoRow('Ubicación', _locationText(applicant)),
                  _buildInfoRow('Dirección', applicant.address),
                  _buildInfoRow(
                    'Responsable del registro',
                    _responsibleText(applicant),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // =================================================
              // OBSERVACIONES
              // =================================================
              _buildSectionCard(
                title: 'Observaciones',
                icon: Icons.notes_outlined,
                iconBackground: const Color(0xFFFFF7E9),
                iconColor: const Color(0xFFB47A28),
                children: [
                  _buildInfoRow(
                    'Observaciones',
                    applicant.observations.isEmpty
                        ? 'Sin observaciones'
                        : applicant.observations,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // =================================================
              // SINCRONIZACIÓN
              // =================================================
              _buildSectionCard(
                title: 'Sincronización',
                icon: Icons.sync_rounded,
                iconBackground: const Color(0xFFEAF5FC),
                iconColor: const Color(0xFF327DB6),
                children: [
                  _buildInfoRow(
                    'Estado',
                    applicant.syncStatus,
                    valueWidget: _statusBadge(applicant),
                  ),
                  _buildInfoRow(
                    'Fecha de registro',
                    _formatDateTime(applicant.createdAt),
                  ),
                  _buildInfoRow(
                    'Última actualización',
                    _formatDateTime(applicant.updatedAt),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // TARJETA DE SECCIÓN
  // =============================================================

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1B2733) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDark ? const Color(0xFF344454) : const Color(0xFFDCEAEC),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF527985).withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -----------------------------------------------------
          // ENCABEZADO DE LA SECCIÓN
          // -----------------------------------------------------
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isDark ? const Color(0xFF2C3B49) : iconBackground,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  color: _isDark ? Colors.white : iconColor,
                  size: 18,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: _isDark ? Colors.white : iconColor,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          // -----------------------------------------------------
          // INFORMACIÓN
          // -----------------------------------------------------
          ...children,
        ],
      ),
    );
  }

  // =============================================================
  // BOTÓN DEL APP BAR
  // =============================================================

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required Color backgroundColor,
    required Color borderColor,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: borderColor),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  // =============================================================
  // FILA DE INFORMACIÓN
  // =============================================================

  Widget _buildInfoRow(String label, String value, {Widget? valueWidget}) {
    final displayValue = value.isEmpty ? 'No registrado' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            softWrap: true,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _isDark ? Colors.white : const Color(0xFF74879A),
              letterSpacing: 0.05,
            ),
          ),

          const SizedBox(height: 1),

          if (valueWidget != null)
            valueWidget
          else
            SelectableText(
              displayValue,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: _isDark ? Colors.white : const Color(0xFF34495A),
                height: 1.18,
                letterSpacing: -0.1,
              ),
            ),
        ],
      ),
    );
  }

  // =============================================================
  // UBICACIÓN
  // =============================================================

  String _locationText(ApplicantModel applicant) {
    final parts = <String>[
      applicant.department.trim(),
      applicant.municipality.trim(),
      applicant.corregimiento.trim(),
      applicant.village.trim(),
    ].where((value) => value.isNotEmpty).toList();

    return parts.isEmpty ? 'No registrado' : parts.join('\n');
  }

  // =============================================================
  // RESPONSABLE DEL REGISTRO
  // =============================================================

  String _responsibleText(ApplicantModel applicant) {
    final name = applicant.responsibleName.trim();
    final role = applicant.responsibleRole.trim();
    final cedula = applicant.responsibleCedula.trim();

    final List<String> details = [];

    if (name.isNotEmpty) {
      details.add(name);
    }

    if (role.isNotEmpty) {
      details.add(role);
    }

    if (cedula.isNotEmpty) {
      details.add('CC: $cedula');
    }

    return details.isEmpty ? 'No registrado' : details.join('\n');
  }

  // =============================================================
  // ESTADO DE SINCRONIZACIÓN
  // =============================================================

  Widget _statusBadge(ApplicantModel applicant) {
    final status = applicant.syncStatus;

    Color backgroundColor = const Color(0xFFFFF7ED);
    Color textColor = const Color(0xFFB56A18);
    IconData icon = Icons.schedule_rounded;

    if (status.toLowerCase() == 'sincronizado' ||
        status.toLowerCase() == 'synced') {
      backgroundColor = const Color(0xFFEDF9F4);
      textColor = const Color(0xFF287A60);
      icon = Icons.check_circle_outline_rounded;
    }

    if (status.toLowerCase() == 'enviado' || status.toLowerCase() == 'sent') {
      backgroundColor = const Color(0xFFEEF6FD);
      textColor = const Color(0xFF3277B4);
      icon = Icons.cloud_done_outlined;
    }

    if (status.toLowerCase() == 'error') {
      backgroundColor = const Color(0xFFFFF1F1);
      textColor = const Color(0xFFC94F4F);
      icon = Icons.error_outline_rounded;
    }

    if (_isDark) {
      backgroundColor = const Color(0xFF2C3946);
      textColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),

          const SizedBox(width: 4),

          Flexible(
            child: Text(
              status.isEmpty ? 'No registrado' : status,
              softWrap: true,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // FORMATO DE FECHA
  // =============================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  // =============================================================
  // FORMATO DE FECHA Y HORA
  // =============================================================

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
