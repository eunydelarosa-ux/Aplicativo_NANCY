// =============================================================
// APLICATIVO NANCY
// Página de Preferencias
// Diseño institucional blanco / perla / cristal
// =============================================================

import 'package:flutter/material.dart';

import '../../models/preferences_settings_model.dart';
import '../../providers/preferences_provider.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  // ===========================================================
  // PROVIDER
  // ===========================================================

  late final PreferencesProvider _provider;

  // ===========================================================
  // CICLO DE VIDA
  // ===========================================================

  @override
  void initState() {
    super.initState();

    _provider = PreferencesProvider();

    _provider.addListener(_onPreferencesChanged);

    _provider.loadPreferences();
  }

  @override
  void dispose() {
    _provider.removeListener(_onPreferencesChanged);
    _provider.dispose();

    super.dispose();
  }

  // ===========================================================
  // ACTUALIZAR INTERFAZ
  // ===========================================================

  void _onPreferencesChanged() {
    if (!mounted) return;

    setState(() {});
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    final PreferencesSettingsModel settings = _provider.settings;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101820)
          : const Color(0xFFF8FBFD),

      // =========================================================
      // APP BAR
      // =========================================================
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF17232E) : Colors.white,

        surfaceTintColor: Colors.transparent,

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
          'Preferencias',

          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF17345F),
            letterSpacing: -0.4,
          ),
        ),
      ),

      // =========================================================
      // CONTENIDO
      // =========================================================
      body: SafeArea(
        child: _provider.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2D8FE5),
                  strokeWidth: 3,
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =================================================
                    // ENCABEZADO
                    // =================================================
                    _buildPageIntroduction(context),

                    const SizedBox(height: 20),

                    // =================================================
                    // SINCRONIZACIÓN AUTOMÁTICA
                    // =================================================
                    _buildPreferenceCard(
                      context: context,
                      icon: Icons.sync_rounded,
                      iconColor: const Color(0xFF2D8FE5),
                      iconBackground: const Color(0xFFEAF5FC),
                      title: 'Sincronización automática',
                      description:
                          'Sincroniza los registros pendientes '
                          'cuando vuelva la conexión.',
                      value: settings.automaticSync,
                      onChanged: (value) {
                        _provider.setAutomaticSync(value);
                      },
                    ),

                    const SizedBox(height: 13),

                    // =================================================
                    // GUARDAR BORRADORES
                    // =================================================
                    _buildPreferenceCard(
                      context: context,
                      icon: Icons.drafts_outlined,
                      iconColor: const Color(0xFF8B6CCF),
                      iconBackground: const Color(0xFFF3EEFC),
                      title: 'Guardar borradores',
                      description:
                          'Conserva los borradores para continuar '
                          'más tarde.',
                      value: settings.saveDrafts,
                      onChanged: (value) {
                        _provider.setSaveDrafts(value);
                      },
                    ),

                    const SizedBox(height: 13),

                    // =================================================
                    // CONFIRMAR ELIMINACIÓN
                    // =================================================
                    _buildPreferenceCard(
                      context: context,
                      icon: Icons.delete_outline_rounded,
                      iconColor: const Color(0xFFE56B5D),
                      iconBackground: const Color(0xFFFFF1EF),
                      title: 'Confirmar eliminación',
                      description:
                          'Solicita confirmación antes de eliminar '
                          'un registro.',
                      value: settings.confirmDeletion,
                      onChanged: (value) {
                        _provider.setConfirmDeletion(value);
                      },
                    ),

                    const SizedBox(height: 13),

                    // =================================================
                    // MENSAJES DE CONFIRMACIÓN
                    // =================================================
                    _buildPreferenceCard(
                      context: context,
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF39A982),
                      iconBackground: const Color(0xFFECF9F4),
                      title: 'Mensajes de confirmación',
                      description:
                          'Muestra mensajes cuando una operación '
                          'se realiza correctamente.',
                      value: settings.showSuccessMessages,
                      onChanged: (value) {
                        _provider.setShowSuccessMessages(value);
                      },
                    ),

                    const SizedBox(height: 22),

                    // =================================================
                    // INFORMACIÓN
                    // =================================================
                    _buildInformationCard(context),

                    const SizedBox(height: 14),

                    // =================================================
                    // AVISO DE FUNCIONALIDADES FUTURAS
                    // =================================================
                    _buildFutureFeaturesCard(context),
                  ],
                ),
              ),
      ),
    );
  }

  // =============================================================
  // AVISO DE FUNCIONALIDADES FUTURAS
  // Este método va FUERA de build(), pero dentro de la clase.
  // =============================================================
  Widget _buildFutureFeaturesCard(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202D39) : const Color(0xFFEAF3FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3B5061) : const Color(0xFFD2E3F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_sync_outlined,
            size: 25,
            color: isDark ? const Color(0xFF8CC8F2) : const Color(0xFF2D8FE5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Funcionalidades próximamente',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFE6EDF5)
                        : const Color(0xFF17345F),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Estas opciones estarán disponibles en '
                  'próximas versiones, cuando NANCY se '
                  'conecte al sistema central y se complete '
                  'su configuración. Por el momento, algunas '
                  'preferencias aún no tienen efecto sobre '
                  'las funciones de la aplicación.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: isDark
                        ? const Color(0xFFBBC8D4)
                        : const Color(0xFF61758A),
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
  // INTRODUCCIÓN
  // =============================================================
  Widget _buildPageIntroduction(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            'COMPORTAMIENTO',

            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: isDark ? const Color(0xFFB5C2D0) : const Color(0xFF6F8094),
            ),
          ),

          SizedBox(height: 7),

          Text(
            'Configura cómo deseas que funcione Nancy.',

            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFC2CDD8) : const Color(0xFF7D8B9C),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // TARJETA DE PREFERENCIA
  // =============================================================

  Widget _buildPreferenceCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),

      decoration: BoxDecoration(
        // -------------------------------------------------------
        // FONDO BLANCO PERLA
        // -------------------------------------------------------
        color: isDark ? const Color(0xFF1B2936) : const Color(0xFFFEFFFF),

        borderRadius: BorderRadius.circular(22),

        // -------------------------------------------------------
        // BORDE PLATEADO SUAVE
        // -------------------------------------------------------
        border: Border.all(
          color: isDark ? const Color(0xFF344657) : const Color(0xFFDCE6ED),
          width: 1.1,
        ),

        // -------------------------------------------------------
        // SOMBRA MUY DISCRETA
        // -------------------------------------------------------
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8FA8B8).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          // =====================================================
          // ICONO
          // =====================================================
          Container(
            width: 56,
            height: 56,

            decoration: BoxDecoration(
              color: iconBackground,

              borderRadius: BorderRadius.circular(17),

              border: Border.all(
                color: iconColor.withValues(alpha: 0.14),
                width: 1,
              ),
            ),

            child: Icon(icon, color: iconColor, size: 28),
          ),

          const SizedBox(width: 14),

          // =====================================================
          // TEXTO
          // =====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              mainAxisSize: MainAxisSize.min,

              children: [
                Text(
                  title,

                  maxLines: 2,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 16,
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF263B58),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,

                  maxLines: 3,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFB6C2CE)
                        : const Color(0xFF8190A1),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // =====================================================
          // SWITCH
          // =====================================================
          Switch.adaptive(
            value: value,

            activeThumbColor: const Color(0xFF2D8FE5),

            activeTrackColor: const Color(0xFFB9E4F5),

            inactiveThumbColor: isDark
                ? const Color(0xFFB8C4D0)
                : const Color(0xFF9AA8B5),

            inactiveTrackColor: isDark
                ? const Color(0xFF3A4A59)
                : const Color(0xFFE5EBEF),

            trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((
              states,
            ) {
              if (states.contains(WidgetState.selected)) {
                return isDark
                    ? const Color(0xFF5A8BA5)
                    : const Color(0xFF9BD5E9);
              }

              return isDark ? const Color(0xFF526171) : const Color(0xFFD4DDE3);
            }),

            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // =============================================================
  // TARJETA INFORMATIVA
  // =============================================================

  Widget _buildInformationCard(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A37) : const Color(0xFFF3F8FC),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: isDark ? const Color(0xFF34495A) : const Color(0xFFDDE8F0),
          width: 1,
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // =====================================================
          // ICONO
          // =====================================================
          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF203D50) : const Color(0xFFE6F3FB),

              borderRadius: BorderRadius.circular(13),

              border: Border.all(
                color: isDark
                    ? const Color(0xFF355B70)
                    : const Color(0xFFCDE6F4),
              ),
            ),

            child: const Icon(
              Icons.info_outline_rounded,

              size: 21,

              color: Color(0xFF2D8FE5),
            ),
          ),

          const SizedBox(width: 12),

          // =====================================================
          // TEXTO
          // =====================================================
          Expanded(
            child: Text(
              'Los cambios se guardan automáticamente '
              'en este dispositivo.',

              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFFC0CCD7)
                    : const Color(0xFF687A8E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
