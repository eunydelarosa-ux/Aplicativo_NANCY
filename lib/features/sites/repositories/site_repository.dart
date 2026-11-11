// ===============================================================
// APLICATIVO NANCY
// Repositorio de Sedes
// ===============================================================

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_constants.dart';
import '../../../core/database/database_helper.dart';
import '../models/site_model.dart';

class SiteRepository {
  SiteRepository();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // =============================================================
  // OBTENER TODAS LAS SEDES
  // =============================================================

  Future<List<SiteModel>> getSites({bool onlyActive = false}) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      DatabaseConstants.sitesTable,
      where: onlyActive ? '${DatabaseConstants.siteActive} = ?' : null,
      whereArgs: onlyActive ? [1] : null,
      orderBy: '${DatabaseConstants.siteName} COLLATE NOCASE ASC',
    );

    return result.map(SiteModel.fromMap).toList();
  }

  // =============================================================
  // OBTENER SEDE POR ID
  // =============================================================

  Future<SiteModel?> getSiteById(int id) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      DatabaseConstants.sitesTable,
      where: '${DatabaseConstants.siteId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return SiteModel.fromMap(result.first);
  }

  // =============================================================
  // CREAR SEDE
  // =============================================================

  Future<int> insertSite(SiteModel site) async {
    final Database db = await _databaseHelper.database;

    return await db.insert(DatabaseConstants.sitesTable, site.toMap());
  }

  // =============================================================
  // ACTUALIZAR SEDE
  // =============================================================

  Future<int> updateSite(SiteModel site) async {
    final Database db = await _databaseHelper.database;

    if (site.id == null) {
      return await insertSite(site);
    }

    return await db.update(
      DatabaseConstants.sitesTable,
      site.toMap(),
      where: '${DatabaseConstants.siteId} = ?',
      whereArgs: [site.id],
    );
  }

  // =============================================================
  // ACTIVAR / DESACTIVAR SEDE
  // =============================================================

  Future<int> setSiteActive(int siteId, bool active) async {
    final Database db = await _databaseHelper.database;

    return await db.update(
      DatabaseConstants.sitesTable,
      {
        DatabaseConstants.siteActive: active ? 1 : 0,
        DatabaseConstants.siteUpdatedAt: DateTime.now().toIso8601String(),
      },
      where: '${DatabaseConstants.siteId} = ?',
      whereArgs: [siteId],
    );
  }

  // =============================================================
  // ELIMINAR SEDE
  // =============================================================

  Future<int> deleteSite(int siteId) async {
    final Database db = await _databaseHelper.database;

    return await db.delete(
      DatabaseConstants.sitesTable,
      where: '${DatabaseConstants.siteId} = ?',
      whereArgs: [siteId],
    );
  }
}
