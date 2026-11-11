import 'package:flutter/material.dart';

/// ===========================================================
/// NANCY
/// Sistema Integral de Inscripciones
/// -----------------------------------------------------------
/// Espaciados oficiales de la aplicación.
/// ===========================================================
class AppSpacing {
  AppSpacing._();

  // Espaciados
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;

  // Padding estándar
  static const EdgeInsets screen = EdgeInsets.all(md);

  static const EdgeInsets card = EdgeInsets.all(md);

  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  static const EdgeInsets input = EdgeInsets.symmetric(
    horizontal: md,
    vertical: 14,
  );
}
