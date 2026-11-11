// ===============================================================
// APLICATIVO NANCY
// Seeder inicial de ubicaciones de Colombia
// ===============================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../repositories/location_repository.dart';
import '../models/municipality_model.dart';

class ColombiaLocationSeeder {
  ColombiaLocationSeeder({LocationRepository? repository})
    : _repository = repository ?? LocationRepository();

  final LocationRepository _repository;

  static const String _assetPath = 'assets/data/colombia_locations.json';

  // ===============================================================
  // EJECUTAR SEED
  // ===============================================================

  Future<void> seed() async {
    final departments = await _repository.getDepartments();

    if (departments.isNotEmpty) {
      return;
    }

    final String jsonString = await rootBundle.loadString(_assetPath);

    final dynamic decoded = json.decode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'El archivo colombia_locations.json no tiene un formato válido.',
      );
    }

    final Map<String, dynamic> data = decoded;

    await _seedDepartments(data);
    await _seedMunicipalities(data);
    await _seedCorregimientos(data);
    await _seedVillages(data);

    // "No aplica" debe existir para todos los municipios.
    await _createNoAplicaRecords();
  }

  // ===============================================================
  // DEPARTAMENTOS
  // ===============================================================

  Future<void> _seedDepartments(Map<String, dynamic> data) async {
    final List<dynamic> departments =
        data['departments'] as List<dynamic>? ?? [];

    for (final dynamic item in departments) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final String name = (item['name'] ?? '').toString().trim();

      final String code = (item['code'] ?? '').toString().trim();

      if (name.isEmpty) {
        continue;
      }

      // Si ya existe por nombre, no hacemos nada.
      final existing = await _repository.findDepartmentByName(name);

      if (existing != null) {
        continue;
      }

      try {
        await _repository.addDepartment(
          name: name,
          code: code.isEmpty ? null : code,
        );
      } catch (_) {
        // Si otro proceso lo creó o ya existe por restricción,
        // continuamos con el siguiente registro.
        continue;
      }
    }
  }

  // ===============================================================
  // MUNICIPIOS
  // ===============================================================

  Future<void> _seedMunicipalities(Map<String, dynamic> data) async {
    final List<dynamic> municipalities =
        data['municipalities'] as List<dynamic>? ?? [];

    for (final dynamic item in municipalities) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final String departmentName = (item['departmentName'] ?? '')
          .toString()
          .trim();

      final String departmentCode = (item['departmentCode'] ?? '')
          .toString()
          .trim();

      final String name = (item['name'] ?? '').toString().trim();

      final String code = (item['code'] ?? '').toString().trim();

      if (name.isEmpty) {
        continue;
      }

      // El Repository busca departamento por nombre,
      // no por código. Por eso preferimos departmentName.
      final String departmentLookup = departmentName.isNotEmpty
          ? departmentName
          : _departmentNameFromCode(data, departmentCode);

      if (departmentLookup.isEmpty) {
        continue;
      }

      final department = await _repository.findDepartmentByName(
        departmentLookup,
      );

      if (department == null) {
        continue;
      }

      // CORRECCIÓN:
      // department.id es int?, pero el Repository necesita int.
      final int? departmentId = department.id;

      if (departmentId == null) {
        continue;
      }

      final existing = await _repository.findMunicipalityByName(
        departmentId: departmentId,
        name: name,
      );

      if (existing != null) {
        continue;
      }

      try {
        await _repository.addMunicipality(
          departmentId: departmentId,
          name: name,
          code: code.isEmpty ? null : code,
        );
      } catch (_) {
        continue;
      }
    }
  }

  // ===============================================================
  // CORREGIMIENTOS
  // ===============================================================

  Future<void> _seedCorregimientos(Map<String, dynamic> data) async {
    final List<dynamic> corregimientos =
        data['corregimientos'] as List<dynamic>? ?? [];

    for (final dynamic item in corregimientos) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final String municipalityName = (item['municipalityName'] ?? '')
          .toString()
          .trim();

      final String municipalityCode = (item['municipalityCode'] ?? '')
          .toString()
          .trim();

      final String departmentName = (item['departmentName'] ?? '')
          .toString()
          .trim();

      final String name = (item['name'] ?? '').toString().trim();

      final String code = (item['code'] ?? '').toString().trim();

      if (name.isEmpty) {
        continue;
      }

      final municipality = await _findMunicipality(
        data: data,
        departmentName: departmentName,
        municipalityName: municipalityName,
        municipalityCode: municipalityCode,
      );

      if (municipality == null) {
        continue;
      }

      // CORRECCIÓN:
      // municipality.id es int?, pero el Repository necesita int.
      final int? municipalityId = municipality.id;

      if (municipalityId == null) {
        continue;
      }

      final existing = await _repository.findCorregimientoByName(
        municipalityId: municipalityId,
        name: name,
      );

      if (existing != null) {
        continue;
      }

      try {
        await _repository.addCorregimiento(
          municipalityId: municipalityId,
          name: name,
          code: code.isEmpty ? null : code,
        );
      } catch (_) {
        continue;
      }
    }
  }

  // ===============================================================
  // VEREDAS
  // ===============================================================

  Future<void> _seedVillages(Map<String, dynamic> data) async {
    final List<dynamic> villages = data['villages'] as List<dynamic>? ?? [];

    debugPrint(
      '🌱 Seeder: se encontraron ${villages.length} veredas en el JSON.',
    );

    int inserted = 0;
    int alreadyExists = 0;
    int skipped = 0;

    for (final dynamic item in villages) {
      if (item is! Map<String, dynamic>) {
        skipped++;
        continue;
      }

      final String departmentName = (item['departmentName'] ?? '')
          .toString()
          .trim();

      final String municipalityName = (item['municipalityName'] ?? '')
          .toString()
          .trim();

      final String municipalityCode = (item['municipalityCode'] ?? '')
          .toString()
          .trim();

      final String corregimientoName = (item['corregimiento'] ?? '')
          .toString()
          .trim();

      final String name = (item['name'] ?? '').toString().trim();

      final String code = (item['code'] ?? '').toString().trim();

      if (name.isEmpty) {
        skipped++;
        continue;
      }

      // -------------------------------------------------------------
      // BUSCAR MUNICIPIO
      // -------------------------------------------------------------

      final municipality = await _findMunicipality(
        data: data,
        departmentName: departmentName,
        municipalityName: municipalityName,
        municipalityCode: municipalityCode,
      );

      if (municipality == null || municipality.id == null) {
        debugPrint(
          '⚠️ No se encontró el municipio "$municipalityName" '
          'para la vereda "$name".',
        );

        skipped++;
        continue;
      }

      final int municipalityId = municipality.id!;

      // -------------------------------------------------------------
      // BUSCAR CORREGIMIENTO
      // -------------------------------------------------------------

      int? corregimientoId;

      if (corregimientoName.isNotEmpty) {
        final corregimiento = await _repository.findCorregimientoByName(
          municipalityId: municipalityId,
          name: corregimientoName,
        );

        if (corregimiento == null || corregimiento.id == null) {
          debugPrint(
            '⚠️ No se encontró el corregimiento '
            '"$corregimientoName" para el municipio '
            '"$municipalityName". '
            'Vereda: "$name".',
          );

          skipped++;
          continue;
        }

        corregimientoId = corregimiento.id!;
      }

      // -------------------------------------------------------------
      // BUSCAR DEPARTAMENTO
      // -------------------------------------------------------------

      final int departmentId = municipality.departmentId;

      // -------------------------------------------------------------
      // EVITAR DUPLICADOS
      // -------------------------------------------------------------

      final existing = await _repository.findVillageByName(
        municipalityId: municipalityId,
        corregimientoId: corregimientoId,
        name: name,
      );

      if (existing != null) {
        alreadyExists++;
        continue;
      }

      // -------------------------------------------------------------
      // INSERTAR VEREDA
      // -------------------------------------------------------------

      try {
        await _repository.addVillage(
          name: name,
          departmentId: departmentId,
          municipalityId: municipalityId,
          corregimientoId: corregimientoId,
          code: code.isEmpty ? null : code,
        );

        inserted++;

        debugPrint(
          '✅ Vereda cargada: $name '
          '→ $municipalityName '
          '→ $corregimientoName',
        );
      } catch (error, stackTrace) {
        debugPrint('❌ Error al insertar la vereda "$name": $error');

        debugPrint('$stackTrace');

        skipped++;
      }
    }

    debugPrint(
      '🌱 Seeder de veredas terminado. '
      'Insertadas: $inserted | '
      'Ya existentes: $alreadyExists | '
      'Omitidas: $skipped | '
      'Total JSON: ${villages.length}',
    );
  }
  // ===============================================================
  // CREAR "NO APLICA"
  // ===============================================================

  Future<void> _createNoAplicaRecords() async {
    final departments = await _repository.getDepartments();

    for (final department in departments) {
      // CORRECCIÓN:
      // department.id es int?.
      final int? departmentId = department.id;

      if (departmentId == null) {
        continue;
      }

      final municipalities = await _repository.getMunicipalitiesByDepartment(
        departmentId,
      );

      for (final municipality in municipalities) {
        // CORRECCIÓN:
        // municipality.id es int?.
        final int? municipalityId = municipality.id;

        if (municipalityId == null) {
          continue;
        }

        // ---------------------------------------------------------
        // CORREGIMIENTO "No aplica"
        // ---------------------------------------------------------

        var noAplicaCorregimiento = await _repository.findCorregimientoByName(
          municipalityId: municipalityId,
          name: 'No aplica',
        );

        if (noAplicaCorregimiento == null) {
          try {
            final int id = await _repository.addCorregimiento(
              municipalityId: municipalityId,
              name: 'No aplica',
            );

            noAplicaCorregimiento = await _repository.getCorregimientoById(id);
          } catch (_) {
            // Puede haber sido creado por otra ejecución.
            noAplicaCorregimiento = await _repository.findCorregimientoByName(
              municipalityId: municipalityId,
              name: 'No aplica',
            );
          }
        }

        if (noAplicaCorregimiento == null) {
          continue;
        }

        // CORRECCIÓN:
        // noAplicaCorregimiento.id es int?.
        final int? noAplicaCorregimientoId = noAplicaCorregimiento.id;

        if (noAplicaCorregimientoId == null) {
          continue;
        }

        // ---------------------------------------------------------
        // VEREDA "No aplica"
        // ---------------------------------------------------------

        final existingVillage = await _repository.findVillageByName(
          municipalityId: municipalityId,
          corregimientoId: noAplicaCorregimientoId,
          name: 'No aplica',
        );

        if (existingVillage != null) {
          continue;
        }

        try {
          await _repository.addVillage(
            name: 'No aplica',
            departmentId: departmentId,
            municipalityId: municipalityId,
            corregimientoId: noAplicaCorregimientoId,
          );
        } catch (_) {
          continue;
        }
      }
    }
  }

  // ===============================================================
  // BUSCAR MUNICIPIO
  // ===============================================================

  Future<MunicipalityModel?> _findMunicipality({
    required Map<String, dynamic> data,
    required String departmentName,
    required String municipalityName,
    required String municipalityCode,
  }) async {
    String departmentLookup = departmentName;

    if (departmentLookup.isEmpty) {
      departmentLookup = _departmentNameFromCode(
        data,
        _departmentCodeFromMunicipalityCode(municipalityCode),
      );
    }

    if (departmentLookup.isEmpty || municipalityName.isEmpty) {
      return null;
    }

    final department = await _repository.findDepartmentByName(departmentLookup);

    if (department == null) {
      return null;
    }

    // CORRECCIÓN:
    // department.id es int?.
    final int? departmentId = department.id;

    if (departmentId == null) {
      return null;
    }

    return _repository.findMunicipalityByName(
      departmentId: departmentId,
      name: municipalityName,
    );
  }

  // ===============================================================
  // OBTENER NOMBRE DEL DEPARTAMENTO POR CÓDIGO
  // ===============================================================

  String _departmentNameFromCode(Map<String, dynamic> data, String code) {
    if (code.isEmpty) {
      return '';
    }

    final List<dynamic> departments =
        data['departments'] as List<dynamic>? ?? [];

    for (final dynamic item in departments) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final String itemCode = (item['code'] ?? '').toString().trim();

      if (itemCode == code) {
        return (item['name'] ?? '').toString().trim();
      }
    }

    return '';
  }

  // ===============================================================
  // OBTENER CÓDIGO DEPARTAMENTO DESDE CÓDIGO MUNICIPAL
  // ===============================================================

  String _departmentCodeFromMunicipalityCode(String municipalityCode) {
    final String clean = municipalityCode.trim();

    if (clean.length < 2) {
      return '';
    }

    return clean.substring(0, 2);
  }
}
