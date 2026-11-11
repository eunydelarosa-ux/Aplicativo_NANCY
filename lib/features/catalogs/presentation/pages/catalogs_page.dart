// =============================================================
// APLICATIVO NANCY
// Página principal de Catálogos
// =============================================================

import 'package:flutter/material.dart';

import '../../providers/catalog_provider.dart';
import 'catalog_manager_page.dart';

class CatalogsPage extends StatefulWidget {
  const CatalogsPage({super.key});

  @override
  State<CatalogsPage> createState() => _CatalogsPageState();
}

class _CatalogsPageState extends State<CatalogsPage> {
  // =============================================================
  // PROVIDER
  // =============================================================

  late final CatalogProvider _provider;

  // =============================================================
  // CICLO DE VIDA
  // =============================================================

  @override
  void initState() {
    super.initState();

    _provider = CatalogProvider();

    _provider.addListener(_onProviderChanged);

    _provider.loadAll();
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();

    super.dispose();
  }

  // =============================================================
  // ACTUALIZAR INTERFAZ
  // =============================================================

  void _onProviderChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
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
          : const Color(0xFFF7F9FD),

      // =========================================================
      // APP BAR
      // =========================================================
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF17232E) : Colors.white,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? const Color(0xFFE6EDF5) : const Color(0xFF26364F),
            size: 28,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          'Gestionar Datos',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2A44),
          ),
        ),
      ),

      // =========================================================
      // CONTENIDO
      // =========================================================
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===================================================
              // ENCABEZADO
              // ===================================================
              Text(
                'INFORMACIÓN DEL SISTEMA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: isDark
                      ? const Color(0xFFB6C2CE)
                      : const Color(0xFF788497),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Administra las opciones que utiliza '
                'Aplicativo Nancy en sus formularios.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDark
                      ? const Color(0xFFB6C2CE)
                      : const Color(0xFF8793A5),
                ),
              ),

              const SizedBox(height: 20),

              // ===================================================
              // PROGRAMAS
              // ===================================================
              _buildCatalogCard(
                context: context,
                icon: Icons.school_outlined,
                iconColor: const Color(0xFF2D8FE5),
                title: 'Programas',
                description: 'Programas de formación disponibles.',
                catalogType: 'program',
              ),

              const SizedBox(height: 14),

              // ===================================================
              // TIPOS DE DOCUMENTO
              // ===================================================
              _buildCatalogCard(
                context: context,
                icon: Icons.badge_outlined,
                iconColor: const Color(0xFF4CAF50),
                title: 'Tipos de documento',
                description:
                    'Documentos utilizados para identificar '
                    'a los aspirantes.',
                catalogType: 'document_type',
              ),

              const SizedBox(height: 14),

              // ===================================================
              // GÉNEROS
              // ===================================================
              _buildCatalogCard(
                context: context,
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFFEC4899),
                title: 'Géneros',
                description: 'Opciones de género utilizadas en el registro.',
                catalogType: 'gender',
              ),

              const SizedBox(height: 14),

              // ===================================================
              // ESCOLARIDAD
              // ===================================================
              _buildCatalogCard(
                context: context,
                icon: Icons.school_rounded,
                iconColor: const Color(0xFF14B8A6),
                title: 'Escolaridad',
                description:
                    'Niveles de escolaridad utilizados en el registro.',
                catalogType: 'schooling',
              ),

              const SizedBox(height: 28),

              // ===================================================
              // INFORMACIÓN
              // ===================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A2A37)
                      : const Color(0xFFF1F6FB),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF344F65)
                        : const Color(0xFFE0EAF3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: Color(0xFF2D8FE5),
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Los catálogos permiten mantener organizadas '
                        'las opciones utilizadas por la aplicación. '
                        'La ubicación se administra por separado '
                        'mediante departamentos, municipios, '
                        'corregimientos y veredas.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark
                              ? const Color(0xFFC0CCD7)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // TARJETA DE CATÁLOGO
  // =============================================================

  Widget _buildCatalogCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String catalogType,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openCatalog(catalogType, title);
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2936) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF344657) : const Color(0xFFE1E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // =================================================
              // ICONO
              // =================================================
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),

              const SizedBox(width: 15),

              // =================================================
              // TEXTO
              // =================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF26364F),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: isDark
                            ? const Color(0xFFB6C2CE)
                            : const Color(0xFF8793A5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // =================================================
              // FLECHA
              // =================================================
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? const Color(0xFFB6C2CE)
                    : const Color(0xFF8793A3),
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // ABRIR CATÁLOGO
  // =============================================================

  void _openCatalog(String catalogType, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CatalogManagerPage(catalogType: catalogType, title: title),
      ),
    );
  }
}
