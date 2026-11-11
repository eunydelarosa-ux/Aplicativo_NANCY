import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ===========================================================
/// NANCY
/// Sistema Integral de Inscripciones
/// -----------------------------------------------------------
/// Degradados oficiales de la aplicación.
/// ===========================================================
class AppGradients {
  AppGradients._();

  /// Degradado institucional principal
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryBlue, AppColors.primaryGreen],
  );

  /// Degradado suave para tarjetas destacadas
  static const LinearGradient soft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
  );

  /// Degradado para botones secundarios
  static const LinearGradient secondary = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1976D2), Color(0xFF26A69A)],
  );
}
