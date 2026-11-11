// =============================================================
// APLICATIVO NANCY
// Página - Datos de una Copia de Seguridad
// =============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../session/session_manager.dart';
import '../../models/backup_applicant_model.dart';
import '../../models/backup_model.dart';
import '../../providers/backup_provider.dart';

// =============================================================
// PÁGINA
// =============================================================

class BackupDataPage extends StatefulWidget {
  final BackupModel backup;

  const BackupDataPage({super.key, required this.backup});

  @override
  State<BackupDataPage> createState() => _BackupDataPageState();
}

// =============================================================
// STATE
// =============================================================

class _BackupDataPageState extends State<BackupDataPage> {
  // ===========================================================
  // CICLO DE VIDA
  // ===========================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _loadData();
    });
  }

  // ===========================================================
  // CARGAR DATOS
  // ===========================================================

  Future<void> _loadData() async {
    final SessionManager session = SessionManager.instance;

    final bool canAccessBackupData =
        session.hasActiveSession &&
        (session.isAdministrator ||
            (session.isCoordinator && session.currentUser?.id != null));

    if (!canAccessBackupData) {
      return;
    }

    final BackupProvider provider = context.read<BackupProvider>();

    final bool success = await provider.loadBackupApplicants(widget.backup);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          content: Text(
            provider.errorMessage ?? 'No fue posible leer la copia.',
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
    final SessionManager session = SessionManager.instance;

    final bool canAccessBackupData =
        session.hasActiveSession &&
        (session.isAdministrator ||
            (session.isCoordinator && session.currentUser?.id != null));

    if (!canAccessBackupData) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(title: const Text('Datos de la copia')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No tienes permiso para consultar copias de seguridad.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final BackupProvider provider = context.watch<BackupProvider>();

    final bool isLoading = provider.isLoadingBackupData;

    final List<BackupApplicantModel> applicants = provider.backupApplicants;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),

      // =======================================================
      // APPBAR
      // =======================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),

        title: const Text(
          'Datos de la copia',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),

        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      // =======================================================
      // BODY
      // =======================================================
      body: isLoading ? _buildLoading() : _buildContent(applicants),
    );
  }

  // ===========================================================
  // CARGANDO
  // ===========================================================

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),

          SizedBox(height: 18),

          Text('Leyendo datos de la copia...'),

          SizedBox(height: 8),

          Text(
            'La información se abre solo para consulta.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // CONTENIDO
  // ===========================================================

  Widget _buildContent(List<BackupApplicantModel> applicants) {
    return RefreshIndicator(
      onRefresh: _loadData,

      child: applicants.isEmpty
          ? _buildEmpty()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // =================================================
                // INFORMACIÓN DE LA COPIA
                // =================================================
                _buildBackupInfo(applicants.length),

                const SizedBox(height: 20),

                // =================================================
                // TÍTULO
                // =================================================
                Text(
                  '${applicants.length} '
                  '${applicants.length == 1 ? 'aspirante encontrado' : 'aspirantes encontrados'}',

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),

                const SizedBox(height: 14),

                // =================================================
                // LISTA
                // =================================================
                ...applicants.map(
                  (applicant) => _ApplicantCard(applicant: applicant),
                ),

                const SizedBox(height: 30),
              ],
            ),
    );
  }

  // ===========================================================
  // INFORMACIÓN DE LA COPIA
  // ===========================================================

  Widget _buildBackupInfo(int totalApplicants) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(14),
                ),

                child: const Icon(
                  Icons.visibility_rounded,
                  color: Color(0xFF2D8FE5),
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Vista de solo lectura',

                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Esta información no modifica NANCY.',

                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(),

          const SizedBox(height: 12),

          _BackupDetailRow(
            icon: Icons.insert_drive_file_outlined,
            title: 'Archivo',
            value: widget.backup.name,
          ),

          const SizedBox(height: 12),

          _BackupDetailRow(
            icon: Icons.people_outline_rounded,
            title: 'Aspirantes',
            value: totalApplicants.toString(),
          ),

          const SizedBox(height: 12),

          _BackupDetailRow(
            icon: Icons.calendar_today_outlined,
            title: 'Fecha',
            value: widget.backup.formattedDate,
          ),

          const SizedBox(height: 12),

          _BackupDetailRow(
            icon: Icons.access_time_rounded,
            title: 'Hora',
            value: widget.backup.formattedTime,
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // SIN ASPIRANTES
  // ===========================================================

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.all(24),

      children: [
        const SizedBox(height: 80),

        Center(
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,

                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(24),
                ),

                child: const Icon(
                  Icons.folder_open_rounded,
                  size: 46,
                  color: Color(0xFF2D8FE5),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'No hay aspirantes en esta copia',

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'La copia fue abierta correctamente, '
                'pero no contiene aspirantes activos.',

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'La base de datos actual no fue modificada.',

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E8B57),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================
// TARJETA DE ASPIRANTE
// =============================================================

class _ApplicantCard extends StatelessWidget {
  final BackupApplicantModel applicant;

  const _ApplicantCard({required this.applicant});

  @override
  Widget build(BuildContext context) {
    // =========================================================
    // UBICACIÓN
    // =========================================================
    //
    // Se construye únicamente con los datos disponibles.
    //
    // Ejemplo:
    //
    // Antioquia → El Bagre → Puerto Claver → Vereda X
    //
    // =========================================================

    final String location =
        [
              applicant.department,
              applicant.municipality,
              applicant.corregimiento,
              applicant.village,
            ]
            .where((String? value) => value != null && value.trim().isNotEmpty)
            .map((String? value) => value!.trim())
            .join(' → ');

    // =========================================================
    // RESPONSABLE
    // =========================================================

    final String responsibleName = (applicant.responsibleName ?? '').trim();

    final String responsibleRole = (applicant.responsibleRole ?? '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // =====================================================
          // ICONO
          // =====================================================
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF2D8FE5),
            ),
          ),

          const SizedBox(width: 14),

          // =====================================================
          // INFORMACIÓN
          // =====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // =================================================
                // NOMBRE
                // =================================================
                Text(
                  applicant.fullName,

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),

                const SizedBox(height: 5),

                // =================================================
                // DOCUMENTO
                // =================================================
                Text(
                  'Documento: ${applicant.documentNumber}',

                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),

                // =================================================
                // ESCOLARIDAD
                // =================================================
                const SizedBox(height: 5),

                Text(
                  applicant.schooling.trim().isEmpty
                      ? 'Sin escolaridad'
                      : 'Escolaridad: ${applicant.schooling.trim()}',

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),

                // =================================================
                // PROGRAMA
                // =================================================
                const SizedBox(height: 4),

                Text(
                  applicant.program.trim().isEmpty
                      ? 'Sin programa'
                      : 'Programa: ${applicant.program.trim()}',

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),

                // =================================================
                // UBICACIÓN
                // =================================================
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 5),

                  Text(
                    'Ubicación: $location',

                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],

                // =================================================
                // RESPONSABLE
                // =================================================
                if (responsibleName.isNotEmpty) ...[
                  const SizedBox(height: 5),

                  Text(
                    'Responsable: $responsibleName',

                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],

                // =================================================
                // CARGO
                // =================================================
                if (responsibleRole.isNotEmpty)
                  Text(
                    'Cargo: $responsibleRole',

                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),

                // =================================================
                // ESTADO DE PAPELERA
                // =================================================
                //
                // Normalmente esta pantalla carga aspirantes
                // activos. Sin embargo, si en el futuro el backup
                // contiene registros eliminados, podemos mostrar
                // claramente su estado sin romper la vista.
                //
                // =================================================
                if (applicant.isDeleted) ...[
                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),

                    child: const Text(
                      'En papelera',

                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC62828),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // =====================================================
          // ICONO DE CONSULTA
          // =====================================================
          const Icon(Icons.visibility_outlined, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}

// =============================================================
// FILA DE INFORMACIÓN
// =============================================================

class _BackupDetailRow extends StatelessWidget {
  final IconData icon;

  final String title;

  final String value;

  const _BackupDetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),

        const SizedBox(width: 10),

        Text(
          '$title: ',

          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),

        Expanded(
          child: Text(
            value,

            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }
}
