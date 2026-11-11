import 'package:flutter/material.dart';

/// ===========================================================
/// NANCY
/// Sistema Integral de Inscripciones
/// -----------------------------------------------------------
/// Sombras oficiales de la aplicación.
/// ===========================================================
class AppShadows {
  AppShadows._();

  /// Sombra para tarjetas
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Sombra para botones
  static const List<BoxShadow> button = [
    BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 3)),
  ];

  /// Sombra para diálogos
  static const List<BoxShadow> dialog = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 20, offset: Offset(0, 8)),
  ];
}
