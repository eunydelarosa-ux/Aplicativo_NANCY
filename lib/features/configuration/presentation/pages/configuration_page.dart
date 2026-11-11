// =============================================================
// APLICATIVO NANCY
// Página de Configuración
// =============================================================

import 'package:flutter/material.dart';
import 'package:nancy_app/features/configuration/presentation/pages/preferences_page.dart';
import 'package:go_router/go_router.dart';

class ConfigurationPage extends StatelessWidget {
  const ConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBackground = isDark
        ? const Color(0xFF101820)
        : const Color(0xFFF7F9FD);
    final appBarBackground = isDark ? const Color(0xFF17232E) : Colors.white;
    final primaryText = isDark
        ? const Color(0xFFE8EEF5)
        : const Color(0xFF26364F);
    final headingText = isDark
        ? const Color(0xFFE8EEF5)
        : const Color(0xFF1F2A44);
    final secondaryText = isDark
        ? const Color(0xFFB0BFCC)
        : const Color(0xFF8793A5);
    final labelText = isDark
        ? const Color(0xFFB0BFCC)
        : const Color(0xFF788497);

    return Scaffold(
      backgroundColor: pageBackground,

      // =========================================================
      // APP BAR
      // =========================================================
      appBar: AppBar(
        backgroundColor: appBarBackground,
        surfaceTintColor: appBarBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: primaryText, size: 28),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Configuración',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: headingText,
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
              Text(
                'GENERAL',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: labelText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Personaliza el comportamiento de la aplicación',
                style: TextStyle(fontSize: 14, color: secondaryText),
              ),
              const SizedBox(height: 18),

              _buildConfigurationCard(
                context: context,
                icon: Icons.tune_rounded,
                iconColor: const Color(0xFF2D8FE5),
                title: 'Preferencias',
                description: 'Configura el comportamiento de la aplicación',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PreferencesPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              _buildConfigurationCard(
                context: context,
                icon: Icons.palette_outlined,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Apariencia',
                description: 'Personaliza la apariencia de la aplicación',
                onTap: () {
                  context.push('/configuration/appearance');
                },
              ),

              const SizedBox(height: 14),

              _buildConfigurationCard(
                context: context,
                icon: Icons.notifications_none_rounded,
                iconColor: const Color(0xFF4CAF50),
                title: 'Notificaciones',
                description: 'Administra las notificaciones de la aplicación',
                onTap: () {
                  context.push('/configuration/notifications');
                },
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B2A38)
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
                        'Estas opciones controlan únicamente '
                        'el comportamiento y la apariencia de '
                        'Aplicativo Nancy.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isDark
                              ? const Color(0xFFCAD5E0)
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
  // TARJETA DE CONFIGURACIÓN
  // =============================================================
  Widget _buildConfigurationCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark ? const Color(0xFF1B2733) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF344654)
        : const Color(0xFFE1E8F0);
    final titleColor = isDark
        ? const Color(0xFFE8EEF5)
        : const Color(0xFF26364F);
    final descriptionColor = isDark
        ? const Color(0xFFB0BFCC)
        : const Color(0xFF8793A5);
    final arrowColor = isDark
        ? const Color(0xFFB0BFCC)
        : const Color(0xFF8793A3);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cardBorder, width: 1),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
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
                        color: descriptionColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: arrowColor, size: 25),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // MENSAJE TEMPORAL
  // =============================================================
  void showTemporaryMessage(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final sheetBackground = isDark ? const Color(0xFF1B2733) : Colors.white;
        final titleColor = isDark
            ? const Color(0xFFE8EEF5)
            : const Color(0xFF1F2A44);
        final messageColor = isDark
            ? const Color(0xFFB0BFCC)
            : const Color(0xFF7B879A);

        return Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          decoration: BoxDecoration(
            color: sheetBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE3EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 22),
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
                    Icons.settings_outlined,
                    color: Color(0xFF2D8FE5),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: messageColor,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
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
                      'Entendido',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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
