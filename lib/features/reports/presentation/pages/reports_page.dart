// ===============================================================
// APLICATIVO NANCY
// Página - Estadísticas / Reportes por programa
// ===============================================================

import 'package:flutter/material.dart';

import 'package:nancy_app/features/applicants/providers/applicant_provider.dart';
import 'package:nancy_app/features/applicants/models/applicant_model.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final ApplicantProvider _applicantProvider;

  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();

    _applicantProvider = ApplicantProvider();
    _loadFuture = _applicantProvider.loadApplicants();
  }

  @override
  void dispose() {
    _applicantProvider.dispose();
    super.dispose();
  }

  // =============================================================
  // RECARGAR INFORMACIÓN
  // =============================================================

  Future<void> _reloadReports() async {
    setState(() {
      _loadFuture = _applicantProvider.loadApplicants();
    });

    await _loadFuture;
  }

  // =============================================================
  // AGRUPAR ASPIRANTES POR PROGRAMA
  // =============================================================

  Map<String, int> _groupApplicantsByProgram(List<ApplicantModel> applicants) {
    final Map<String, int> grouped = {};

    for (final applicant in applicants) {
      final String program = applicant.program.trim();

      if (program.isEmpty) {
        continue;
      }

      grouped.update(program, (count) => count + 1, ifAbsent: () => 1);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final int countComparison = b.value.compareTo(a.value);

        if (countComparison != 0) {
          return countComparison;
        }

        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });

    return Map.fromEntries(entries);
  }

  // =============================================================
  // CONSTRUIR PANTALLA
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color backgroundColor = isDark
        ? const Color(0xFF101827)
        : const Color(0xFFF6F8FB);

    final Color cardColor = isDark ? const Color(0xFF273449) : Colors.white;

    final Color primaryText = isDark
        ? const Color(0xFFF1F5F9)
        : const Color(0xFF1E293B);

    final Color secondaryText = isDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: primaryText,
        title: const Text(
          'Estadísticas de aspirantes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar reporte',
            onPressed: _reloadReports,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reloadReports,
          child: FutureBuilder<void>(
            future: _loadFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 180),
                    Center(child: CircularProgressIndicator()),
                    SizedBox(height: 16),
                    Center(child: Text('Cargando estadísticas...')),
                  ],
                );
              }

              if (_applicantProvider.errorMessage != null) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 100),
                    Icon(
                      Icons.error_outline_rounded,
                      size: 56,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No fue posible cargar los reportes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _applicantProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: secondaryText),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _reloadReports,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar'),
                      ),
                    ),
                  ],
                );
              }

              final List<ApplicantModel> applicants =
                  _applicantProvider.applicants;

              final Map<String, int> programCounts = _groupApplicantsByProgram(
                applicants,
              );

              final int totalApplicants = applicants.length;

              final int totalPrograms = programCounts.length;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  // =================================================
                  // ENCABEZADO
                  // =================================================
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [const Color(0xFF1E293B), const Color(0xFF312E45)]
                            : [
                                const Color(0xFFEAF4FF),
                                const Color(0xFFF1ECFF),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFDCE8F2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF273449)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.bar_chart_rounded,
                                size: 30,
                                color: isDark
                                    ? const Color(0xFFC4B5FD)
                                    : const Color(0xFF7C3AED),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Resumen general de NANCY',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Consulta la distribución de aspirantes '
                          'registrados por programa académico.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: secondaryText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.storage_rounded,
                              size: 15,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Datos reales de la aplicación',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF93C5FD)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // =================================================
                  // TARJETAS RESUMEN
                  // =================================================
                  Row(
                    children: [
                      Expanded(
                        child: _StatisticCard(
                          icon: Icons.people_outline_rounded,
                          title: 'Aspirantes activos',
                          value: '$totalApplicants',
                          color: const Color(0xFF2563EB),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatisticCard(
                          icon: Icons.school_outlined,
                          title: 'Programas',
                          value: '$totalPrograms',
                          color: const Color(0xFF2E8B57),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // =================================================
                  // GRÁFICO POR PROGRAMA
                  // =================================================
                  Text(
                    'Aspirantes por programa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Distribución según los registros activos.',
                    style: TextStyle(fontSize: 13, color: secondaryText),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: programCounts.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.bar_chart_rounded,
                                  size: 48,
                                  color: secondaryText,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No hay aspirantes registrados '
                                  'por programa.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: secondaryText),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              ...programCounts.entries.map(
                                (entry) => _ProgramBar(
                                  program: entry.key,
                                  count: entry.value,
                                  maxCount: programCounts.values.reduce(
                                    (a, b) => a > b ? a : b,
                                  ),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 24),

                  // =================================================
                  // DETALLE NUMÉRICO
                  // =================================================
                  Text(
                    'Detalle por programa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryText,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF475569)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: programCounts.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              'No hay datos disponibles.',
                              style: TextStyle(color: secondaryText),
                            ),
                          )
                        : Column(
                            children: [
                              for (
                                int i = 0;
                                i < programCounts.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    color: isDark
                                        ? const Color(0xFF475569)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          programCounts.keys.elementAt(i),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: primaryText,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF2563EB,
                                          ).withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '${programCounts.values.elementAt(i)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // AVISO
                  // =================================================
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF273449)
                          : const Color(0xFFEAF4FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: isDark
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'El reporte incluye únicamente aspirantes '
                            'activos. Los registros en la Papelera '
                            'no se contabilizan. Actualiza el reporte '
                            'para consultar los cambios recientes.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// TARJETA DE ESTADÍSTICA
// ===============================================================

class _StatisticCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isDark;

  const _StatisticCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF273449) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================================================
// BARRA DE PROGRAMA
// ===============================================================

class _ProgramBar extends StatelessWidget {
  final String program;
  final int count;
  final int maxCount;
  final bool isDark;

  const _ProgramBar({
    required this.program,
    required this.count,
    required this.maxCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF334155);

    final double percentage = maxCount == 0 ? 0 : count / maxCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  program,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 10,
              backgroundColor: isDark
                  ? const Color(0xFF475569)
                  : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
