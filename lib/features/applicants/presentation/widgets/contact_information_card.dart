// =============================================================
// APLICATIVO NANCY
// TARJETA - INFORMACIÓN DE CONTACTO
// =============================================================

import 'package:flutter/material.dart';

import 'applicant_form_card.dart';
import 'custom_text_field.dart';

// =============================================================
// SELECTOR DE UBICACIÓN
// =============================================================

import '../../../location/presentation/widgets/location_selector.dart';

// =============================================================
// TARJETA DE INFORMACIÓN DE CONTACTO
// =============================================================

class ContactInformationCard extends StatelessWidget {
  // =============================================================
  // CONTROLADORES
  // =============================================================

  final TextEditingController phoneController;

  final TextEditingController emailController;

  final TextEditingController addressController;

  // =============================================================
  // UBICACIÓN INICIAL
  // =============================================================

  final String? department;

  final String? municipality;

  final String? corregimiento;

  final String? village;

  // =============================================================
  // CAMBIO DE UBICACIÓN
  // =============================================================

  final ValueChanged<LocationSelection?>? onLocationChanged;

  // =============================================================
  // CONSTRUCTOR
  // =============================================================

  const ContactInformationCard({
    super.key,
    required this.phoneController,
    required this.emailController,
    required this.addressController,
    this.department,
    this.municipality,
    this.corregimiento,
    this.village,
    this.onLocationChanged,
  });

  // =============================================================
  // INTERFAZ
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return ApplicantFormCard(
      title: 'Contacto y ubicación',
      subtitle: '',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isWide = constraints.maxWidth >= 650;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // TELÉFONO Y CORREO
              // =================================================
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Teléfono',
                        hint: 'Ingrese teléfono',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        controller: phoneController,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Correo electrónico',
                        hint: 'Ingrese correo electrónico',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        controller: emailController,
                      ),
                    ),
                  ],
                )
              else ...[
                CustomTextField(
                  label: 'Teléfono',
                  hint: 'Ingrese el número de teléfono',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  controller: phoneController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Correo electrónico',
                  hint: 'Ingrese el correo electrónico',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  controller: emailController,
                ),
              ],

              const SizedBox(height: 24),

              // =================================================
              // UBICACIÓN
              // =================================================
              LocationSelector(
                label: 'Ubicación',
                hint: 'Seleccione la ubicación',
                initialDepartment: department,
                initialMunicipality: municipality,
                initialCorregimiento: corregimiento,
                initialVillage: village,
                onChanged: onLocationChanged,
              ),

              const SizedBox(height: 24),

              // =================================================
              // DIRECCIÓN
              // =================================================
              CustomTextField(
                label: 'Dirección',
                hint: 'Ingrese la dirección',
                icon: Icons.location_on_outlined,
                controller: addressController,
              ),

              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}
