// ===============================================================
// APLICATIVO NANCY
// Repositorio central de Ubicación
// ===============================================================

import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';

import '../models/department_model.dart';
import '../models/municipality_model.dart';
import '../models/corregimiento_model.dart';
import '../models/village_model.dart';

class LocationRepository {
  LocationRepository();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // ===============================================================
  // REGISTRAR FRECUENCIA DE SELECCIÓN DE UBICACIONES
  // ===============================================================

  Future<void> registerLocationSelection({
    required String locationType,
    required int locationId,
  }) async {
    final Database db = await _databaseHelper.database;

    await db.rawInsert(
      '''
      INSERT INTO location_selection_frequency (
        location_type,
        location_id,
        frequency
      )
      VALUES (?, ?, 1)
      ON CONFLICT(location_type, location_id)
      DO UPDATE SET frequency = frequency + 1
      ''',
      [locationType, locationId],
    );
  }

  // ===============================================================
  // NORMALIZACIÓN
  // ===============================================================

  String _normalizeName(String value) {
    final String clean = value
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();

    const Map<String, String> replacements = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'å': 'a',

      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',

      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',

      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',

      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',

      'ñ': 'n',
    };

    return clean
        .split('')
        .map((String character) => replacements[character] ?? character)
        .join();
  }

  String? _cleanNullable(String? value) {
    final String clean = value?.trim() ?? '';

    return clean.isEmpty ? null : clean;
  }

  // ===============================================================
  // DEPARTAMENTOS
  // ===============================================================

  Future<List<DepartmentModel>> getDepartments() async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> rows = await db.query(
      'departments',
      orderBy: '''
      CASE
        WHEN LOWER(TRIM(name)) = 'no aplica' THEN 0
        ELSE 1
      END ASC,
      COALESCE(
        (
          SELECT frequency
          FROM location_selection_frequency
          WHERE location_type = 'department'
            AND location_id = departments.id
        ),
        0
      ) DESC,
      name COLLATE NOCASE ASC
    ''',
    );

    return rows.map(DepartmentModel.fromMap).toList();
  }

  Future<DepartmentModel?> getDepartmentById(int id) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> rows = await db.query(
      'departments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return DepartmentModel.fromMap(rows.first);
  }

  Future<int> addDepartment({required String name, String? code}) async {
    final String cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw ArgumentError('El nombre del departamento es obligatorio.');
    }

    final Database db = await _databaseHelper.database;

    // -------------------------------------------------------------
    // EVITAR DUPLICADOS
    // -------------------------------------------------------------

    final List<Map<String, dynamic>> existingRows = await db.query(
      'departments',
    );

    final String normalizedName = _normalizeName(cleanName);

    for (final Map<String, dynamic> row in existingRows) {
      final String existingName = (row['name'] ?? '').toString();

      if (_normalizeName(existingName) == normalizedName) {
        throw ArgumentError('El departamento "$cleanName" ya existe.');
      }
    }

    // -------------------------------------------------------------
    // INSERTAR
    // -------------------------------------------------------------

    try {
      return await db.insert('departments', {
        'code': _cleanNullable(code),
        'name': cleanName,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    } on DatabaseException catch (error) {
      throw Exception('No fue posible guardar el departamento: $error');
    }
  }

  // ===============================================================
  // MUNICIPIOS
  // ===============================================================

  Future<List<MunicipalityModel>> getMunicipalitiesByDepartment(
    int departmentId,
  ) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> rows = await db.query(
      'municipalities',
      where: 'department_id = ?',
      whereArgs: [departmentId],
      orderBy: '''
        CASE
          WHEN LOWER(TRIM(name)) = 'no aplica' THEN 0
          ELSE 1
        END ASC,
        COALESCE(
          (
            SELECT frequency
            FROM location_selection_frequency
            WHERE location_type = 'municipality'
              AND location_id = municipalities.id
          ),
          0
        ) DESC,
        name COLLATE NOCASE ASC
      ''',
    );

    return rows.map(MunicipalityModel.fromMap).toList();
  }

  // ---------------------------------------------------------------
  // NUEVO:
  // OBTENER TODOS LOS MUNICIPIOS
  // ---------------------------------------------------------------

  Future<List<MunicipalityModel>> getMunicipalities() async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> rows = await db.query(
      'municipalities',
      orderBy: '''
      CASE
        WHEN LOWER(TRIM(name)) = 'no aplica' THEN 0
        ELSE 1
      END ASC,
      COALESCE(
        (
          SELECT frequency
          FROM location_selection_frequency
          WHERE location_type = 'municipality'
            AND location_id = municipalities.id
        ),
        0
      ) DESC,
      name COLLATE NOCASE ASC
    ''',
    );

    return rows.map(MunicipalityModel.fromMap).toList();
  }

  Future<MunicipalityModel?> getMunicipalityById(int id) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> rows = await db.query(
      'municipalities',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return MunicipalityModel.fromMap(rows.first);
  }

  Future<int> addMunicipality({
    required int departmentId,
    required String name,
    String? code,
  }) async {
    final String cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw ArgumentError('El nombre del municipio es obligatorio.');
    }

    final Database db = await _databaseHelper.database;

    // -------------------------------------------------------------
    // EVITAR DUPLICADOS DENTRO DEL MISMO DEPARTAMENTO
    // -------------------------------------------------------------

    final List<Map<String, dynamic>> existingRows = await db.query(
      'municipalities',
      where: 'department_id = ?',
      whereArgs: [departmentId],
    );

    final String normalizedName = _normalizeName(cleanName);

    for (final Map<String, dynamic> row in existingRows) {
      final String existingName = (row['name'] ?? '').toString();

      if (_normalizeName(existingName) == normalizedName) {
        throw ArgumentError(
          'El municipio "$cleanName" ya existe en este departamento.',
        );
      }
    }

    // -------------------------------------------------------------
    // INSERTAR
    // -------------------------------------------------------------

    try {
      return await db.insert('municipalities', {
        'department_id': departmentId,
        'code': _cleanNullable(code),
        'name': cleanName,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    } on DatabaseException catch (error) {
      throw Exception('No fue posible guardar el municipio: $error');
    }
  }

  // ===============================================================
  // CORREGIMIENTOS
  // ===============================================================

  Future<List<CorregimientoModel>> getCorregimientosByMunicipality(
    int municipalityId,
  ) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> rows = await db.query(
      'corregimientos',
      where: 'municipality_id = ?',
      whereArgs: [municipalityId],
      orderBy: '''
        CASE
          WHEN LOWER(TRIM(name)) = 'no aplica' THEN 0
          ELSE 1
        END ASC,
        COALESCE(
          (
            SELECT frequency
            FROM location_selection_frequency
            WHERE location_type = 'corregimiento'
              AND location_id = corregimientos.id
          ),
          0
        ) DESC,
        name COLLATE NOCASE ASC
      ''',
    );
    return rows.map(CorregimientoModel.fromMap).toList();
  }

  // ---------------------------------------------------------------
  // NUEVO:
  // OBTENER TODOS LOS CORREGIMIENTOS
  // ---------------------------------------------------------------

  Future<List<CorregimientoModel>> getCorregimientos() async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> rows = await db.query(
      'corregimientos',
      orderBy: '''
        CASE
          WHEN LOWER(TRIM(name)) = 'no aplica' THEN 0
          ELSE 1
        END ASC,
        COALESCE(
          (
            SELECT frequency
            FROM location_selection_frequency
            WHERE location_type = 'corregimiento'
              AND location_id = corregimientos.id
          ),
          0
        ) DESC,
        name COLLATE NOCASE ASC
      ''',
    );

    return rows.map(CorregimientoModel.fromMap).toList();
  }

  Future<CorregimientoModel?> getCorregimientoById(int id) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> rows = await db.query(
      'corregimientos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return CorregimientoModel.fromMap(rows.first);
  }

  Future<int> addCorregimiento({
    required int municipalityId,
    required String name,
    String? code,
  }) async {
    final String cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw ArgumentError('El nombre del corregimiento es obligatorio.');
    }

    final Database db = await _databaseHelper.database;

    // -------------------------------------------------------------
    // EVITAR DUPLICADOS DENTRO DEL MISMO MUNICIPIO
    // -------------------------------------------------------------

    final List<Map<String, dynamic>> existingRows = await db.query(
      'corregimientos',
      where: 'municipality_id = ?',
      whereArgs: [municipalityId],
    );

    final String normalizedName = _normalizeName(cleanName);

    for (final Map<String, dynamic> row in existingRows) {
      final String existingName = (row['name'] ?? '').toString();

      if (_normalizeName(existingName) == normalizedName) {
        throw ArgumentError(
          'El corregimiento "$cleanName" ya existe en este municipio.',
        );
      }
    }

    // -------------------------------------------------------------
    // INSERTAR
    // -------------------------------------------------------------

    try {
      return await db.insert('corregimientos', {
        'municipality_id': municipalityId,
        'code': _cleanNullable(code),
        'name': cleanName,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    } on DatabaseException catch (error) {
      throw Exception('No fue posible guardar el corregimiento: $error');
    }
  }

  // ===============================================================
  // VEREDAS
  // ===============================================================

  Future<List<VillageModel>> getVillages({
    int? departmentId,
    int? municipalityId,
    int? corregimientoId,
  }) async {
    final Database db = await _databaseHelper.database;

    final List<String> whereParts = [];
    final List<dynamic> whereArgs = [];

    if (departmentId != null) {
      whereParts.add('department_id = ?');
      whereArgs.add(departmentId);
    }

    if (municipalityId != null) {
      whereParts.add('municipality_id = ?');
      whereArgs.add(municipalityId);
    }

    if (corregimientoId != null) {
      whereParts.add('corregimiento_id = ?');
      whereArgs.add(corregimientoId);
    }

    final List<Map<String, dynamic>> rows = await db.query(
      'villages',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: '''
        CASE
          WHEN LOWER(TRIM(name)) = 'no aplica' THEN 0
          ELSE 1
        END ASC,
        COALESCE(
          (
            SELECT frequency
            FROM location_selection_frequency
            WHERE location_type = 'village'
              AND location_id = villages.id
          ),
          0
        ) DESC,
        name COLLATE NOCASE ASC
      ''',
    );

    return rows.map(VillageModel.fromMap).toList();
  }

  Future<VillageModel?> getVillageById(int id) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> rows = await db.query(
      'villages',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return VillageModel.fromMap(rows.first);
  }

  Future<int> addVillage({
    required String name,
    int? departmentId,
    int? municipalityId,
    int? corregimientoId,
    String? code,
  }) async {
    final String cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw ArgumentError('El nombre de la vereda es obligatorio.');
    }

    if (municipalityId == null) {
      throw ArgumentError(
        'El municipio es obligatorio para registrar una vereda.',
      );
    }

    final Database db = await _databaseHelper.database;

    // -------------------------------------------------------------
    // EVITAR DUPLICADOS
    // -------------------------------------------------------------

    final List<String> whereParts = ['municipality_id = ?'];

    final List<dynamic> whereArgs = [municipalityId];

    if (corregimientoId != null) {
      whereParts.add('corregimiento_id = ?');
      whereArgs.add(corregimientoId);
    } else {
      whereParts.add('corregimiento_id IS NULL');
    }

    final List<Map<String, dynamic>> existingRows = await db.query(
      'villages',
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
    );

    final String normalizedName = _normalizeName(cleanName);

    for (final Map<String, dynamic> row in existingRows) {
      final String existingName = (row['name'] ?? '').toString();

      if (_normalizeName(existingName) == normalizedName) {
        throw ArgumentError(
          'La vereda "$cleanName" ya existe en esta ubicación.',
        );
      }
    }

    // -------------------------------------------------------------
    // INSERTAR
    // -------------------------------------------------------------

    try {
      return await db.insert('villages', {
        'department_id': departmentId,
        'municipality_id': municipalityId,
        'corregimiento_id': corregimientoId,
        'code': _cleanNullable(code),
        'name': cleanName,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    } on DatabaseException catch (error) {
      throw Exception('No fue posible guardar la vereda: $error');
    }
  }

  // ===============================================================
  // BUSCAR DEPARTAMENTO POR NOMBRE
  // ===============================================================

  Future<DepartmentModel?> findDepartmentByName(String name) async {
    final Database db = await _databaseHelper.database;

    final String normalizedTarget = _normalizeName(name);

    final List<Map<String, dynamic>> rows = await db.query('departments');

    for (final Map<String, dynamic> row in rows) {
      final String rowName = (row['name'] ?? '').toString();

      if (_normalizeName(rowName) == normalizedTarget) {
        return DepartmentModel.fromMap(row);
      }
    }

    return null;
  }

  // ===============================================================
  // BUSCAR MUNICIPIO POR NOMBRE
  // ===============================================================

  Future<MunicipalityModel?> findMunicipalityByName({
    required int departmentId,
    required String name,
  }) async {
    final Database db = await _databaseHelper.database;

    final String normalizedTarget = _normalizeName(name);

    final List<Map<String, dynamic>> rows = await db.query(
      'municipalities',
      where: 'department_id = ?',
      whereArgs: [departmentId],
    );

    for (final Map<String, dynamic> row in rows) {
      final String rowName = (row['name'] ?? '').toString();

      if (_normalizeName(rowName) == normalizedTarget) {
        return MunicipalityModel.fromMap(row);
      }
    }

    return null;
  }

  // ===============================================================
  // BUSCAR CORREGIMIENTO POR NOMBRE
  // ===============================================================

  Future<CorregimientoModel?> findCorregimientoByName({
    required int municipalityId,
    required String name,
  }) async {
    final Database db = await _databaseHelper.database;

    final String normalizedTarget = _normalizeName(name);

    final List<Map<String, dynamic>> rows = await db.query(
      'corregimientos',
      where: 'municipality_id = ?',
      whereArgs: [municipalityId],
    );

    for (final Map<String, dynamic> row in rows) {
      final String rowName = (row['name'] ?? '').toString();

      if (_normalizeName(rowName) == normalizedTarget) {
        return CorregimientoModel.fromMap(row);
      }
    }

    return null;
  }

  // ===============================================================
  // BUSCAR VEREDA POR NOMBRE
  // ===============================================================

  Future<VillageModel?> findVillageByName({
    required int municipalityId,
    int? corregimientoId,
    required String name,
  }) async {
    final Database db = await _databaseHelper.database;

    final String normalizedTarget = _normalizeName(name);

    String where = 'municipality_id = ?';

    final List<dynamic> args = [municipalityId];

    if (corregimientoId != null) {
      where += ' AND corregimiento_id = ?';
      args.add(corregimientoId);
    } else {
      where += ' AND corregimiento_id IS NULL';
    }

    final List<Map<String, dynamic>> rows = await db.query(
      'villages',
      where: where,
      whereArgs: args,
    );

    for (final Map<String, dynamic> row in rows) {
      final String rowName = (row['name'] ?? '').toString();

      if (_normalizeName(rowName) == normalizedTarget) {
        return VillageModel.fromMap(row);
      }
    }

    return null;
  }
}
