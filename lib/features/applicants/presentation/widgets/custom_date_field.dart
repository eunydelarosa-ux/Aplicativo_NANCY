// =============================================================
// APLICATIVO NANCY
// Campo de fecha reutilizable
// Diseño visual unificado del formulario
// =============================================================

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class CustomDateField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onTap;

  const CustomDateField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.onTap,
  });

  // =============================================================
  // PALETA VISUAL DEL FORMULARIO NANCY
  // =============================================================

  static const Color _primaryBlue = Color(0xFF1E5AA8);

  static const Color _textColor = Color(0xFF24364B);

  static const Color _hintColor = Color(0xFF7B8798);

  static const Color _borderColor = Color(0xFFD8E1EC);

  // Fondo verde muy claro para los iconos principales
  static const Color _softGreen = Color(0xFFE8F6F1);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color textColor = isDark ? Colors.white : _textColor;
    final Color hintColor = isDark ? Colors.white70 : _hintColor;
    final Color fieldFillColor = isDark
        ? const Color(0xFF252A32)
        : const Color(0xFFFBFCFE);
    final Color borderColor = isDark ? const Color(0xFF505966) : _borderColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // ETIQUETA
          // =====================================================
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.1,
            ),
          ),

          const SizedBox(height: 9),

          // =====================================================
          // CAMPO DE FECHA
          // =====================================================
          TextField(
            controller: controller,
            readOnly: true,
            onTap: onTap,
            cursorColor: _primaryBlue,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: fieldFillColor,

              // =================================================
              // ICONO PRINCIPAL
              // Fondo verde claro + icono azul
              // =================================================
              prefixIcon: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF24463D) : _softGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    color: _primaryBlue,
                    size: 22,
                  ),
                ),
              ),

              prefixIconConstraints: const BoxConstraints(
                minWidth: 60,
                minHeight: 60,
              ),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 18,
              ),

              // =================================================
              // BORDES
              // =================================================
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: borderColor, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: _primaryBlue, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: borderColor, width: 1.2),
              ),

              // =================================================
              // ERROR
              // =================================================
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: AppColors.error, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
