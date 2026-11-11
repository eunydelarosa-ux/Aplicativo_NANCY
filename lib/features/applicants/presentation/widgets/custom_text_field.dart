import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool readOnly;
  final int maxLines;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.maxLines = 1,
    this.onTap,
  });

  // =============================================================
  // PALETA VISUAL DEL FORMULARIO NANCY
  // =============================================================

  static const Color _primaryBlue = Color(0xFF1E5AA8);

  static const Color _textColor = Color(0xFF24364B);

  static const Color _hintColor = Color(0xFF66758A);

  static const Color _borderColor = Color(0xFFD8E1EC);

  static const Color _softGreen = Color(0xFFE8F6F1);

  @override
  Widget build(BuildContext context) {
    // =============================================================
    // DETECTAR MODO CLARO / OSCURO
    // =============================================================
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores dinámicos: se conserva intacta la paleta del modo claro.
    final Color textColor = isDark ? Colors.white : _textColor;
    final Color hintColor = isDark ? Colors.white70 : _hintColor;
    final Color borderColor = isDark ? const Color(0xFF4A5563) : _borderColor;
    final Color fieldColor = isDark
        ? const Color(0xFF252A32)
        : const Color(0xFFFBFCFE);
    final Color iconBackground = isDark ? const Color(0xFF263B38) : _softGreen;

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
          // CAMPO
          // =====================================================
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            maxLines: maxLines,
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
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: fieldColor,

              // =================================================
              // ICONO UNIFORME
              // FONDO VERDE CLARITO + ICONO AZUL
              // =================================================
              prefixIcon: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: _primaryBlue, size: 22),
                ),
              ),

              prefixIconConstraints: const BoxConstraints(
                minWidth: 60,
                minHeight: 60,
              ),

              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: maxLines > 1 ? 18 : 18,
              ),

              // =================================================
              // BORDE NORMAL
              // =================================================
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: borderColor, width: 1.2),
              ),

              // =================================================
              // BORDE ACTIVO
              // =================================================
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: _primaryBlue, width: 2),
              ),

              // =================================================
              // DESHABILITADO
              // =================================================
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
