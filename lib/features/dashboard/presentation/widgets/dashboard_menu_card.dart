// =============================================================
// APLICATIVO NANCY
// Tarjeta del menú principal del Dashboard
// Adaptada para modo claro / oscuro
// =============================================================

import 'package:flutter/material.dart';

class DashboardMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const DashboardMenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: color.withValues(alpha: 0.07),
        highlightColor: color.withValues(alpha: 0.03),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            // En modo claro se conserva el fondo perla original.
            color: isDark ? const Color(0xFF202D38) : const Color(0xFFFCFDFE),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? color.withValues(alpha: 0.38)
                  : color.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.18)
                    : const Color(0xFF8EA4B5).withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),

          // Recorte redondeado
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Pequeña línea superior de color
                Positioned(
                  top: 0,
                  left: 42,
                  right: 42,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                // Pequeño detalle perlado
                Positioned(
                  top: 14,
                  right: 15,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: isDark ? 0.28 : 0.16),
                    ),
                  ),
                ),

                // Contenido
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 15, 10, 42),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icono
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: color.withValues(
                              alpha: isDark ? 0.17 : 0.09,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: color.withValues(
                                alpha: isDark ? 0.32 : 0.18,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(icon, color: color, size: 31),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Título
                        Flexible(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              height: 1.12,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFF18355B),
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        // Subtítulo
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.1,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFB0BECC)
                                : const Color(0xFF718196),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Flecha
                Positioned(
                  bottom: 9,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: isDark ? 0.14 : 0.07),
                        border: Border.all(
                          color: color.withValues(alpha: isDark ? 0.38 : 0.25),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: color,
                        size: 21,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(height: 4, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
