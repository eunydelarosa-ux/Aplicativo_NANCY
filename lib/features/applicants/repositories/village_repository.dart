// ===============================================================
// APLICATIVO NANCY
// Repositorio de Veredas o Corregimientos

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_constants.dart';
import '../../../core/database/database_helper.dart';

class VillageRepository {
  VillageRepository();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // =============================================================
  // OBTENER TODOS
  // =============================================================
  //
  // Obtiene todas las veredas y corregimientos disponibles.
  // Se muestran en orden alfabético.
  // =============================================================

  Future<List<String>> getAllVillages() async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      DatabaseConstants.villagesTable,
      columns: [DatabaseConstants.villageName],
      orderBy: '${DatabaseConstants.villageName} ASC',
    );

    return result
        .map((item) => item[DatabaseConstants.villageName] as String)
        .toList();
  }

  // =============================================================
  // BUSCAR
  // =============================================================
  //
  // Busca veredas o corregimientos según el texto escrito.
  // =============================================================

  Future<List<String>> searchVillages(String query) async {
    final Database db = await _databaseHelper.database;

    final String search = query.trim();

    if (search.isEmpty) {
      return getAllVillages();
    }

    final List<Map<String, dynamic>> result = await db.query(
      DatabaseConstants.villagesTable,
      columns: [DatabaseConstants.villageName],
      where: '${DatabaseConstants.villageName} LIKE ? COLLATE NOCASE',
      whereArgs: ['%$search%'],
      orderBy: '${DatabaseConstants.villageName} ASC',
    );

    return result
        .map((item) => item[DatabaseConstants.villageName] as String)
        .toList();
  }

  // =============================================================
  // BUSCAR UN REGISTRO EXACTO
  // =============================================================

  Future<String?> findVillage(String name) async {
    final Database db = await _databaseHelper.database;

    final String value = name.trim();

    if (value.isEmpty) {
      return null;
    }

    final List<Map<String, dynamic>> result = await db.query(
      DatabaseConstants.villagesTable,
      columns: [DatabaseConstants.villageName],
      where: '${DatabaseConstants.villageName} = ? COLLATE NOCASE',
      whereArgs: [value],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first[DatabaseConstants.villageName] as String;
  }

  // =============================================================
  // AGREGAR
  // =============================================================
  //
  // Guarda una nueva vereda o corregimiento.
  //
  // Si ya existe, SQLite ignora el duplicado.
  // =============================================================

  Future<void> addVillage(String name) async {
    final Database db = await _databaseHelper.database;

    final String value = name.trim();

    if (value.isEmpty) {
      return;
    }

    await db.insert(DatabaseConstants.villagesTable, {
      DatabaseConstants.villageName: value,
      DatabaseConstants.villageCreatedAt: DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // =============================================================
  // OBTENER O CREAR
  // =============================================================
  //
  // Este será el método principal.
  //
  // Si el usuario selecciona un registro existente:
  // → devuelve el existente.
  //
  // Si escribe uno nuevo:
  // → lo guarda automáticamente.
  // → lo devuelve.
  // =============================================================

  Future<String?> getOrCreateVillage(String name) async {
    final String value = name.trim();

    if (value.isEmpty) {
      return null;
    }

    final String? existingVillage = await findVillage(value);

    if (existingVillage != null) {
      return existingVillage;
    }

    await addVillage(value);

    return value;
  }
}
