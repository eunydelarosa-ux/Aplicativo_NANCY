// =============================================================
// APLICATIVO NANCY
// Tarjeta - Información Académica
// =============================================================

import 'package:flutter/material.dart';

import 'applicant_form_card.dart';
import 'custom_dropdown_field.dart';

class AcademicInformationCard extends StatelessWidget {
  // =============================================================
  // VALORES SELECCIONADOS
  // =============================================================

  final String? schooling;
  final String? program;

  // =============================================================
  // OPCIONES DEL CATÁLOGO
  // =============================================================

  final List<String> schoolings;
  final List<String> programs;

  // =============================================================
  // EVENTOS
  // =============================================================

  final ValueChanged<String?> onSchoolingChanged;
  final ValueChanged<String?> onProgramChanged;

  // =============================================================
  // CONSTRUCTOR
  // =============================================================

  const AcademicInformationCard({
    super.key,
    required this.schooling,
    required this.program,
    required this.schoolings,
    required this.programs,
    required this.onSchoolingChanged,
    required this.onProgramChanged,
  });

  // =============================================================
  // INTERFAZ
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ThemeData currentTheme = Theme.of(context);

    // En modo claro se conserva el tema existente.
    // En modo oscuro se refuerzan los colores de texto e íconos
    // para mantener contraste en los componentes descendientes.
    final ThemeData cardTheme = isDark
        ? currentTheme.copyWith(
            colorScheme: currentTheme.colorScheme.copyWith(
              onSurface: Colors.white,
              onPrimary: Colors.white,
              onSecondary: Colors.white,
            ),
            textTheme: currentTheme.textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
            iconTheme: currentTheme.iconTheme.copyWith(color: Colors.white),
            inputDecorationTheme: currentTheme.inputDecorationTheme.copyWith(
              labelStyle: const TextStyle(color: Colors.white),
              hintStyle: const TextStyle(color: Colors.white70),
              prefixIconColor: Colors.white,
              suffixIconColor: Colors.white,
            ),
          )
        : currentTheme;

    return Theme(
      data: cardTheme,
      child: ApplicantFormCard(
        title: 'Información académica',
        subtitle: '',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =====================================================
            // ESCOLARIDAD
            // =====================================================
            CustomDropdownField(
              label: 'Escolaridad',
              hint: 'Seleccione la escolaridad',
              icon: Icons.menu_book_outlined,
              items: schoolings,
              value: schooling,
              onChanged: onSchoolingChanged,
            ),

            const SizedBox(height: 16),

            // =====================================================
            // PROGRAMA
            // =====================================================
            CustomDropdownField(
              label: 'Programa',
              hint: 'Seleccione un programa',
              icon: Icons.school_outlined,
              items: programs,
              value: program,
              onChanged: onProgramChanged,
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
