// =============================================================
// APLICATIVO NANCY
// Página - Lista de Aspirantes
// =============================================================

import 'package:flutter/material.dart';

import '../../models/applicant_model.dart';
import '../../providers/applicant_provider.dart';
import 'applicant_detail_page.dart';

class ApplicantListPage extends StatefulWidget {
  // =============================================================
  // BÚSQUEDA RECIBIDA DESDE EL DASHBOARD
  // =============================================================

  final String? initialSearch;

  // =============================================================
  // INDICA SI LA LISTA FUE ABIERTA DESDE EL REGISTRO
  // =============================================================

  final bool openedFromRegistration;

  // =============================================================
  // INDICA SI DEBE MOSTRAR SOLAMENTE PENDIENTES
  // =============================================================

  final bool onlyPending;

  // ID del aspirante recién registrado
  final String? highlightedApplicantId;

  const ApplicantListPage({
    super.key,
    this.initialSearch,
    this.openedFromRegistration = false,
    this.onlyPending = false,
    this.highlightedApplicantId,
  });

  @override
  State<ApplicantListPage> createState() => _ApplicantListPageState();
}

class _ApplicantListPageState extends State<ApplicantListPage> {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // =============================================================
  // PROVIDER
  // =============================================================

  final ApplicantProvider _applicantProvider = ApplicantProvider();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const int _itemsPerPage = 10;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _searchQuery = widget.initialSearch ?? '';

    _searchController.text = _searchQuery;

