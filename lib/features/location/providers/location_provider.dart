// ===============================================================
// APLICATIVO NANCY
// Provider central de Ubicación
// ===============================================================

import 'package:flutter/foundation.dart';

import '../models/department_model.dart';
import '../models/municipality_model.dart';
import '../models/corregimiento_model.dart';
import '../models/village_model.dart';
import '../repositories/location_repository.dart';

class LocationProvider extends ChangeNotifier {
  LocationProvider({LocationRepository? repository})
    : _repository = repository ?? LocationRepository();

  final LocationRepository _repository;

  // =============================================================
  // REGISTRAR FRECUENCIA DE SELECCIÓN DE UBICACIONES
  // =============================================================

  Future<void> registerLocationSelection({
    required String locationType,
    required int locationId,
  }) async {
    await _repository.registerLocationSelection(
      locationType: locationType,
      locationId: locationId,
    );
  }

  // =============================================================
  // LISTAS
  // =============================================================

  List<DepartmentModel> _departments = [];

  List<MunicipalityModel> _municipalities = [];

  List<CorregimientoModel> _corregimientos = [];

  List<VillageModel> _villages = [];

  // =============================================================
  // SELECCIÓN
  // =============================================================

  DepartmentModel? _selectedDepartment;

  MunicipalityModel? _selectedMunicipality;

  CorregimientoModel? _selectedCorregimiento;

  VillageModel? _selectedVillage;

  // =============================================================
  // ESTADO
  // =============================================================

  bool _isLoading = false;

  String? _errorMessage;

  // =============================================================
  // GETTERS
  // =============================================================

  List<DepartmentModel> get departments => List.unmodifiable(_departments);

  List<MunicipalityModel> get municipalities =>
      List.unmodifiable(_municipalities);

  List<CorregimientoModel> get corregimientos =>
      List.unmodifiable(_corregimientos);

  List<VillageModel> get villages => List.unmodifiable(_villages);

  DepartmentModel? get selectedDepartment => _selectedDepartment;

  MunicipalityModel? get selectedMunicipality => _selectedMunicipality;

  CorregimientoModel? get selectedCorregimiento => _selectedCorregimiento;

  VillageModel? get selectedVillage => _selectedVillage;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // =============================================================
  // CARGAR UBICACIONES
  // =============================================================

