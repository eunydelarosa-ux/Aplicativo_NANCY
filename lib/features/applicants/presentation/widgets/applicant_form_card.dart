// =============================================================
// APLICATIVO NANCY
// Contenedor reutilizable para las secciones del formulario
// Diseño visual compacto
// =============================================================

import 'package:flutter/material.dart';

class ApplicantFormCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const ApplicantFormCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  // =============================================================
  // PALETA DEL FORMULARIO
  // =============================================================

  static const Color _secondaryTextColor = Color(0xFF6B7785);

  static const Color _titleGreen = Color(0xFF249A88);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // =====================================================
          // TÍTULO SIMPLE
          // =====================================================
          Text(
            title,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : _titleGreen,
              letterSpacing: -0.2,
            ),
          ),

          // =====================================================
          // SUBTÍTULO
          // =====================================================
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),

            Text(
              subtitle!,

              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white : _secondaryTextColor,
                height: 1.3,
              ),
            ),
          ],

          // =====================================================
          // ESPACIO REDUCIDO
          // =====================================================
          const SizedBox(height: 12),

          // =====================================================
          // CONTENIDO DEL FORMULARIO
          // =====================================================
          child,
        ],
      ),
    );
  }
}
