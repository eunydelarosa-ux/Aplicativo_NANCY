// =============================================================
// APLICATIVO NANCY
// Modelo de Copia de Seguridad
// =============================================================


import 'dart:io';

class BackupModel {
  // ===========================================================
  // PROPIEDADES
  // ===========================================================

  final String name;

  final String path;

  final DateTime createdAt;

  final int sizeBytes;

  // ===========================================================
  // CONSTRUCTOR
  // ===========================================================

  const BackupModel({
    required this.name,
    required this.path,
    required this.createdAt,
    required this.sizeBytes,
  });

  // ===========================================================
  // CREAR MODELO DESDE ARCHIVO
  // ===========================================================

  static Future<BackupModel> fromFile(File file) async {
    final FileStat fileStat = await file.stat();

    final String fileName = file.path.split('/').last;

    return BackupModel(
      name: fileName,
      path: file.path,
      createdAt: fileStat.modified,
      sizeBytes: fileStat.size,
    );
  }

  // ===========================================================
  // FORMATEAR FECHA
  // ===========================================================

  String get formattedDate {
    final String day = createdAt.day.toString().padLeft(2, '0');

    final String month = createdAt.month.toString().padLeft(2, '0');

    final String year = createdAt.year.toString();

    return '$day/$month/$year';
  }

  // ===========================================================
  // FORMATEAR HORA
  // ===========================================================

  String get formattedTime {
    final String hour = createdAt.hour.toString().padLeft(2, '0');

    final String minute = createdAt.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // ===========================================================
  // FORMATEAR TAMAÑO
  // ===========================================================

  String get formattedSize {
    const int kb = 1024;

    const int mb = 1024 * 1024;

    if (sizeBytes < kb) {
      return '$sizeBytes B';
    }

    if (sizeBytes < mb) {
      final double size = sizeBytes / kb;

      return '${size.toStringAsFixed(1)} KB';
    }

    final double size = sizeBytes / mb;

    return '${size.toStringAsFixed(2)} MB';
  }
}
