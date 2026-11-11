import 'package:flutter/material.dart';

/// ===========================================================
/// NANCY
/// Sistema Integral de Inscripciones
/// -----------------------------------------------------------
/// Radios oficiales de bordes.
/// ===========================================================
class AppRadius {
  AppRadius._();

  /// Campos de texto
  static const BorderRadius input = BorderRadius.all(Radius.circular(14));

  /// Botones
  static const BorderRadius button = BorderRadius.all(Radius.circular(16));

  /// Tarjetas
  static const BorderRadius card = BorderRadius.all(Radius.circular(20));

  /// Diálogos
  static const BorderRadius dialog = BorderRadius.all(Radius.circular(24));

  /// Hojas inferiores (Bottom Sheets)
  static const BorderRadius bottomSheet = BorderRadius.vertical(
    top: Radius.circular(28),
  );
}