    _loadApplicants();
  }

  // =============================================================
  // CARGAR ASPIRANTES
  // =============================================================

  Future<void> _loadApplicants() async {
    await _applicantProvider.loadApplicants();

    if (mounted) {
      setState(() {
        final totalPages =
            (_getFilteredApplicants(_applicantProvider.applicants).length /
                    _itemsPerPage)
                .ceil();

        if (totalPages == 0) {
          _currentPage = 0;
        } else if (_currentPage >= totalPages) {
          _currentPage = totalPages - 1;
        }
      });
    }
  }

  // =============================================================
  // BÚSQUEDA GENERAL DE ASPIRANTES
  // =============================================================

  // =============================================================
  // NORMALIZAR TEXTO PARA BÚSQUEDA
  // =============================================================

  String _normalizeSearchText(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n');
  }

  // =============================================================
  // BÚSQUEDA GENERAL DE ASPIRANTES
  // =============================================================
  List<ApplicantModel> _getFilteredApplicants(List<ApplicantModel> applicants) {
    final query = _normalizeSearchText(_searchQuery);

    // ===========================================================
    // FILTRO POR ESTADO
    // ===========================================================

    final List<ApplicantModel> sourceApplicants = widget.onlyPending
        ? applicants.where((applicant) {
            final String status = applicant.syncStatus.toLowerCase().trim();

            return status == 'pendiente' || status == 'pending';
          }).toList()
        : applicants;

    // ===========================================================
    // SIN BÚSQUEDA
    // ===========================================================

    // Si no hay búsqueda, conservar el orden original,
    // pero colocar primero al aspirante recién registrado.
    if (query.isEmpty) {
      final highlighted = sourceApplicants
          .where((a) => a.id == widget.highlightedApplicantId)
          .toList();

      final remaining = sourceApplicants
          .where((a) => a.id != widget.highlightedApplicantId)
          .toList();

      return [...highlighted, ...remaining];
    }

    // ===========================================================
    // BÚSQUEDA
    // ===========================================================

    // Buscar en los registros permitidos por el filtro,
    // ignorando mayúsculas y tildes.
    final results = sourceApplicants.where((applicant) {
      final searchableFields = <String>[
        applicant.documentType,
        applicant.documentNumber,
        applicant.firstName,
        applicant.lastName,
        '${applicant.firstName} ${applicant.lastName}',
        applicant.birthDate.toString(),
        applicant.gender,
        applicant.schooling,
        applicant.program,
        applicant.phone,
        applicant.email,
        applicant.address,
        applicant.department,
        applicant.municipality,
        applicant.corregimiento,
        applicant.village,
        applicant.responsibleName,
        applicant.responsibleCedula,
        applicant.responsibleRole,
        applicant.observations,
        applicant.syncStatus,
        applicant.createdAt.toString(),
        applicant.updatedAt.toString(),
      ];

      return searchableFields.any(
        (field) => _normalizeSearchText(field).contains(query),
      );
    }).toList();

    // Priorizar al aspirante recién registrado.
    // Después, los resultados exactos y finalmente el nombre.
    results.sort((a, b) {
      final aIsNew = a.id == widget.highlightedApplicantId;
      final bIsNew = b.id == widget.highlightedApplicantId;

      if (aIsNew && !bIsNew) return -1;
      if (!aIsNew && bIsNew) return 1;

      final aDocument = _normalizeSearchText(a.documentNumber);
      final bDocument = _normalizeSearchText(b.documentNumber);

      final aName = _normalizeSearchText('${a.firstName} ${a.lastName}');
      final bName = _normalizeSearchText('${b.firstName} ${b.lastName}');

      final aExact = aDocument == query || aName == query;
      final bExact = bDocument == query || bName == query;

      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      return aName.compareTo(bName);
    });

    return results;
  }

  // =============================================================
  // VERIFICAR RESULTADO DESTACADO
  // =============================================================

  bool _isHighlightedApplicant(ApplicantModel applicant) {
    // Siempre resaltar el aspirante recién registrado.
    if (applicant.id == widget.highlightedApplicantId) {
      return true;
    }

    final query = _normalizeSearchText(_searchQuery);

    if (query.isEmpty) {
      return false;
    }

    final document = _normalizeSearchText(applicant.documentNumber);

    final fullName = _normalizeSearchText(
      '${applicant.firstName} ${applicant.lastName}',
    );

    return document == query || fullName == query;
  }

  // =============================================================
  // LIBERAR RECURSOS
  // =============================================================

  @override
  void dispose() {
    _searchController.dispose();

    _applicantProvider.dispose();

    super.dispose();
  }

  // =============================================================
  // INTERFAZ
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final applicants = _applicantProvider.applicants;

    final filteredApplicants = _getFilteredApplicants(applicants);

    return Scaffold(
      backgroundColor: _isDark
          ? const Color(0xFF101820)
          : const Color(0xFFEAF5FB),

      // =========================================================
      // APP BAR COMPACTA
      // =========================================================
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        toolbarHeight: 58,
        centerTitle: true,
        elevation: 0,
        backgroundColor: _isDark
            ? const Color(0xFF17232F)
            : const Color(0xFFF5FAFD),
        surfaceTintColor: Colors.transparent,
        foregroundColor: _isDark ? Colors.white : const Color(0xFF1E293B),
        title: Text(
          widget.onlyPending ? 'Aspirantes pendientes' : 'Aspirantes',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            letterSpacing: 0.1,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _isDark
                    ? const Color(0xFF263849)
                    : const Color(0xFFDDEEF8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isDark
                      ? const Color(0xFF34495A)
                      : const Color(0xFFC9E2ED),
                ),
              ),
              child: IconButton(
                tooltip: 'Actualizar',
                padding: EdgeInsets.zero,
                onPressed: _loadApplicants,
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 22,
                  color: _isDark ? Colors.white : const Color(0xFF2563A8),
                ),
              ),
            ),
          ),
        ],
      ),
      // =========================================================
      // CONTENIDO
      // =========================================================
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isDark
                ? const [
                    Color(0xFF101820),
                    Color(0xFF15212B),
                    Color(0xFF17251F),
                  ]
                : const [
                    Color(0xFFE6F3FB),
                    Color(0xFFF5FAFB),
                    Color(0xFFEEF9F3),
                  ],
            stops: const [0.0, 0.46, 1.0],
          ),
        ),

        child: _buildBody(applicants, filteredApplicants),
      ),
    );
  }

  // =============================================================
  // CUERPO
  // =============================================================

  Widget _buildBody(
    List<ApplicantModel> applicants,
    List<ApplicantModel> filteredApplicants,
  ) {
    // ===========================================================
    // CARGANDO
    // ===========================================================

    if (_applicantProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563A8)),
      );
    }

    // ===========================================================
    // ERROR
    // ===========================================================

    if (_applicantProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 54,
                color: Colors.redAccent,
              ),

              const SizedBox(height: 16),

              Text(
                _applicantProvider.errorMessage!,
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 16,
                  color: _isDark ? Colors.white : null,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _loadApplicants,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF2563A8),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Intentar nuevamente'),
              ),
            ],
          ),
        ),
      );
    }

    // ===========================================================
    // SIN ASPIRANTES
    // ===========================================================

    if (applicants.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadApplicants,

        color: const Color(0xFF2563A8),

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),

          children: [
            const SizedBox(height: 130),

            Icon(
              Icons.people_outline_rounded,
              size: 72,
              color: _isDark ? Colors.white : const Color(0xFF2563A8),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                'No hay aspirantes registrados.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30),

                child: Text(
                  'Los aspirantes que registres aparecerán aquí.',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 14,
                    color: _isDark ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ===========================================================
    // PAGINACIÓN
    // ===========================================================

    final int totalPages = (filteredApplicants.length / _itemsPerPage).ceil();

    // Evitamos que una página inválida produzca un error.
    final int safeCurrentPage = totalPages == 0
        ? 0
        : _currentPage.clamp(0, totalPages - 1);

    final int startIndex = safeCurrentPage * _itemsPerPage;

    final int endIndex = (startIndex + _itemsPerPage).clamp(
      0,
      filteredApplicants.length,
    );

    final List<ApplicantModel> paginatedApplicants = filteredApplicants.sublist(
      startIndex,
      endIndex,
    );

    return RefreshIndicator(
      onRefresh: _loadApplicants,

      color: const Color(0xFF2563A8),

      child: Column(
        children: [
          // =====================================================
          // BUSCADOR Y FILTROS
          // =====================================================
          _buildSearchSection(),

          // =====================================================
          // CONTADOR CENTRADO DE ASPIRANTES
          // =====================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),

            child: Container(
              width: double.infinity,

              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF1B2935) : Colors.white,
                borderRadius: BorderRadius.circular(17),

                border: Border.all(
                  color: _isDark
                      ? const Color(0xFF344654)
                      : const Color(0xFFD8EAEF),
                ),

                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4C8290).withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // ICONO VERDE MARINO
                  Container(
                    width: 42,
                    height: 42,

                    decoration: BoxDecoration(
                      color: _isDark
                          ? const Color(0xFF3A3022)
                          : const Color(0xFFFFF0DB),
                      borderRadius: BorderRadius.circular(13),
                    ),

                    child: const Icon(
                      Icons.groups_rounded,
                      size: 23,
                      color: Color(0xFFFF9800),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // TOTAL DE ASPIRANTES
                  Flexible(
                    child: Text(
                      _searchQuery.isEmpty
                          ? widget.onlyPending
                                ? '${filteredApplicants.length} '
                                      '${filteredApplicants.length == 1 ? 'aspirante pendiente' : 'aspirantes pendientes'}'
                                : '${applicants.length} '
                                      '${applicants.length == 1 ? 'aspirante registrado' : 'aspirantes registrados'}'
                          : '${filteredApplicants.length} resultados encontrados',

                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===========================================================
          // SIN RESULTADOS
          // ===========================================================
          if (filteredApplicants.isEmpty)
            Expanded(
              child: widget.onlyPending
                  ? _buildEmptyPending()
                  : _buildEmptySearch(),
            )
          // =====================================================
          // RESULTADOS
          // =====================================================
          else
            Expanded(
              child: Column(
                children: [
                  // =============================================
                  // LISTA DE ASPIRANTES
                  // =============================================
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),

                      itemCount: paginatedApplicants.length,

                      itemBuilder: (context, index) {
                        final applicant = paginatedApplicants[index];

                        final isHighlighted = _isHighlightedApplicant(
                          applicant,
                        );

                        return _ApplicantCard(
                          applicant: applicant,

                          isHighlighted: isHighlighted,

                          onTap: () async {
                            await Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (_) =>
                                    ApplicantDetailPage(applicant: applicant),
                              ),
                            );

                            if (mounted) {
                              await _loadApplicants();
                            }
                          },
                        );
                      },
                    ),
                  ),

                  // =============================================
                  // PAGINACIÓN
                  // =============================================
                  if (totalPages > 1)
                    SafeArea(
                      top: false,

                      minimum: const EdgeInsets.only(
                        left: 18,
                        right: 18,
                        top: 4,
                        bottom: 8,
                      ),

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),

                        decoration: BoxDecoration(
                          color: _isDark
                              ? const Color(0xFF1B2935)
                              : Colors.white,

                          borderRadius: BorderRadius.circular(18),

                          border: Border.all(
                            color: _isDark
                                ? const Color(0xFF344654)
                                : const Color(0xFFD8EAE4),
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF4C8290,
                              ).withValues(alpha: 0.07),

                              blurRadius: 10,

                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),

                        child: Row(
                          children: [
                            // ===================================
                            // ANTERIOR
                            // ===================================
                            Expanded(
                              child: OutlinedButton(
                                onPressed: safeCurrentPage > 0
                                    ? () {
                                        setState(() {
                                          _currentPage = safeCurrentPage - 1;
                                        });
                                      }
                                    : null,

                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _isDark
                                      ? Colors.white
                                      : const Color(0xFF2563A8),
                                  disabledForegroundColor: _isDark
                                      ? Colors.white38
                                      : const Color(0xFF9CA3AF),
                                  side: BorderSide(
                                    color: _isDark
                                        ? const Color(0xFF526779)
                                        : const Color(0xFFB8D5E8),
                                  ),
                                  minimumSize: const Size(0, 44),

                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),

                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,

                                  visualDensity: VisualDensity.compact,

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),

                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,

                                  mainAxisSize: MainAxisSize.min,

                                  children: [
                                    Icon(Icons.chevron_left_rounded, size: 22),

                                    SizedBox(width: 3),

                                    Text(
                                      'Anterior',
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,

                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // ===================================
                            // PÁGINA ACTUAL
                            // ===================================
                            SizedBox(
                              width: 92,

                              child: Text(
                                'Página ${safeCurrentPage + 1} de $totalPages',

                                maxLines: 1,

                                softWrap: false,

                                overflow: TextOverflow.ellipsis,

                                textAlign: TextAlign.center,

                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // ===================================
                            // SIGUIENTE
                            // ===================================
                            Expanded(
                              child: OutlinedButton(
                                onPressed: safeCurrentPage < totalPages - 1
                                    ? () {
                                        setState(() {
                                          _currentPage = safeCurrentPage + 1;
                                        });
                                      }
                                    : null,

                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _isDark
                                      ? Colors.white
                                      : const Color(0xFF2563A8),
                                  disabledForegroundColor: _isDark
                                      ? Colors.white38
                                      : const Color(0xFF9CA3AF),
                                  side: BorderSide(
                                    color: _isDark
                                        ? const Color(0xFF526779)
                                        : const Color(0xFFB8D5E8),
                                  ),
                                  minimumSize: const Size(0, 44),

                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),

                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,

                                  visualDensity: VisualDensity.compact,

                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),

                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,

                                  mainAxisSize: MainAxisSize.min,

                                  children: [
                                    Text(
                                      'Siguiente',
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,

                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    SizedBox(width: 3),

                                    Icon(Icons.chevron_right_rounded, size: 22),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // =============================================================
  // BUSCADOR
  // =============================================================

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDark
              ? const [Color(0xFF1D3447), Color(0xFF243F54)]
              : const [Color(0xFFB9DDFF), Color(0xFFD2EAFF)],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _isDark ? const Color(0xFF45657D) : const Color(0xFF8CC5FF),
          width: 1.2,
        ),
      ),

      child: TextField(
        controller: _searchController,

        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _isDark ? Colors.white : const Color(0xFF1E293B),
        ),

        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _currentPage = 0;
          });
        },

        decoration: InputDecoration(
          hintText: 'Buscar por nombre, documento, programa o ubicación',

          hintStyle: TextStyle(
            fontSize: 13,
            color: _isDark ? Colors.white60 : const Color(0xFF94A3B8),
          ),

          prefixIcon: Icon(
            Icons.search_rounded,
            size: 22,
            color: _isDark ? Colors.white : const Color(0xFF2563A8),
          ),

          prefixIconConstraints: const BoxConstraints(minWidth: 46),

          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Limpiar búsqueda',
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchQuery = '';
                      _currentPage = 0;
                    });
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: _isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                )
              : null,

          filled: true,
          fillColor: _isDark ? const Color(0xFF17232F) : Colors.white,

          isDense: true,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF80BFFF), width: 1.2),
          ),
        ),
      ),
    );
  }
  // =============================================================
  // SIN RESULTADOS
  // =============================================================

  Widget _buildEmptySearch() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDCECF8), Color(0xFFF1F5F9)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 36,
                color: _isDark ? Colors.white : const Color(0xFF2563A8),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No encontramos resultados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta buscar por otro nombre, documento o programa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // SIN PENDIENTES
  // =============================================================

  Widget _buildEmptyPending() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF0DB), Color(0xFFFFF8EE)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.cloud_done_outlined,
                size: 36,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No hay aspirantes pendientes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Todos los aspirantes activos ya fueron procesados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// TARJETA DE ASPIRANTE