  Future<void> loadDepartments() async {
    _setLoading(true);

    try {
      _departments = await _repository.getDepartments();

      _municipalities = await _repository.getMunicipalities();

      _corregimientos = await _repository.getCorregimientos();

      _villages = await _repository.getVillages();

      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'No fue posible cargar las ubicaciones.';

      if (kDebugMode) {
        debugPrint('Error al cargar ubicaciones: $error');
      }
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // CARGAR DEPARTAMENTOS Y MUNICIPIOS PARA GESTIÓN DE SEDES
  // =============================================================

  Future<void> loadDepartmentsAndMunicipalities() async {
    _setLoading(true);

    try {
      _departments = await _repository.getDepartments();
      _municipalities = await _repository.getMunicipalities();

      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'No fue posible cargar departamentos y municipios.';

      if (kDebugMode) {
        debugPrint('Error al cargar departamentos y municipios: $error');
      }
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // CARGAR TODAS LAS UBICACIONES
  // =============================================================

  Future<void> loadAllLocations() async {
    _setLoading(true);

    try {
      _departments = await _repository.getDepartments();

      _municipalities = await _repository.getMunicipalities();

      _corregimientos = await _repository.getCorregimientos();

      _villages = await _repository.getVillages();

      debugPrint('DEBUG UBICACIONES: corregimientos=${_corregimientos.length}');

      debugPrint('DEBUG UBICACIONES: veredas=${_villages.length}');

      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'No fue posible cargar las ubicaciones.';

      if (kDebugMode) {
        debugPrint('Error al cargar ubicaciones: $error');
      }
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // SELECCIONAR DEPARTAMENTO
  // =============================================================

  Future<void> selectDepartment(DepartmentModel? department) async {
    _selectedDepartment = department;

    _selectedMunicipality = null;

    _selectedCorregimiento = null;

    _selectedVillage = null;

    _errorMessage = null;

    notifyListeners();

    final int? departmentId = department?.id;

    if (departmentId == null) {
      await _reloadIndependentLocationLists();

      return;
    }

    await _loadMunicipalities(departmentId);

    // Mantener disponibles los corregimientos y veredas
    // para permitir búsqueda independiente.
    _corregimientos = await _repository.getCorregimientos();

    _villages = await _repository.getVillages();

    notifyListeners();
  }

  // =============================================================
  // CARGAR MUNICIPIOS
  // =============================================================

  Future<void> _loadMunicipalities(int departmentId) async {
    _setLoading(true);

    try {
      _municipalities = await _repository.getMunicipalitiesByDepartment(
        departmentId,
      );

      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'No fue posible cargar los municipios.';

      if (kDebugMode) {
        debugPrint('Error al cargar municipios: $error');
      }
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // SELECCIONAR MUNICIPIO
  // =============================================================

  Future<void> selectMunicipality(MunicipalityModel? municipality) async {
    _selectedMunicipality = municipality;

    _selectedCorregimiento = null;

    _selectedVillage = null;

    _errorMessage = null;

    final int? municipalityId = municipality?.id;

    if (municipalityId == null) {
      _selectedDepartment = null;
      notifyListeners();
      await _reloadIndependentLowerLocationLists();
      return;
    }

    // Si el municipio fue encontrado mediante búsqueda independiente,
    // sincronizamos automáticamente su departamento real.
    _selectedDepartment = _findById(_departments, municipality!.departmentId);

    // Si por alguna razón la lista de departamentos no estuviera cargada,
    // recargamos las ubicaciones sin alterar la lógica existente.
    if (_selectedDepartment == null) {
      final List<DepartmentModel> departments = await _repository
          .getDepartments();
      _departments = departments;
      _selectedDepartment = _findById(_departments, municipality.departmentId);
    }

    notifyListeners();

    await _loadCorregimientos(municipalityId);

    await _loadVillages();
  }

  // =============================================================
  // CARGAR CORREGIMIENTOS
  // =============================================================

  Future<void> _loadCorregimientos(int municipalityId) async {
    _setLoading(true);

    try {
      _corregimientos = await _repository.getCorregimientosByMunicipality(
        municipalityId,
      );

      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'No fue posible cargar los corregimientos.';

      if (kDebugMode) {
        debugPrint('Error al cargar corregimientos: $error');
      }
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // SELECCIONAR CORREGIMIENTO
  // =============================================================

  Future<void> selectCorregimiento(CorregimientoModel? corregimiento) async {
    _selectedCorregimiento = corregimiento;

    _selectedVillage = null;

    _villages = [];

    _errorMessage = null;

    final int? corregimientoId = corregimiento?.id;
    final int? municipalityId = corregimiento?.municipalityId;

    if (municipalityId == null) {
      _selectedMunicipality = null;
      _selectedDepartment = null;
      notifyListeners();
      await _loadVillages();
      return;
    }

    // Si el corregimiento fue encontrado mediante búsqueda independiente,
    // sincronizamos municipio y departamento con sus padres reales.
    _selectedMunicipality = _findById(_municipalities, municipalityId);

    if (_selectedMunicipality == null) {
      _municipalities = await _repository.getMunicipalities();
      _selectedMunicipality = _findById(_municipalities, municipalityId);
    }

    final int? departmentId = _selectedMunicipality?.departmentId;

    if (departmentId != null) {
      _selectedDepartment = _findById(_departments, departmentId);

      if (_selectedDepartment == null) {
        _departments = await _repository.getDepartments();
        _selectedDepartment = _findById(_departments, departmentId);
      }
    }

    notifyListeners();

    if (corregimientoId != null) {
      await _loadVillages();
    }
  }

  // =============================================================
  // CARGAR VEREDAS
  // =============================================================

  Future<void> _loadVillages() async {
    final int? departmentId = _selectedDepartment?.id;

    final int? municipalityId = _selectedMunicipality?.id;

    final int? corregimientoId = _selectedCorregimiento?.id;

    if (municipalityId == null) {
      _setLoading(true);

      try {
        _villages = await _repository.getVillages(
          departmentId: departmentId,
          municipalityId: null,
          corregimientoId: null,
        );

        _errorMessage = null;
      } catch (error) {
        _errorMessage = 'No fue posible cargar las veredas.';

        if (kDebugMode) {
          debugPrint('Error al cargar veredas: $error');
        }
      } finally {
        _setLoading(false);
      }

      return;
    }

    _setLoading(true);

    try {
      _villages = await _repository.getVillages(
        departmentId: departmentId,
        municipalityId: municipalityId,
        corregimientoId: corregimientoId,
      );

      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'No fue posible cargar las veredas.';

      if (kDebugMode) {
        debugPrint('Error al cargar veredas: $error');
      }
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // SELECCIONAR VEREDA
  // =============================================================

  Future<void> selectVillage(VillageModel? village) async {
    _selectedVillage = village;

    _errorMessage = null;

    final int? municipalityId = village?.municipalityId;
    final int? villageDepartmentId = village?.departmentId;
    final int? corregimientoId = village?.corregimientoId;

    if (municipalityId != null) {
      // Una vereda seleccionada desde búsqueda independiente debe recuperar
      // también su municipio y departamento reales.
      _selectedMunicipality = _findById(_municipalities, municipalityId);

      if (_selectedMunicipality == null) {
        _municipalities = await _repository.getMunicipalities();
        _selectedMunicipality = _findById(_municipalities, municipalityId);
      }

      final int? departmentId =
          _selectedMunicipality?.departmentId ?? villageDepartmentId;

      if (departmentId != null) {
        _selectedDepartment = _findById(_departments, departmentId);

        if (_selectedDepartment == null) {
          _departments = await _repository.getDepartments();
          _selectedDepartment = _findById(_departments, departmentId);
        }
      }
    } else if (villageDepartmentId != null) {
      _selectedDepartment = _findById(_departments, villageDepartmentId);

      if (_selectedDepartment == null) {
        _departments = await _repository.getDepartments();
        _selectedDepartment = _findById(_departments, villageDepartmentId);
      }

      _selectedMunicipality = null;
    } else {
      _selectedMunicipality = null;
      _selectedDepartment = null;
    }

    if (corregimientoId != null) {
      _selectedCorregimiento = _findById(_corregimientos, corregimientoId);

      if (_selectedCorregimiento == null) {
        _corregimientos = await _repository.getCorregimientos();
        _selectedCorregimiento = _findById(_corregimientos, corregimientoId);
      }
    } else {
      _selectedCorregimiento = null;
    }

    notifyListeners();
  }

  // =============================================================
  // AGREGAR DEPARTAMENTO
  // =============================================================

  Future<bool> addDepartment({required String name, String? code}) async {
    final String cleanName = _cleanName(name);

    if (cleanName.isEmpty) {
      _errorMessage = 'Ingrese el nombre del departamento.';

      notifyListeners();

      return false;
    }

    _setLoading(true);

    try {
      final int id = await _repository.addDepartment(
        name: cleanName,
        code: code,
      );

      _departments = await _repository.getDepartments();

      _selectedDepartment = _findById(_departments, id);

      _selectedMunicipality = null;

      _selectedCorregimiento = null;

      _selectedVillage = null;

      _municipalities = await _repository.getMunicipalities();

      _corregimientos = await _repository.getCorregimientos();

      _villages = await _repository.getVillages();

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (error) {
      _errorMessage = _friendlyDatabaseError(error, 'departamento');

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // AGREGAR MUNICIPIO
  // =============================================================

  Future<bool> addMunicipality({required String name, String? code}) async {
    final int? departmentId = _selectedDepartment?.id;

    if (departmentId == null) {
      _errorMessage = 'Primero debe seleccionar un departamento.';

      notifyListeners();

      return false;
    }

    final String cleanName = _cleanName(name);

    if (cleanName.isEmpty) {
      _errorMessage = 'Ingrese el nombre del municipio.';

      notifyListeners();

      return false;
    }

    _setLoading(true);

    try {
      final int id = await _repository.addMunicipality(
        departmentId: departmentId,
        name: cleanName,
        code: code,
      );

      _municipalities = await _repository.getMunicipalitiesByDepartment(
        departmentId,
      );

      _selectedMunicipality = _findById(_municipalities, id);

      _selectedCorregimiento = null;

      _selectedVillage = null;

      _corregimientos = [];

      _villages = [];

      // -----------------------------------------------------------
      // CARGAR LOS CORREGIMIENTOS DEL NUEVO MUNICIPIO
      // -----------------------------------------------------------

      if (_selectedMunicipality?.id != null) {
        _corregimientos = await _repository.getCorregimientosByMunicipality(
          _selectedMunicipality!.id!,
        );

        _villages = await _repository.getVillages(
          departmentId: departmentId,
          municipalityId: _selectedMunicipality!.id!,
        );
      }

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (error) {
      _errorMessage = _friendlyDatabaseError(error, 'municipio');

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // AGREGAR CORREGIMIENTO
  // =============================================================

  Future<bool> addCorregimiento({required String name, String? code}) async {
    final int? municipalityId = _selectedMunicipality?.id;

    if (municipalityId == null) {
      _errorMessage = 'Primero debe seleccionar un municipio.';

      notifyListeners();

      return false;
    }

    final String cleanName = _cleanName(name);

    if (cleanName.isEmpty) {
      _errorMessage = 'Ingrese el nombre del corregimiento.';

      notifyListeners();

      return false;
    }

    _setLoading(true);

    try {
      final int id = await _repository.addCorregimiento(
        municipalityId: municipalityId,
        name: cleanName,
        code: code,
      );

      _corregimientos = await _repository.getCorregimientosByMunicipality(
        municipalityId,
      );

      _selectedCorregimiento = _findById(_corregimientos, id);

      _selectedVillage = null;

      _villages = [];

      // -----------------------------------------------------------
      // CARGAR LAS VEREDAS DEL NUEVO CORREGIMIENTO
      // -----------------------------------------------------------

      await _loadVillages();

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (error) {
      _errorMessage = _friendlyDatabaseError(error, 'corregimiento');

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // AGREGAR VEREDA
  // =============================================================

  Future<bool> addVillage({required String name, String? code}) async {
    final int? departmentId = _selectedDepartment?.id;

    final int? municipalityId = _selectedMunicipality?.id;

    final int? corregimientoId = _selectedCorregimiento?.id;

    if (municipalityId == null) {
      _errorMessage = 'Primero debe seleccionar un municipio.';

      notifyListeners();

      return false;
    }

    final String cleanName = _cleanName(name);

    if (cleanName.isEmpty) {
      _errorMessage = 'Ingrese el nombre de la vereda.';

      notifyListeners();

      return false;
    }

    _setLoading(true);

    try {
      final int id = await _repository.addVillage(
        name: cleanName,
        departmentId: departmentId,
        municipalityId: municipalityId,
        corregimientoId: corregimientoId,
        code: code,
      );

      _villages = await _repository.getVillages(
        departmentId: departmentId,
        municipalityId: municipalityId,
        corregimientoId: corregimientoId,
      );

      _selectedVillage = _findById(_villages, id);

      _errorMessage = null;

      notifyListeners();

      return true;
    } catch (error) {
      _errorMessage = _friendlyDatabaseError(error, 'vereda');

      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // INICIALIZAR DESDE NOMBRES
  // =============================================================

  Future<void> initializeFromNames({
    String? departmentName,
    String? municipalityName,
    String? corregimientoName,
    String? villageName,
  }) async {
    // -------------------------------------------------------------
    // CARGAMOS LAS CUATRO LISTAS.
    // -------------------------------------------------------------

    await loadAllLocations();

    final String departmentValue = _cleanName(departmentName ?? '');

    final String municipalityValue = _cleanName(municipalityName ?? '');

    final String corregimientoValue = _cleanName(corregimientoName ?? '');

    final String villageValue = _cleanName(villageName ?? '');

    // -------------------------------------------------------------
    // DEPARTAMENTO
    // -------------------------------------------------------------

    if (departmentValue.isNotEmpty) {
      final DepartmentModel? department = _findByName(
        _departments,
        departmentValue,
      );

      if (department != null) {
        await selectDepartment(department);
      }
    }

    // -------------------------------------------------------------
    // MUNICIPIO
    // -------------------------------------------------------------

    if (municipalityValue.isNotEmpty) {
      MunicipalityModel? municipality = _findByName(
        _municipalities,
        municipalityValue,
      );

      // Si ya existe un departamento seleccionado, NO buscamos el municipio
      // globalmente: debe pertenecer a ese departamento.
      if (municipality == null && _selectedDepartment == null) {
        final List<MunicipalityModel> allMunicipalities = await _repository
            .getMunicipalities();

        municipality = _findByName(allMunicipalities, municipalityValue);
      }

      if (municipality != null) {
        await selectMunicipality(municipality);
      }
    }

    // -------------------------------------------------------------
    // CORREGIMIENTO
    // -------------------------------------------------------------

    if (corregimientoValue.isNotEmpty) {
      CorregimientoModel? corregimiento = _findByName(
        _corregimientos,
        corregimientoValue,
      );

      // Si ya existe un municipio seleccionado, NO buscamos el corregimiento
      // globalmente: debe pertenecer a ese municipio.
      if (corregimiento == null && _selectedMunicipality == null) {
        final List<CorregimientoModel> allCorregimientos = await _repository
            .getCorregimientos();

        corregimiento = _findByName(allCorregimientos, corregimientoValue);
      }

      if (corregimiento != null) {
        await selectCorregimiento(corregimiento);
      }
    }

    // -------------------------------------------------------------
    // VEREDA
    // -------------------------------------------------------------

    if (villageValue.isNotEmpty) {
      VillageModel? village = _findByName(_villages, villageValue);

      if (village == null) {
        final List<VillageModel> allVillages = await _repository.getVillages(
          departmentId: _selectedDepartment?.id,
          municipalityId: _selectedMunicipality?.id,
          corregimientoId: _selectedCorregimiento?.id,
        );

        village = _findByName(allVillages, villageValue);
      }

      if (village != null) {
        selectVillage(village);
      }
    }
  }

  // =============================================================
  // RECARGAR LISTAS INDEPENDIENTES
  // =============================================================

  Future<void> _reloadIndependentLocationLists() async {
    _setLoading(true);

    try {
      _municipalities = await _repository.getMunicipalities();

      _corregimientos = await _repository.getCorregimientos();

      _villages = await _repository.getVillages();

      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'No fue posible cargar las ubicaciones.';

      if (kDebugMode) {
        debugPrint('Error al recargar ubicaciones: $error');
      }
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // RECARGAR LISTAS INFERIORES INDEPENDIENTES
  // =============================================================

  Future<void> _reloadIndependentLowerLocationLists() async {
    _setLoading(true);

    try {
      _corregimientos = await _repository.getCorregimientos();

      _villages = await _repository.getVillages();

      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'No fue posible cargar las ubicaciones inferiores.';

      if (kDebugMode) {
        debugPrint('Error al recargar ubicaciones inferiores: $error');
      }
    } finally {
      _setLoading(false);
    }
  }

  // =============================================================
  // LIMPIAR SELECCIÓN
  // =============================================================

  void clearSelection() {
    _selectedDepartment = null;

    _selectedMunicipality = null;

    _selectedCorregimiento = null;

    _selectedVillage = null;

    _municipalities = [];

    _corregimientos = [];

    _villages = [];

    _errorMessage = null;

    notifyListeners();
  }

  // =============================================================
  // LIMPIAR ERROR
  // =============================================================

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }

  // =============================================================
  // UTILIDADES INTERNAS
  // =============================================================

  String _cleanName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // -------------------------------------------------------------
  // NORMALIZAR PARA COMPARACIÓN
  // -------------------------------------------------------------

  String _normalizeName(String value) {
    final String clean = _cleanName(value).toLowerCase();

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

  // -------------------------------------------------------------
  // BUSCAR POR ID
  // -------------------------------------------------------------

  T? _findById<T>(List<T> items, int id) {
    for (final T item in items) {
      final dynamic value = item;

      if (value.id == id) {
        return item;
      }
    }

    return null;
  }

  // -------------------------------------------------------------
  // BUSCAR POR NOMBRE
  // -------------------------------------------------------------

  T? _findByName<T>(List<T> items, String name) {
    final String target = _normalizeName(name);

    for (final T item in items) {
      final dynamic value = item;

      final String itemName = value.name.toString();

      if (_normalizeName(itemName) == target) {
        return item;
      }
    }

    return null;
  }

  // -------------------------------------------------------------
  // MENSAJES DE ERROR
  // -------------------------------------------------------------

  String _friendlyDatabaseError(Object error, String type) {
    final String message = error.toString().toLowerCase();

    if (message.contains('ya existe') ||
        message.contains('unique') ||
        message.contains('constraint')) {
      return 'El $type ya existe.';
    }

    if (message.contains('obligatorio')) {
      return error.toString();
    }

    return 'No fue posible guardar el $type.';
  }

  // -------------------------------------------------------------
  // ESTADO DE CARGA
  // -------------------------------------------------------------

  void _setLoading(bool value) {
    _isLoading = value;

    notifyListeners();
  }
}
