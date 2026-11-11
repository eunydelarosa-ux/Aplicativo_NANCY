// ===============================================================
// APLICATIVO NANCY
// Repositorio de relación Sede - Municipio
// ===============================================================

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_constants.dart';
import '../../../core/database/database_helper.dart';
import '../models/site_municipality_model.dart';

class SiteMunicipalityRepository {
  SiteMunicipalityRepository();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // =============================================================
  // OBTENER MUNICIPIOS DE UNA SEDE
  // =============================================================

  Future<List<int>> getMunicipalityIdsBySite(int siteId) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      DatabaseConstants.siteMunicipalitiesTable,
      columns: [DatabaseConstants.siteMunicipalityMunicipalityId],
      where: '${DatabaseConstants.siteMunicipalitySiteId} = ?',
      whereArgs: [siteId],
      orderBy: '${DatabaseConstants.siteMunicipalityMunicipalityId} ASC',
    );

    return result
        .map(
          (row) => row[DatabaseConstants.siteMunicipalityMunicipalityId] as int,
        )
        .toList();
  }

  // =============================================================
  // OBTENER RELACIONES DE UNA SEDE
  // =============================================================

  Future<List<SiteMunicipalityModel>> getBySite(int siteId) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      DatabaseConstants.siteMunicipalitiesTable,
      where: '${DatabaseConstants.siteMunicipalitySiteId} = ?',
      whereArgs: [siteId],
      orderBy: '${DatabaseConstants.siteMunicipalityMunicipalityId} ASC',
    );

    return result.map(SiteMunicipalityModel.fromMap).toList();
  }

  // =============================================================
  // OBTENER SEDES DE UN MUNICIPIO
  // =============================================================

  Future<List<int>> getSiteIdsByMunicipality(int municipalityId) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      DatabaseConstants.siteMunicipalitiesTable,
      columns: [DatabaseConstants.siteMunicipalitySiteId],
      where: '${DatabaseConstants.siteMunicipalityMunicipalityId} = ?',
      whereArgs: [municipalityId],
      orderBy: '${DatabaseConstants.siteMunicipalitySiteId} ASC',
    );

    return result
        .map((row) => row[DatabaseConstants.siteMunicipalitySiteId] as int)
        .toList();
  }

  // =============================================================
  // ASOCIAR MUNICIPIO A SEDE
  // =============================================================

  Future<void> addMunicipalityToSite(int siteId, int municipalityId) async {
    final Database db = await _databaseHelper.database;

    await db.insert(
      DatabaseConstants.siteMunicipalitiesTable,
      SiteMunicipalityModel(
        siteId: siteId,
        municipalityId: municipalityId,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // =============================================================
  // QUITAR MUNICIPIO DE SEDE
  // =============================================================

  Future<int> removeMunicipalityFromSite(int siteId, int municipalityId) async {
    final Database db = await _databaseHelper.database;

    return await db.delete(
      DatabaseConstants.siteMunicipalitiesTable,
      where:
          '''
        ${DatabaseConstants.siteMunicipalitySiteId} = ?
        AND
        ${DatabaseConstants.siteMunicipalityMunicipalityId} = ?
      ''',
      whereArgs: [siteId, municipalityId],
    );
  }

  // =============================================================
  // REEMPLAZAR MUNICIPIOS DE UNA SEDE
  // =============================================================

  Future<void> replaceMunicipalitiesForSite(
    int siteId,
    List<int> municipalityIds,
  ) async {
    final Database db = await _databaseHelper.database;

    await db.transaction((txn) async {
      await txn.delete(
        DatabaseConstants.siteMunicipalitiesTable,
        where: '${DatabaseConstants.siteMunicipalitySiteId} = ?',
        whereArgs: [siteId],
      );

      for (final int municipalityId in municipalityIds) {
        await txn.insert(
          DatabaseConstants.siteMunicipalitiesTable,
          SiteMunicipalityModel(
            siteId: siteId,
            municipalityId: municipalityId,
          ).toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  // =============================================================
  // COMPROBAR RELACIÓN
  // =============================================================

  Future<bool> isMunicipalityAssignedToSite(
    int siteId,
    int municipalityId,
  ) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      DatabaseConstants.siteMunicipalitiesTable,
      columns: [DatabaseConstants.siteMunicipalitySiteId],
      where:
          '''
        ${DatabaseConstants.siteMunicipalitySiteId} = ?
        AND
        ${DatabaseConstants.siteMunicipalityMunicipalityId} = ?
      ''',
      whereArgs: [siteId, municipalityId],
      limit: 1,
    );

    return result.isNotEmpty;
  }
}
