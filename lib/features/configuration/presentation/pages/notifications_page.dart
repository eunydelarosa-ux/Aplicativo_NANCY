// =============================================================
// APLICATIVO NANCY
// Página de Notificaciones
// =============================================================

import 'package:flutter/material.dart';

import '../../models/notifications_settings_model.dart';
import '../../providers/notifications_provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // ===========================================================
  // PROVIDER
  // ===========================================================

  late final NotificationsProvider _provider;

  // ===========================================================
  // CICLO DE VIDA
  // ===========================================================

  @override
  void initState() {
    super.initState();

    _provider = NotificationsProvider();

    _provider.addListener(_onNotificationsChanged);

    _provider.loadSettings();
  }

  @override
  void dispose() {
    _provider.removeListener(_onNotificationsChanged);

    _provider.dispose();

    super.dispose();
  }

  // ===========================================================
  // ACTUALIZAR INTERFAZ
  // ===========================================================

  void _onNotificationsChanged() {
    if (!mounted) return;

    setState(() {});
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    final NotificationsSettingsModel settings = _provider.settings;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101820)
          : const Color(0xFFF7F9FD),

      // =========================================================
      // APP BAR
      // =========================================================
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1B2733) : Colors.white,
        foregroundColor: isDark
            ? const Color(0xFFE7EDF5)
            : const Color(0xFF26364F),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? const Color(0xFFE7EDF5) : const Color(0xFF26364F),
            size: 28,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          'Notificaciones',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFE7EDF5) : const Color(0xFF1F2A44),
          ),
        ),
      ),

      // =========================================================
      // CONTENIDO
      // =========================================================
      body: SafeArea(
        child: _provider.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // =================================================
                    // ENCABEZADO
                    // =================================================
                    Text(
                      'NOTIFICACIONES',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: isDark
                            ? const Color(0xFFB0BFCC)
                            : const Color(0xFF788497),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Controla cómo quieres recibir los avisos '
                      'de la aplicación.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isDark
                            ? const Color(0xFFB0BFCC)
                            : const Color(0xFF8793A5),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // =================================================
                    // NOTIFICACIONES GENERALES
                    // =================================================
                    _buildSwitchCard(
                      context: context,
                      icon: Icons.notifications_active_outlined,
                      iconColor: const Color(0xFF4CAF50),
                      title: 'Notificaciones',
                      description:
                          'Activa o desactiva los avisos de '
                          'Aplicativo Nancy.',
                      value: settings.enabled,
                      onChanged: (value) {
                        _provider.setEnabled(value);
                      },
                    ),

                    const SizedBox(height: 14),

                    // =================================================
                    // SONIDO
                    // =================================================
                    _buildSwitchCard(
                      context: context,
                      icon: Icons.volume_up_outlined,
                      iconColor: const Color(0xFF2D8FE5),
                      title: 'Sonido',
                      description:
                          'Permite reproducir sonidos cuando '
                          'se genere una notificación.',
                      value: settings.sound,
                      enabled: settings.enabled,
                      onChanged: (value) {
                        _provider.setSound(value);
                      },
                    ),

                    const SizedBox(height: 14),

                    // =================================================
                    // VIBRACIÓN
                    // =================================================
                    _buildSwitchCard(
                      context: context,
                      icon: Icons.vibration_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'Vibración',
                      description:
                          'Permite utilizar vibración al recibir '
                          'una notificación.',
                      value: settings.vibration,
                      enabled: settings.enabled,
                      onChanged: (value) {
                        _provider.setVibration(value);
                      },
                    ),

                    const SizedBox(height: 28),

                    // =================================================
                    // INFORMACIÓN
                    // =================================================
                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF203343)
                            : const Color(0xFFF1F6FB),

                        borderRadius: BorderRadius.circular(18),

                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF344654)
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
                              ' Las notificaciones reales '
                              'estarán disponibles próximamente.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: isDark
                                    ? const Color(0xFFD0DAE5)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =================================================
                    // RESTABLECER
                    // =================================================
                    SizedBox(
                      width: double.infinity,

                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showResetConfirmation(context);
                        },

                        icon: const Icon(Icons.restart_alt_rounded, size: 20),

                        label: const Text('Restablecer configuración'),

                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? const Color(0xFFD0DAE5)
                              : const Color(0xFF64748B),

                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF526273)
                                : const Color(0xFFD7E0E8),
                          ),

                          minimumSize: const Size(double.infinity, 50),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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

  // =============================================================
  // TARJETA CON SWITCH
  // =============================================================

  Widget _buildSwitchCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),

      opacity: enabled ? 1.0 : 0.55,

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2733) : Colors.white,

          borderRadius: BorderRadius.circular(22),

          border: Border.all(
            color: isDark ? const Color(0xFF344654) : const Color(0xFFE1E8F0),
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
            // ===================================================
            // ICONO
            // ===================================================
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

            // ===================================================
            // TEXTO
            // ===================================================
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
                          ? const Color(0xFFE7EDF5)
                          : const Color(0xFF26364F),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    description,

                    maxLines: 3,

                    overflow: TextOverflow.ellipsis,

                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: isDark
                          ? const Color(0xFFB0BFCC)
                          : const Color(0xFF8793A5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ===================================================
            // SWITCH
            // ===================================================
            Switch.adaptive(
              value: value,

              onChanged: enabled ? onChanged : null,

              activeThumbColor: const Color(0xFF4CAF50),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // CONFIRMAR RESTABLECIMIENTO
  // =============================================================

  void _showResetConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.transparent,

      builder: (sheetContext) {
        final bool isDark =
            Theme.of(sheetContext).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),

          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2733) : Colors.white,

            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),

          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                // =================================================
                // INDICADOR
                // =================================================
                Container(
                  width: 42,
                  height: 5,

                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF526273)
                        : const Color(0xFFDCE3EA),

                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 22),

                // =================================================
                // ICONO
                // =================================================
                Container(
                  width: 58,
                  height: 58,

                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF203B50)
                        : const Color(0xFFEAF4FF),

                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: const Icon(
                    Icons.restart_alt_rounded,
                    color: Color(0xFF2D8FE5),
                    size: 28,
                  ),
                ),

                const SizedBox(height: 15),

                // =================================================
                // TITULO
                // =================================================
                Text(
                  'Restablecer configuración',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFE7EDF5)
                        : const Color(0xFF1F2A44),
                  ),
                ),

                const SizedBox(height: 8),

                // =================================================
                // DESCRIPCIÓN
                // =================================================
                Text(
                  'Las notificaciones, el sonido y la vibración '
                  'volverán a su configuración predeterminada.',
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isDark
                        ? const Color(0xFFB0BFCC)
                        : const Color(0xFF7B879A),
                  ),
                ),

                const SizedBox(height: 22),

                // =================================================
                // BOTÓN RESTABLECER
                // =================================================
                SizedBox(
                  width: double.infinity,

                  child: ElevatedButton(
                    onPressed: () async {
                      await _provider.resetToDefaults();

                      if (!sheetContext.mounted) return;

                      Navigator.pop(sheetContext);
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D8FE5),

                      foregroundColor: Colors.white,

                      elevation: 0,

                      padding: const EdgeInsets.symmetric(vertical: 14),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    child: const Text(
                      'Restablecer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // =================================================
                // CANCELAR
                // =================================================
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                  },

                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFD0DAE5)
                          : const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
