// =============================================================
// APLICATIVO NANCY
// Botón reutilizable para guardar
// Diseño visual unificado
// =============================================================

import 'package:flutter/material.dart';

class SaveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SaveButton({super.key, required this.onPressed});

  // =============================================================
  // PALETA VISUAL
  // =============================================================

  static const Color _primaryBlue = Color(0xFF2F6097);
  static const Color _secondaryBlue = Color(0xFF4F83BD);
  static const Color _lightBlue = Color(0xFF7FAFD6);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Se conserva exactamente el degradado original en modo claro.
    // En modo oscuro se usa un azul más profundo, manteniendo
    // contraste suficiente con el icono y el texto blancos.
    final LinearGradient buttonGradient = isDark
        ? const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF173B63), Color(0xFF24558A), Color(0xFF356FA8)],
          )
        : const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_primaryBlue, _secondaryBlue, _lightBlue],
          );

    final Color shadowColor = isDark
        ? const Color(0xFF000000).withValues(alpha: 0.35)
        : _primaryBlue.withValues(alpha: 0.20);

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        // =======================================================
        // DEGRADADO AZUL ADAPTADO AL TEMA
        // =======================================================
        gradient: buttonGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save_outlined, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                'Guardar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
