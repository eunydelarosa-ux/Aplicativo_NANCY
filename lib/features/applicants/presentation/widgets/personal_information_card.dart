// =============================================================
// APLICATIVO NANCY
// Tarjeta - Información Personal
// =============================================================

import 'package:flutter/material.dart';

import 'applicant_form_card.dart';
import 'custom_date_field.dart';
import 'custom_dropdown_field.dart';
import 'custom_text_field.dart';

class PersonalInformationCard extends StatelessWidget {
  // =============================================================
  // CONTROLADORES
  // =============================================================

  final TextEditingController documentController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController birthDateController;

  // =============================================================
  // VALORES SELECCIONADOS
  // =============================================================

  final String? documentType;
  final String? gender;

  // =============================================================
  // OPCIONES DEL CATÁLOGO
  // =============================================================

  final List<String> documentTypes;
  final List<String> genders;

  // =============================================================
  // EVENTOS
  // =============================================================

  final ValueChanged<String?> onDocumentTypeChanged;
  final ValueChanged<String?> onGenderChanged;

  final VoidCallback onBirthDateTap;

  // =============================================================
  // CONSTRUCTOR
  // =============================================================

  const PersonalInformationCard({
    super.key,
    required this.documentController,
    required this.firstNameController,
    required this.lastNameController,
    required this.birthDateController,
    required this.documentType,
    required this.gender,
    required this.documentTypes,
    required this.genders,
    required this.onDocumentTypeChanged,
    required this.onGenderChanged,
    required this.onBirthDateTap,
  });

  // =============================================================
  // INTERFAZ
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return ApplicantFormCard(
      title: 'Información personal',
      subtitle: '',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 650;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // IDENTIFICACIÓN
              // =================================================
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomDropdownField(
                        label: 'Tipo de documento',
                        hint: 'Seleccione',
                        icon: Icons.badge_outlined,
                        items: documentTypes,
                        value: documentType,
                        onChanged: onDocumentTypeChanged,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: CustomTextField(
                        label: 'Número de documento',
                        hint: 'Ingrese número',
                        icon: Icons.credit_card_outlined,
                        keyboardType: TextInputType.number,
                        controller: documentController,
                      ),
                    ),
                  ],
                )
              else ...[
                CustomDropdownField(
                  label: 'Tipo de documento',
                  hint: 'Seleccione el tipo de documento',
                  icon: Icons.badge_outlined,
                  items: documentTypes,
                  value: documentType,
                  onChanged: onDocumentTypeChanged,
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Número de documento',
                  hint: 'Ingrese número de documento',
                  icon: Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                  controller: documentController,
                ),
              ],

              const SizedBox(height: 16),

              // =================================================
              // NOMBRE Y APELLIDO
              // =================================================
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Nombre(s)',
                        hint: 'Ingrese nombre(s)',
                        icon: Icons.person_outline_rounded,
                        controller: firstNameController,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: CustomTextField(
                        label: 'Apellidos',
                        hint: 'Ingrese apellidos',
                        icon: Icons.person_outline_rounded,
                        controller: lastNameController,
                      ),
                    ),
                  ],
                )
              else ...[
                CustomTextField(
                  label: 'Nombre(s)',
                  hint: 'Ingrese nombre(s)',
                  icon: Icons.person_outline_rounded,
                  controller: firstNameController,
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Apellidos',
                  hint: 'Ingrese apellidos',
                  icon: Icons.person_outline_rounded,
                  controller: lastNameController,
                ),
              ],

              const SizedBox(height: 16),

              // =================================================
              // FECHA DE NACIMIENTO Y GÉNERO
              // =================================================
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomDateField(
                        label: 'Fecha de nacimiento',
                        hint: 'Seleccione fecha',
                        controller: birthDateController,
                        onTap: onBirthDateTap,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: CustomDropdownField(
                        label: 'Género',
                        hint: 'Seleccione',
                        icon: Icons.wc_outlined,
                        items: genders,
                        value: gender,
                        onChanged: onGenderChanged,
                      ),
                    ),
                  ],
                )
              else ...[
                CustomDateField(
                  label: 'Fecha de nacimiento',
                  hint: 'Seleccione la fecha',
                  controller: birthDateController,
                  onTap: onBirthDateTap,
                ),

                const SizedBox(height: 16),

                CustomDropdownField(
                  label: 'Género',
                  hint: 'Seleccione el género',
                  icon: Icons.wc_outlined,
                  items: genders,
                  value: gender,
                  onChanged: onGenderChanged,
                ),
              ],

              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}