// =============================================================

class _ApplicantCard extends StatelessWidget {
  final ApplicantModel applicant;

  final VoidCallback onTap;

  final bool isHighlighted;

  const _ApplicantCard({
    required this.applicant,
    required this.onTap,
    required this.isHighlighted,
  });

  String _locationText(ApplicantModel applicant) {
    final parts = <String>[
      applicant.department.trim(),
      applicant.municipality.trim(),
      applicant.corregimiento.trim(),
      applicant.village.trim(),
    ].where((value) => value.isNotEmpty).toList();

    return parts.isEmpty ? 'Ubicación no registrada' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),

      margin: const EdgeInsets.only(bottom: 15),

      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1B2935)
            : isHighlighted
            ? const Color(0xFFEAF7FD)
            : const Color(0xFFFFFFFF),

        borderRadius: BorderRadius.circular(22),

        border: Border.all(
          color: isDark
              ? (isHighlighted
                    ? const Color(0xFF5B9BD5)
                    : const Color(0xFF344654))
              : isHighlighted
              ? const Color(0xFF5B9BD5)
              : const Color(0xFFCDE5DC),

          width: isHighlighted ? 1.5 : 1,
        ),

        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? const Color(0xFF2563A8).withValues(alpha: 0.10)
                : const Color(0xFF4E7C78).withValues(alpha: 0.085),

            blurRadius: isHighlighted ? 16 : 10,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        borderRadius: BorderRadius.circular(22),

        child: InkWell(
          borderRadius: BorderRadius.circular(22),

          onTap: onTap,

          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(17),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // =========================================
                    // ICONO DEL ASPIRANTE
                    // =========================================
                    Container(
                      width: 58,
                      height: 58,

                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,

                          end: Alignment.bottomRight,

                          colors: isDark
                              ? const [Color(0xFF29445A), Color(0xFF223B4B)]
                              : isHighlighted
                              ? const [Color(0xFFDCEEFF), Color(0xFFEAF5FF)]
                              : const [Color(0xFFDCEEFF), Color(0xFFE5F6EE)],
                        ),

                        borderRadius: BorderRadius.circular(18),

                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3A5263)
                              : const Color(0xFFC6E2DD),
                        ),
                      ),

                      child: Icon(
                        Icons.person_outline_rounded,

                        color: isDark ? Colors.white : const Color(0xFF2563A8),

                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 15),

                    // =========================================
                    // INFORMACIÓN
                    // =========================================
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // ===================================
                          // RESULTADO DESTACADO
                          // ===================================
                          if (isHighlighted) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),

                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF29445A)
                                    : const Color(0xFFE0F0FF),

                                borderRadius: BorderRadius.circular(10),
                              ),

                              child: Row(
                                mainAxisSize: MainAxisSize.min,

                                children: [
                                  Icon(
                                    Icons.check_circle_outline,

                                    size: 13,

                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF2563A8),
                                  ),

                                  SizedBox(width: 4),

                                  Text(
                                    'Resultado encontrado',

                                    style: TextStyle(
                                      fontSize: 10,

                                      fontWeight: FontWeight.w800,

                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF2563A8),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 9),
                          ],

                          // ===================================
                          // NOMBRE
                          // ===================================
                          Text(
                            '${applicant.firstName} '
                            '${applicant.lastName}',

                            maxLines: 2,

                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              fontSize: 17,

                              fontWeight: FontWeight.w800,

                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ===================================
                          // DOCUMENTO
                          // ===================================
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,

                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2A3945)
                                      : const Color(0xFFF1F6F7),

                                  borderRadius: BorderRadius.circular(8),
                                ),

                                child: Icon(
                                  Icons.badge_outlined,

                                  size: 15,

                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF64748B),
                                ),
                              ),

                              const SizedBox(width: 7),

                              Expanded(
                                child: Text(
                                  '${applicant.documentType}: '
                                  '${applicant.documentNumber}',

                                  style: TextStyle(
                                    fontSize: 13,

                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 9),

                          // ===================================
                          // PROGRAMA
                          // ===================================
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,

                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF263B32)
                                      : const Color(0xFFECFDF5),

                                  borderRadius: BorderRadius.circular(8),
                                ),

                                child: Icon(
                                  Icons.school_outlined,

                                  size: 15,

                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF15803D),
                                ),
                              ),

                              const SizedBox(width: 7),

                              Expanded(
                                child: Text(
                                  applicant.program,

                                  maxLines: 2,

                                  overflow: TextOverflow.ellipsis,

                                  style: TextStyle(
                                    fontSize: 13,

                                    fontWeight: FontWeight.w700,

                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF2563A8),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // ===================================
                          // ESCOLARIDAD
                          // ===================================
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF302B40)
                                      : const Color(0xFFF5F3FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.menu_book_outlined,
                                  size: 15,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF7C3AED),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  applicant.schooling.isEmpty
                                      ? 'Escolaridad no registrada'
                                      : applicant.schooling,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // ===================================
                          // UBICACIÓN
                          // ===================================
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF263B32)
                                      : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  _locationText(applicant),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          _SyncStatusBadge(status: applicant.syncStatus),
                        ],
                      ),
                    ),

                    // =========================================
                    // FLECHA
                    // =========================================
                    Padding(
                      padding: const EdgeInsets.only(top: 15),

                      child: Icon(
                        Icons.chevron_right_rounded,

                        color: isDark
                            ? Colors.white70
                            : isHighlighted
                            ? const Color(0xFF2563A8)
                            : const Color(0xFF94A3B8),

                        size: 29,
                      ),
                    ),
                  ],
                ),
              ),

              // ===============================================
              // ACENTO LATERAL
              // ===============================================
              Positioned(
                left: 0,
                top: 22,
                bottom: 22,

                child: Container(
                  width: 6,

                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? const Color(0xFF2563A8)
                        : const Color(0xFF1E9B5A).withValues(alpha: 0.62),

                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(8),
                    ),
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
// ESTADO DE SINCRONIZACIÓN
// =============================================================

class _SyncStatusBadge extends StatelessWidget {
  final String status;

  const _SyncStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalizedStatus = status.toLowerCase();

    Color backgroundColor;
    Color iconColor;
    Color textColor;
    IconData icon;

    // ===========================================================
    // SINCRONIZADO
    // ===========================================================

    if (normalizedStatus.contains('sincronizado') ||
        normalizedStatus.contains('completado')) {
      backgroundColor = isDark
          ? const Color(0xFF203A30)
          : const Color(0xFFECFDF5);

      iconColor = isDark ? const Color(0xFF8BE0A5) : const Color(0xFF16A34A);

      textColor = isDark ? Colors.white : const Color(0xFF15803D);

      icon = Icons.cloud_done_rounded;
    }
    // ===========================================================
    // ERROR
    // ===========================================================
    else if (normalizedStatus.contains('error') ||
        normalizedStatus.contains('fallido')) {
      backgroundColor = isDark
          ? const Color(0xFF43272A)
          : const Color(0xFFFEF2F2);

      iconColor = isDark ? const Color(0xFFFF8A8A) : const Color(0xFFDC2626);

      textColor = isDark ? Colors.white : const Color(0xFFB91C1C);

      icon = Icons.error_outline_rounded;
    }
    // ===========================================================
    // PENDIENTE
    // ===========================================================
    else {
      backgroundColor = isDark
          ? const Color(0xFF40351F)
          : const Color(0xFFFFF8E8);

      iconColor = isDark ? const Color(0xFFFFC766) : const Color(0xFFD97706);

      textColor = isDark ? Colors.white : const Color(0xFF9A6700);

      icon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),

      decoration: BoxDecoration(
        color: backgroundColor,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: iconColor.withValues(alpha: 0.12)),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, size: 15, color: iconColor),

          const SizedBox(width: 6),

          Text(
            status,

            style: TextStyle(
              fontSize: 12,

              fontWeight: FontWeight.w700,

              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
