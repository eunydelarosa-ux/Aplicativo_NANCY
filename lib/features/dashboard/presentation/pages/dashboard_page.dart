// =============================================================
// APLICATIVO NANCY
// Página principal - Dashboard
// =============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../applicants/models/applicant_model.dart';
import '../../../applicants/providers/applicant_provider.dart';
import '../../../applicants/repositories/applicant_repository.dart';
import '../../../applicants/presentation/pages/applicant_list_page.dart';

import '../widgets/dashboard_drawer.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_menu_card.dart';
import '../widgets/dashboard_stats.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Solo controla colores visuales; no modifica la lógica del Dashboard.
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  // =============================================================
  // PROVIDER DE ASPIRANTES
  // =============================================================

  final ApplicantProvider _applicantProvider = ApplicantProvider();

  final ApplicantRepository _applicantRepository = ApplicantRepository();

  int _syncedHistoryCount = 0;

  // =============================================================
  // CONTROLADOR DEL BUSCADOR
  // =============================================================

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  int _profileHeaderKey = 0;

  // =============================================================
  // SCAFFOLD
  // =============================================================

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final ScrollController _informationScrollController = ScrollController();

  final ScrollController _newsScrollController = ScrollController();

  int _informationPage = 0;
  int _newsPage = 0;

  static const double _carouselCardWidth = 335;
  static const double _carouselGap = 10;

  // =============================================================
  // CICLO DE VIDA
  // =============================================================

  @override
  void initState() {
    super.initState();

    _informationScrollController.addListener(_updateInformationPage);

    _newsScrollController.addListener(_updateNewsPage);

    _loadApplicants();
  }

  // =============================================================
  // CARGAR ASPIRANTES
  // =============================================================

  Future<void> _loadApplicants() async {
    await _applicantProvider.loadApplicants();
    await _loadSyncHistoryCount();

    if (!mounted) return;

    setState(() {});
  }

  // =============================================================
  // CARGAR CANTIDAD DEL HISTORIAL
  // =============================================================

  Future<void> _loadSyncHistoryCount() async {
    try {
      final List<Map<String, dynamic>> rows = await _applicantRepository
          .getSyncHistory();

      int successfulCount = 0;

      for (final Map<String, dynamic> row in rows) {
        final String status = (row['status'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        final bool successful =
            status == 'sincronizado' ||
            status == 'sincronizados' ||
            status == 'synced';

        if (successful) {
          successfulCount++;
        }
      }

      _syncedHistoryCount = successfulCount;
    } catch (_) {
      _syncedHistoryCount = 0;
    }
  }

  // =============================================================
  // ACTUALIZAR PÁGINA INFORMACIÓN
  // =============================================================

  void _updateInformationPage() {
    if (!_informationScrollController.hasClients) return;

    final page =
        (_informationScrollController.offset /
                (_carouselCardWidth + _carouselGap))
            .round();

    final newPage = page.clamp(0, 2);

    if (newPage != _informationPage && mounted) {
      setState(() {
        _informationPage = newPage;
      });
    }
  }

  // =============================================================
  // ACTUALIZAR PÁGINA NOVEDADES
  // =============================================================

  void _updateNewsPage() {
    if (!_newsScrollController.hasClients) return;

    final page =
        (_newsScrollController.offset / (_carouselCardWidth + _carouselGap))
            .round();

    final newPage = page.clamp(0, 2);

    if (newPage != _newsPage && mounted) {
      setState(() {
        _newsPage = newPage;
      });
    }
  }

  // =============================================================
  // LIBERAR RECURSOS
  // =============================================================

  @override
  void dispose() {
    _informationScrollController.removeListener(_updateInformationPage);

    _informationScrollController.dispose();

    _newsScrollController.removeListener(_updateNewsPage);

    _newsScrollController.dispose();

    _searchController.dispose();

    _applicantProvider.dispose();

    super.dispose();
  }

  // =============================================================
  // BUSCADOR
  // =============================================================
  List<ApplicantModel> _getSearchResults() {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return [];
    }

    return _applicantProvider.applicants.where((applicant) {
      final firstName = applicant.firstName.toLowerCase();

      final lastName = applicant.lastName.toLowerCase();

      final documentNumber = applicant.documentNumber.toLowerCase();

      final program = applicant.program.toLowerCase();

      final department = applicant.department.toLowerCase();

      final municipality = applicant.municipality.toLowerCase();

      final corregimiento = applicant.corregimiento.toLowerCase();

      final village = applicant.village.toLowerCase();

      return firstName.contains(query) ||
          lastName.contains(query) ||
          documentNumber.contains(query) ||
          program.contains(query) ||
          department.contains(query) ||
          municipality.contains(query) ||
          corregimiento.contains(query) ||
          village.contains(query);
    }).toList();
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final applicants = _applicantProvider.applicants;

    // -----------------------------------------------------------
    // PENDIENTES
    // -----------------------------------------------------------

    final int pendingCount = applicants.where((applicant) {
      final status = applicant.syncStatus.toLowerCase().trim();

      return status == 'pendiente' || status == 'pending';
    }).length;

    // -----------------------------------------------------------
    // SINCRONIZADOS
    // -----------------------------------------------------------

    final int syncedCount = _syncedHistoryCount;
    // -----------------------------------------------------------
    // RESULTADOS DEL BUSCADOR
    // -----------------------------------------------------------

    final searchResults = _getSearchResults();

    // ===========================================================
    // SCAFFOLD
    // ===========================================================

    return Scaffold(
      key: _scaffoldKey,

      // =========================================================
      // MENÚ LATERAL
      // =========================================================
      drawer: const DashboardDrawer(),

      // =========================================================
      // FONDO AZUL CLARO
      // =========================================================
      // En modo claro se conserva exactamente el color original.
      // En modo oscuro se adapta únicamente el color base del Scaffold.
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF101820)
          : const Color(0xFFEAF6FF),

      // =========================================================
      // CUERPO
      // =========================================================
      body: Container(
        decoration: isDark
            ? const BoxDecoration(color: Color(0xFF101820))
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    // Azul del fondo de la imagen
                    Color(0xFF0057B8),

                    // Azul del logo
                    Color(0xFF0A3D91),

                    // Azul claro intermedio
                    Color(0xFF9DD0EE),

                    // Transición hacia blanco
                    Color(0xFFEAF6FC),

                    // Blanco total (Información, Gestión, Novedades)
                    Colors.white,
                    Colors.white,
                    Colors.white,

                    // Inicio verde muy claro
                    Color(0xFFE1F4E9),

                    // Verde intermedio
                    Color(0xFFCBEAD9),

                    // Verde del logo (borde inferior)
                    Color(0xFF4CAF50),
                  ],
                  stops: [
                    0.00, // Azul fondo
                    0.10, // Azul logo
                    0.20, // Azul claro
                    0.28, // Transición
                    0.34, // Blanco antes de Información
                    0.48, // Blanco en Información + Gestión
                    0.68, // Blanco hasta después de Novedades
                    0.84, // Verde muy claro
                    0.93, // Verde intermedio
                    1.00, // Verde logo inferior
                  ],
                ),
              ),

        child: SafeArea(
          child: Column(
            children: [
              // =================================================
              // ENCABEZADO
              // =================================================
              DashboardHeader(
                key: ValueKey(_profileHeaderKey),
                pendingCount: pendingCount,
              ),

              // =================================================
              // CONTENIDO
              // =================================================
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadApplicants,

                  color: const Color(0xFF1976C9),

                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),

                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        // =========================================
                        // BÚSQUEDA
                        // =========================================
                        _buildSearchBar(),

                        // =========================================
                        // RESULTADOS
                        // =========================================
                        if (_searchQuery.isNotEmpty &&
                            !_applicantProvider.isLoading) ...[
                          const SizedBox(height: 9),
                          _buildSearchResults(searchResults),
                        ],
                        const SizedBox(height: 13),

                        // =========================================
                        // INFORMACIÓN
                        // =========================================
                        Text(
                          'Información',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFE5EDF5)
                                : const Color(0xFF17345F),
                          ),
                        ),

                        const SizedBox(height: 9),

                        _buildInformationCarousel(),

                        const SizedBox(height: 18),

                        // =========================================
                        // EXPLORAR
                        // =========================================
                        Text(
                          'Gestión',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFE5EDF5)
                                : const Color(0xFF17345F),
                          ),
                        ),

                        const SizedBox(height: 9),

                        // =========================================
                        // CUATRO TARJETAS
                        // =========================================
                        GridView.count(
                          crossAxisCount: 2,

                          shrinkWrap: true,

                          physics: const NeverScrollableScrollPhysics(),

                          crossAxisSpacing: 11,

                          mainAxisSpacing: 11,

                          childAspectRatio: 1.02,

                          children: [
                            // =====================================
                            // REGISTRAR
                            // =====================================
                            DashboardMenuCard(
                              icon: Icons.person_add_alt_1_rounded,

                              title: 'Registrar Aspirante',

                              subtitle: 'Nueva inscripción',

                              color: const Color(0xFF168A4A),

                              onTap: () {
                                context.push('/register-applicant');
                              },
                            ),

                            // =====================================
                            // LISTA
                            // =====================================
                            DashboardMenuCard(
                              icon: Icons.groups_rounded,

                              title: 'Lista ',

                              subtitle: 'Registros guardados',

                              color: const Color(0xFF1268D5),

                              onTap: () {
                                context.push('/applicants');
                              },
                            ),

                            // =====================================
                            // SINCRONIZACIÓN
                            // =====================================
                            DashboardMenuCard(
                              icon: Icons.sync_rounded,

                              title: 'Sincronización',

                              subtitle: 'Estado de datos',

                              color: const Color(0xFFF28C00),

                              onTap: () async {
                                await context.push('/sync');
                                await _loadApplicants();
                              },
                            ),
                            // =====================================
                            // CATÁLOGOS
                            // =====================================
                            DashboardMenuCard(
                              icon: Icons.menu_book_rounded,

                              title: 'Gestionar Datos',

                              subtitle: 'Configurar formulario ',

                              color: const Color(0xFF078FA3),

                              onTap: () {
                                context.push('/catalogs');
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // =========================================
                        // NOVEDADES
                        // =========================================
                        Text(
                          'Novedades',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFFE5EDF5)
                                : const Color(0xFF17345F),
                          ),
                        ),

                        const SizedBox(height: 9),

                        _buildNewsCarousel(),

                        const SizedBox(height: 15),

                        // =========================================
                        // ESTADÍSTICAS
                        // =========================================
                        Container(
                          width: double.infinity,

                          padding: const EdgeInsets.symmetric(vertical: 5),

                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1B2733)
                                : const Color(0xFFFAFAFA),

                            borderRadius: BorderRadius.circular(25),

                            border: Border.all(
                              color: const Color(0xFFD6E8F5),
                              width: 1.2,
                            ),
                          ),

                          child: DashboardStats(
                            pending: pendingCount,

                            synced: syncedCount,

                            onPendingTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ApplicantListPage(
                                    onlyPending: true,
                                  ),
                                ),
                              );

                              await _loadApplicants();
                            },

                            onSyncedTap: () async {
                              await context.push('/history');
                              await _loadApplicants();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // =================================================
              // BARRA INFERIOR
              // =================================================
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // BARRA DE BÚSQUEDA
  // =============================================================

  Widget _buildSearchBar() {
    return Row(
      children: [
        // =======================================================
        // BUSCADOR
        // =======================================================
        Expanded(
          child: Container(
            height: 50,

            padding: const EdgeInsets.symmetric(horizontal: 15),

            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1B2733)
                  : Colors.white,

              borderRadius: BorderRadius.circular(18),

              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1B2733)
                    : Colors.white,
                width: 1.4,
              ),

              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7EA9C2).withValues(alpha: 0.11),

                  blurRadius: 15,

                  offset: const Offset(0, 5),
                ),
              ],
            ),

            child: TextField(
              controller: _searchController,

              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },

              style: TextStyle(
                fontSize: 14,
                color: _isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF263B55),
                fontWeight: FontWeight.w500,
              ),

              decoration: InputDecoration(
                border: InputBorder.none,

                enabledBorder: InputBorder.none,

                focusedBorder: InputBorder.none,

                disabledBorder: InputBorder.none,

                errorBorder: InputBorder.none,

                focusedErrorBorder: InputBorder.none,

                filled: false,

                fillColor: Colors.transparent,

                hoverColor: Colors.transparent,

                focusColor: Colors.transparent,

                isDense: true,

                contentPadding: const EdgeInsets.symmetric(vertical: 14),

                hintText: 'Buscar aspirante, documento, programa...',

                hintStyle: TextStyle(
                  fontSize: 13,
                  color: _isDark
                      ? const Color(0xFFB0BECC)
                      : const Color(0xFF73859A),
                ),

                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: _isDark
                      ? const Color(0xFFB0BECC)
                      : const Color(0xFF54718C),
                  size: 25,
                ),

                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _searchQuery = '';
                          });
                        },

                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF8A9AAD),
                          size: 20,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),

        const SizedBox(width: 9),

        // =======================================================
        // PREFERENCIAS
        // =======================================================
        Material(
          color: Colors.transparent,

          child: InkWell(
            onTap: () {
              context.push('/configuration/preferences');
            },

            borderRadius: BorderRadius.circular(17),

            child: Container(
              width: 50,
              height: 50,

              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F7),

                borderRadius: BorderRadius.circular(17),

                border: Border.all(color: const Color(0xFFD4EFEC)),

                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF168A9B).withValues(alpha: 0.08),

                    blurRadius: 10,

                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: const Icon(
                Icons.tune_rounded,
                color: Color(0xFF168A9B),
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // RESULTADOS DEL BUSCADOR
  // =============================================================

  Widget _buildSearchResults(List<ApplicantModel> results) {
    if (results.isEmpty) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),

        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1B2733)
              : Colors.white.withValues(alpha: 0.94),

          borderRadius: BorderRadius.circular(18),

          border: Border.all(color: const Color(0xFFDDEAF1)),
        ),

        child: Row(
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: Color(0xFF7D92A5),
              size: 23,
            ),

            SizedBox(width: 10),

            Expanded(
              child: Text(
                'No encontramos aspirantes que coincidan con la búsqueda.',
                style: TextStyle(
                  fontSize: 13,
                  color: _isDark
                      ? const Color(0xFFB0BECC)
                      : const Color(0xFF718396),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final visibleResults = results.take(5).toList();

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(vertical: 6),

      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B2733)
            : Colors.white.withValues(alpha: 0.96),

        borderRadius: BorderRadius.circular(19),

        border: Border.all(color: const Color(0xFFDDEAF1)),

        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7FA5BB).withValues(alpha: 0.10),

            blurRadius: 14,

            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 7, 14, 5),

            child: Row(
              children: [
                const Icon(
                  Icons.people_alt_outlined,
                  size: 19,
                  color: Color(0xFF2D8FE5),
                ),

                const SizedBox(width: 8),

                Text(
                  results.length == 1
                      ? '1 aspirante encontrado'
                      : '${results.length} aspirantes encontrados',

                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF294765),
                  ),
                ),
              ],
            ),
          ),

          ...visibleResults.map(
            (applicant) => _buildSearchResultItem(applicant),
          ),

          if (results.length > 5)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 3, 14, 9),

              child: Text(
                'Hay más resultados. Refina tu búsqueda.',
                style: TextStyle(
                  fontSize: 11,
                  color: _isDark
                      ? const Color(0xFFB0BECC)
                      : const Color(0xFF8394A4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =============================================================
  // RESULTADO INDIVIDUAL
  // =============================================================

  Widget _buildSearchResultItem(ApplicantModel applicant) {
    final fullName = '${applicant.firstName} ${applicant.lastName}'.trim();

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();

          final search = Uri.encodeComponent(applicant.documentNumber);

          context.push('/applicants?search=$search');
        },

        borderRadius: BorderRadius.circular(15),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

          child: Container(
            padding: const EdgeInsets.all(11),

            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF243341)
                  : const Color(0xFFF8FBFD),

              borderRadius: BorderRadius.circular(15),

              border: Border.all(color: const Color(0xFFE5EEF3)),
            ),

            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,

                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FF),

                    borderRadius: BorderRadius.circular(13),

                    border: Border.all(color: const Color(0xFFD4E7F7)),
                  ),

                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF2D8FE5),
                    size: 23,
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        fullName.isEmpty ? 'Aspirante' : fullName,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _isDark
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF243B55),
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'Documento: ${applicant.documentNumber}',

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 11.5,
                          color: _isDark
                              ? const Color(0xFFB0BECC)
                              : const Color(0xFF718396),
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        applicant.program.trim().isEmpty
                            ? 'Programa no especificado'
                            : applicant.program,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF168A9B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 5),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9BAEBC),
                  size: 23,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // CARRUSEL DE INFORMACIÓN
  // =============================================================

  Widget _buildInformationCarousel() {
    final List<_DashboardInfoItem> items = [
      const _DashboardInfoItem(
        icon: Icons.fact_check_outlined,

        title: 'Datos completos',

        description:
            'Verifica que la información del aspirante esté completa antes de guardar.',

        color: Color(0xFF1976D2),

        background: Color(0xFFEAF4FF),
      ),

      const _DashboardInfoItem(
        icon: Icons.verified_user_outlined,

        title: 'Revisa antes de enviar',

        description:
            'Comprueba documentos, datos personales y programa seleccionado.',

        color: Color(0xFF168A4A),

        background: Color(0xFFEAF7EF),
      ),

      const _DashboardInfoItem(
        icon: Icons.cloud_outlined,

        title: 'Trabajo seguro',

        description:
            'Los registros pendientes permanecen disponibles para su sincronización.',

        color: Color(0xFF5B2A91),

        background: Color(0xFFF1EAF9),
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 126,

          child: ListView.separated(
            controller: _informationScrollController,

            scrollDirection: Axis.horizontal,

            physics: const BouncingScrollPhysics(),

            itemCount: items.length,

            separatorBuilder: (_, _) => const SizedBox(width: 10),

            itemBuilder: (context, index) {
              return _buildHorizontalInfoCard(items[index]);
            },
          ),
        ),

        const SizedBox(height: 7),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            _buildCarouselDot(_informationPage == 0),

            const SizedBox(width: 5),

            _buildCarouselDot(_informationPage == 1),

            const SizedBox(width: 5),

            _buildCarouselDot(_informationPage == 2),
          ],
        ),
      ],
    );
  }

  // =============================================================
  // TARJETA DE INFORMACIÓN
  // =============================================================

  Widget _buildHorizontalInfoCard(_DashboardInfoItem item) {
    return Container(
      width: 335,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: _isDark
              ? const [Color(0xFF202D38), Color(0xFF263746), Color(0xFF202D38)]
              : [
                  Colors.white,
                  item.background.withValues(alpha: 0.72),
                  Colors.white.withValues(alpha: 0.96),
                ],
        ),

        borderRadius: BorderRadius.circular(23),

        border: Border.all(
          color: item.color.withValues(alpha: _isDark ? 0.38 : 0.18),
          width: 1.2,
        ),

        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.07),

            blurRadius: 12,

            spreadRadius: 0,

            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          // =====================================================
          // ICONO
          // =====================================================
          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,

                colors: _isDark
                    ? [
                        item.color.withValues(alpha: 0.22),
                        const Color(0xFF263746),
                      ]
                    : [item.background, item.color.withValues(alpha: 0.07)],
              ),

              borderRadius: BorderRadius.circular(16),

              border: Border.all(
                color: item.color.withValues(alpha: 0.18),

                width: 1.1,
              ),
            ),

            child: Icon(item.icon, color: item.color, size: 28),
          ),

          const SizedBox(width: 12),

          // =====================================================
          // TEXTO
          // =====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Text(
                  item.title,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _isDark ? const Color(0xFFE5EDF5) : item.color,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  item.description,

                  maxLines: 3,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: _isDark
                        ? const Color(0xFFD5DEE7)
                        : const Color(0xFF536783),
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
  // CARRUSEL DE NOVEDADES
  // =============================================================

  Widget _buildNewsCarousel() {
    final List<_DashboardNewsItem> news = [
      const _DashboardNewsItem(
        icon: Icons.auto_awesome_rounded,

        title: 'Bienvenido a Nancy',

        subtitle: 'Sistema Integral de Inscripciones',

        description:
            'Una herramienta pensada para facilitar el registro de aspirantes.',

        color: Color(0xFF168A4A),

        background: Color(0xFFF0FAF4),
      ),

      const _DashboardNewsItem(
        icon: Icons.campaign_outlined,

        title: 'Novedades',

        subtitle: 'Mantente informado',

        description:
            'Aquí podrás encontrar avisos y novedades importantes del aplicativo.',

        color: Color(0xFF1268D5),

        background: Color(0xFFF0F6FF),
      ),

      const _DashboardNewsItem(
        icon: Icons.lightbulb_outline_rounded,

        title: 'Recomendación',

        subtitle: 'Antes de guardar',

        description:
            'Revisa los datos ingresados para mantener registros completos y organizados.',

        color: Color(0xFFF28C00),

        background: Color(0xFFFFF6E8),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        SizedBox(
          width: double.infinity,

          height: 138,

          child: ListView.separated(
            controller: _newsScrollController,

            scrollDirection: Axis.horizontal,

            physics: const BouncingScrollPhysics(),

            padding: EdgeInsets.zero,

            itemCount: news.length,

            separatorBuilder: (context, index) {
              return const SizedBox(width: 10);
            },

            itemBuilder: (context, index) {
              return _buildHorizontalNewsCard(news[index]);
            },
          ),
        ),

        const SizedBox(height: 7),

        // =========================================================
        // INDICADORES
        // =========================================================
        Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            _buildCarouselDot(_newsPage == 0),

            const SizedBox(width: 5),

            _buildCarouselDot(_newsPage == 1),

            const SizedBox(width: 5),

            _buildCarouselDot(_newsPage == 2),
          ],
        ),
      ],
    );
  }

  // =============================================================
  // TARJETA DE NOVEDAD
  // =============================================================

  Widget _buildHorizontalNewsCard(_DashboardNewsItem item) {
    return Container(
      width: 335,

      height: 138,

      decoration: BoxDecoration(
        // =======================================================
        // FONDO
        // =======================================================
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: _isDark
              ? const [Color(0xFF202D38), Color(0xFF263746), Color(0xFF202D38)]
              : [
                  Colors.white,
                  item.background.withValues(alpha: 0.78),
                  Colors.white.withValues(alpha: 0.96),
                ],
        ),

        // =======================================================
        // BORDE GENERAL
        // =======================================================
        border: Border.all(
          color: item.color.withValues(alpha: _isDark ? 0.38 : 0.18),

          width: 1.2,
        ),

        borderRadius: BorderRadius.circular(23),

        // =======================================================
        // SOMBRA
        // =======================================================
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.09),

            blurRadius: 12,

            spreadRadius: 0,

            offset: const Offset(0, 5),
          ),
        ],
      ),

      // =========================================================
      // STACK
      // =========================================================
      child: Stack(
        children: [
          // =====================================================
          // CONTENIDO
          // =====================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                // ===============================================
                // ICONO
                // ===============================================
                Container(
                  width: 66,

                  height: 100,

                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,

                      end: Alignment.bottomRight,

                      colors: [
                        item.color.withValues(alpha: 0.18),

                        item.color.withValues(alpha: 0.06),
                      ],
                    ),

                    borderRadius: BorderRadius.circular(19),

                    border: Border.all(
                      color: item.color.withValues(alpha: 0.22),

                      width: 1.1,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: item.color.withValues(alpha: 0.07),

                        blurRadius: 7,

                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),

                  child: Center(
                    child: Icon(item.icon, color: item.color, size: 34),
                  ),
                ),

                const SizedBox(width: 13),

                // ===============================================
                // INFORMACIÓN
                // ===============================================
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // =========================================
                      // TÍTULO
                      // =========================================
                      Text(
                        item.title,

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 15,

                          fontWeight: FontWeight.w800,

                          height: 1.1,

                          color: _isDark ? const Color(0xFFE5EDF5) : item.color,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // =========================================
                      // SUBTÍTULO
                      // =========================================
                      Text(
                        item.subtitle,

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 11.5,

                          fontWeight: FontWeight.w600,

                          height: 1.15,

                          color: _isDark
                              ? const Color(0xFFD5DEE7)
                              : const Color(0xFF53687E),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // =========================================
                      // DESCRIPCIÓN
                      // =========================================
                      Text(
                        item.description,

                        maxLines: 3,

                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 11.5,

                          height: 1.25,

                          color: _isDark
                              ? const Color(0xFFB0BECC)
                              : const Color(0xFF68798C),
                        ),
                      ),
                    ],
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
  // INDICADOR DEL CARRUSEL
  // =============================================================

  Widget _buildCarouselDot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),

      width: active ? 18 : 6,

      height: 5,

      decoration: BoxDecoration(
        color: active ? const Color(0xFF1976C9) : const Color(0xFFC7D5DF),

        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // =============================================================
  // BARRA INFERIOR
  // =============================================================

  Widget _buildBottomNavigation() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 5, 0, 0),

      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),

      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1B2733)
            : Colors.white,

        border: Border(
          top: BorderSide(
            color: Color.fromARGB(255, 242, 245, 247),

            width: 1.2,
          ),
        ),
      ),

      child: Row(
        children: [
          // =====================================================
          // MENÚ
          // =====================================================
          Expanded(
            child: _buildBottomItem(
              icon: Icons.grid_view_rounded,

              label: 'Menú',

              active: true,

              onTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ),

          // =====================================================
          // CALENDARIO
          // =====================================================
          Expanded(
            child: _buildBottomItem(
              icon: Icons.calendar_month_outlined,

              label: 'Calendario',

              onTap: () {
                context.push('/calendar');
              },
            ),
          ),

          // =====================================================
          // EXPORTACIONES
          // =====================================================
          Expanded(
            child: _buildBottomItem(
              icon: Icons.file_upload_outlined,

              label: 'Exportaciones',

              onTap: () {
                context.push('/exports');
              },
            ),
          ),

          // =====================================================
          // PERFIL
          // =====================================================
          Expanded(
            child: _buildBottomItem(
              icon: Icons.person_outline_rounded,

              label: 'Perfil',

              onTap: () async {
                // Abrir la pantalla del perfil.
                await context.push('/profile');

                // Verificar que el Dashboard siga activo.
                if (!mounted) return;

                // Actualizar el encabezado al regresar.
                setState(() {
                  _profileHeaderKey++;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // ITEM DE BARRA INFERIOR
  // =============================================================

  Widget _buildBottomItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(17),

        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),

          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft,

                    end: Alignment.bottomRight,

                    colors: [Color(0xFFEAF4FF), Color(0xFFE8F7F3)],
                  )
                : null,

            borderRadius: BorderRadius.circular(17),

            border: active
                ? Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1B2733)
                        : Colors.white,
                    width: 1,
                  )
                : null,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Icon(
                icon,

                size: 25,

                color: active
                    ? const Color(0xFF1976C9)
                    : (_isDark
                          ? const Color(0xFFB0BECC)
                          : const Color.fromARGB(255, 12, 12, 12)),
              ),

              const SizedBox(height: 2),

              Text(
                label,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: 9.8,

                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,

                  color: active
                      ? const Color(0xFF1976C9)
                      : (_isDark
                            ? const Color(0xFFB0BECC)
                            : const Color.fromARGB(255, 8, 8, 8)),
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
// MODELO INTERNO - INFORMACIÓN
// =============================================================

class _DashboardInfoItem {
  final IconData icon;

  final String title;

  final String description;

  final Color color;

  final Color background;

  const _DashboardInfoItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.background,
  });
}

// =============================================================
// MODELO INTERNO - NOVEDADES
// =============================================================

class _DashboardNewsItem {
  final IconData icon;

  final String title;

  final String subtitle;

  final String description;

  final Color color;

  final Color background;

  const _DashboardNewsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
    required this.background,
  });
}
