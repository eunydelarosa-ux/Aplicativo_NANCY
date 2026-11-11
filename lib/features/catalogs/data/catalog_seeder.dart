// ===============================================================
// APLICATIVO NANCY
// Cargador de datos iniciales de Catálogos
// ===============================================================

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_constants.dart';

class CatalogSeeder {
  CatalogSeeder(this.db);

  final Database db;

  // =============================================================
  // CARGAR CATÁLOGOS INICIALES
  // =============================================================

  Future<void> seed() async {
    await _seedDocumentTypes();
    await _seedGenders();
    await _seedSchoolings();
    await _seedPrograms();
  }

  // =============================================================
  // TIPOS DE DOCUMENTO
  // =============================================================

  Future<void> _seedDocumentTypes() async {
    await _insertIfNotExists(
      catalogType: 'document_type',
      name: 'Cédula de ciudadanía',
    );

    await _insertIfNotExists(
      catalogType: 'document_type',
      name: 'Tarjeta de identidad',
    );

    await _insertIfNotExists(
      catalogType: 'document_type',
      name: 'Cédula de extranjería',
    );

    await _insertIfNotExists(catalogType: 'document_type', name: 'Pasaporte');
  }

  // =============================================================
  // GÉNEROS
  // =============================================================

  Future<void> _seedGenders() async {
    await _insertIfNotExists(catalogType: 'gender', name: 'Femenino');

    await _insertIfNotExists(catalogType: 'gender', name: 'Masculino');

    await _insertIfNotExists(catalogType: 'gender', name: 'Otro');

    await _insertIfNotExists(
      catalogType: 'gender',
      name: 'Prefiero no decirlo',
    );
  }

  // =============================================================
  // ESCOLARIDAD
  // =============================================================

  Future<void> _seedSchoolings() async {
    await _insertIfNotExists(catalogType: 'schooling', name: 'Primaria');

    await _insertIfNotExists(catalogType: 'schooling', name: 'Secundaria');

    await _insertIfNotExists(catalogType: 'schooling', name: 'Técnico');

    await _insertIfNotExists(catalogType: 'schooling', name: 'Tecnólogo');

    await _insertIfNotExists(catalogType: 'schooling', name: 'Profesional');
  }

  // =============================================================
  // PROGRAMAS
  // =============================================================

  Future<void> _seedPrograms() async {
    await _insertIfNotExists(
      catalogType: 'program',
      name: 'Técnico Laboral en Auxiliar Contable y Financiero',
    );

    await _insertIfNotExists(
      catalogType: 'program',
      name: 'Técnico Laboral Auxiliar Administrativo',
    );

    await _insertIfNotExists(
      catalogType: 'program',
      name: 'Técnico Laboral en Atención Integral a la Primera Infancia',
    );

    await _insertIfNotExists(
      catalogType: 'program',
      name: 'Técnico Laboral en Operador de Sistemas de Cómputo',
    );

    await _insertIfNotExists(
      catalogType: 'program',
      name: 'Técnico Laboral en Auxiliar Contable y Financiero',
    );
  }

  // =============================================================
  // INSERTAR SOLO SI NO EXISTE
  // =============================================================

  Future<void> _insertIfNotExists({
    required String catalogType,
    required String name,
  }) async {
    final List<Map<String, dynamic>> existing = await db.query(
      DatabaseConstants.catalogItemsTable,
      columns: [DatabaseConstants.catalogId],
      where:
          '${DatabaseConstants.catalogType} = ? '
          'AND LOWER(${DatabaseConstants.catalogName}) = LOWER(?)',
      whereArgs: [catalogType, name.trim()],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return;
    }

    final String now = DateTime.now().toIso8601String();

    await db.insert(DatabaseConstants.catalogItemsTable, {
      DatabaseConstants.catalogType: catalogType,
      DatabaseConstants.catalogName: name.trim(),
      DatabaseConstants.catalogParentId: 0,
      DatabaseConstants.catalogActive: 1,
      DatabaseConstants.catalogCreatedAt: now,
      DatabaseConstants.catalogUpdatedAt: now,
    });
  }
}
