// =============================================================
// APLICATIVO NANCY
// Sección - Observaciones
// Diseño visual unificado
// =============================================================

import 'package:flutter/material.dart';

import 'applicant_form_card.dart';
import 'custom_text_field.dart';

class ObservationsCard extends StatelessWidget {
  // =============================================================
  // CONTROLADOR
  // =============================================================

  final TextEditingController controller;

  const ObservationsCard({super.key, required this.controller});

  // =============================================================
  // INTERFAZ
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return ApplicantFormCard(
      // =========================================================
      // SOLO DEJAMOS EL ENCABEZADO PRINCIPAL
      // =========================================================
      title: 'Complete la información',
      subtitle: '',

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // CAMPO DE OBSERVACIONES
          // =====================================================
          CustomTextField(
            label: 'Observaciones',
            hint: 'Escriba una observación (opcional)',
            icon: Icons.notes_rounded,
            maxLines: 5,
            controller: controller,
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
