// ===============================================================
// APLICATIVO NANCY
// Selector de Ubicación — búsqueda independiente y contextual
// ===============================================================

import 'package:flutter/material.dart';

import '../../models/department_model.dart';
import '../../models/municipality_model.dart';
import '../../models/corregimiento_model.dart';
import '../../models/village_model.dart';
import '../../providers/location_provider.dart';

// ===============================================================
// MODELO DE SELECCIÓN
// ===============================================================

class LocationSelection {
  final DepartmentModel? department;
  final MunicipalityModel? municipality;
  final CorregimientoModel? corregimiento;
  final VillageModel? village;

  const LocationSelection({
    this.department,
    this.municipality,
    this.corregimiento,
    this.village,
  });

  String get departmentName => department?.name ?? '';

  String get municipalityName => municipality?.name ?? '';

  String get corregimientoName => corregimiento?.name ?? '';

  String get villageName => village?.name ?? '';

  bool get isComplete =>
      department != null &&
      municipality != null &&
      corregimiento != null &&
      village != null;

  bool get isEmpty =>
      department == null &&
      municipality == null &&
      corregimiento == null &&
      village == null;

  String get displayText {
    final parts = <String>[];

    if (departmentName.isNotEmpty) {
      parts.add(departmentName);
    }

    if (municipalityName.isNotEmpty) {
      parts.add(municipalityName);
    }

    if (corregimientoName.isNotEmpty) {
      parts.add(corregimientoName);
    }

    if (villageName.isNotEmpty) {
      parts.add(villageName);
    }

    return parts.join(' / ');
  }
}

// ===============================================================
// SELECTOR PRINCIPAL
// ===============================================================

class LocationSelector extends StatefulWidget {
  final String? initialDepartment;
  final String? initialMunicipality;
  final String? initialCorregimiento;
  final String? initialVillage;

  final LocationSelection? initialSelection;

  final ValueChanged<LocationSelection?>? onChanged;

  final String label;

  final String hint;

  final bool enabled;

  final bool required;

  const LocationSelector({
    super.key,
    this.initialDepartment,
    this.initialMunicipality,
    this.initialCorregimiento,
    this.initialVillage,
    this.initialSelection,
    this.onChanged,
    this.label = 'Ubicación',
    this.hint = 'Seleccione la ubicación',
    this.enabled = true,
    this.required = false,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  late final LocationProvider _provider;

  LocationSelection? _selection;

  @override
  void initState() {
    super.initState();

    _provider = LocationProvider();

    _selection = widget.initialSelection;

    _loadInitialSelection();
  }

  @override
  void dispose() {
    _provider.dispose();

    super.dispose();
  }

  Future<void> _loadInitialSelection() async {
    if (widget.initialSelection != null) {
      return;
    }

    final bool hasInitialNames =
        (widget.initialDepartment?.trim().isNotEmpty ?? false) ||
        (widget.initialMunicipality?.trim().isNotEmpty ?? false) ||
        (widget.initialCorregimiento?.trim().isNotEmpty ?? false) ||
        (widget.initialVillage?.trim().isNotEmpty ?? false);

    if (!hasInitialNames) {
      await _provider.loadAllLocations();

      return;
    }

    await _provider.initializeFromNames(
      departmentName: widget.initialDepartment,
      municipalityName: widget.initialMunicipality,
      corregimientoName: widget.initialCorregimiento,
      villageName: widget.initialVillage,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selection = LocationSelection(
        department: _provider.selectedDepartment,
        municipality: _provider.selectedMunicipality,
        corregimiento: _provider.selectedCorregimiento,
        village: _provider.selectedVillage,
      );
    });
  }

  Future<void> _openSelector() async {
    if (!widget.enabled) {
      return;
    }

    await _provider.loadAllLocations();

    if (_selection != null && !_selection!.isEmpty) {
      await _provider.initializeFromNames(
        departmentName: _selection!.departmentName,
        municipalityName: _selection!.municipalityName,
        corregimientoName: _selection!.corregimientoName,
        villageName: _selection!.villageName,
      );
    }

    if (!mounted) {
      return;
    }

    final result = await showDialog<LocationSelection?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _LocationDialog(
          provider: _provider,
          initialSelection: _selection,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _selection = result;
    });

    widget.onChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasValue = _selection?.displayText.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.label}${widget.required ? ' *' : ''}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF24364B),
          ),
        ),
        const SizedBox(height: 9),
        InkWell(
          onTap: widget.enabled ? _openSelector : null,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF252A32)
                  : widget.enabled
                  ? const Color(0xFFFBFCFE)
                  : const Color(0xFFF1F3F6),
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF1E5AA8),
              ),
              suffixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF1E5AA8),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF4A5563)
                      : const Color(0xFFD8E1EC),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF4A5563)
                      : const Color(0xFFD8E1EC),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 17,
              ),
            ),
            child: Text(
              hasValue ? _selection!.displayText : widget.hint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                color: hasValue
                    ? (isDark ? Colors.white : const Color(0xFF24364B))
                    : (isDark ? Colors.white70 : const Color(0xFF7B8798)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ===============================================================
// DIÁLOGO ÚNICO
// ===============================================================

class _LocationDialog extends StatefulWidget {
  final LocationProvider provider;

  final LocationSelection? initialSelection;

  const _LocationDialog({
    required this.provider,
    required this.initialSelection,
  });

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  String _activeLevel = 'department';

  final _departmentSearch = TextEditingController();

  final _municipalitySearch = TextEditingController();

  final _corregimientoSearch = TextEditingController();

  final _villageSearch = TextEditingController();

  final _departmentAdd = TextEditingController();

  final _municipalityAdd = TextEditingController();

  final _corregimientoAdd = TextEditingController();

  final _villageAdd = TextEditingController();

  bool _addingDepartment = false;

  bool _addingMunicipality = false;

  bool _addingCorregimiento = false;

  bool _addingVillage = false;

  String? _validationMessage;

  LocationProvider get provider => widget.provider;

  @override
  void initState() {
    super.initState();

    _setInitialSearchValues();
  }

  @override
  void dispose() {
    _departmentSearch.dispose();

    _municipalitySearch.dispose();

    _corregimientoSearch.dispose();

    _villageSearch.dispose();

    _departmentAdd.dispose();

    _municipalityAdd.dispose();

    _corregimientoAdd.dispose();

    _villageAdd.dispose();

    super.dispose();
  }

  // =============================================================
  // CARGAR SELECCIONES EN LOS CAMPOS
  // =============================================================

  void _setInitialSearchValues() {
    final selection = widget.initialSelection;

    if (selection == null) {
      return;
    }

    _departmentSearch.text = selection.departmentName;

    _municipalitySearch.text = selection.municipalityName;

    _corregimientoSearch.text = selection.corregimientoName;

    _villageSearch.text = selection.villageName;

    if (selection.village != null) {
      _activeLevel = 'village';
    } else if (selection.corregimiento != null) {
      _activeLevel = 'corregimiento';
    } else if (selection.municipality != null) {
      _activeLevel = 'municipality';
    } else {
      _activeLevel = 'department';
    }
  }

  // =============================================================
  // CONTROLADORES DE BÚSQUEDA
  // =============================================================

  TextEditingController _searchController(String level) {
    switch (level) {
      case 'municipality':
        return _municipalitySearch;

      case 'corregimiento':
        return _corregimientoSearch;

      case 'village':
        return _villageSearch;

      default:
        return _departmentSearch;
    }
  }

  // =============================================================
  // CONTROLADORES DE AGREGAR
  // =============================================================

  TextEditingController _addController(String level) {
    switch (level) {
      case 'municipality':
        return _municipalityAdd;

      case 'corregimiento':
        return _corregimientoAdd;

      case 'village':
        return _villageAdd;

      default:
        return _departmentAdd;
    }
  }

  // =============================================================
  // ESTADO DE AGREGAR
  // =============================================================

  void _setAdding(String level, bool value) {
    setState(() {
      switch (level) {
        case 'municipality':
          _addingMunicipality = value;
          break;

        case 'corregimiento':
          _addingCorregimiento = value;
          break;

        case 'village':
          _addingVillage = value;
          break;

        default:
          _addingDepartment = value;
      }
    });
  }

  // =============================================================
  // ABRIR PÁGINA COMPLETA PARA BUSCAR UN NIVEL
  // =============================================================

  Future<void> _openLevelPage<T>({
    required String level,
    required String title,
    required String hint,
    required List<T> items,
    required T? selected,
    required String Function(T item) label,
    required Future<void> Function(T item) onSelected,
    required Future<bool> Function(String query) onAdd,
  }) async {
    final T? result = await Navigator.of(context, rootNavigator: true).push<T>(
      MaterialPageRoute(
        builder: (_) => _LocationLevelPage<T>(
          title: title,
          hint: hint,
          items: items,
          selected: selected,
          label: label,
          onAdd: onAdd,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    await onSelected(result);
  }

  // =============================================================
  // SELECCIONAR DEPARTAMENTO
  // =============================================================

  Future<void> _selectDepartment(DepartmentModel item) async {
    await provider.selectDepartment(item);

    if (!mounted) {
      return;
    }

    _departmentSearch.text = item.name;

    _municipalitySearch.clear();

    _corregimientoSearch.clear();

    _villageSearch.clear();

    setState(() {
      _activeLevel = 'municipality';

      _validationMessage = null;
    });
  }

  // =============================================================
  // SELECCIONAR MUNICIPIO
  // =============================================================

  Future<void> _selectMunicipality(MunicipalityModel item) async {
    await provider.selectMunicipality(item);

    if (!mounted) {
      return;
    }

    _departmentSearch.text = provider.selectedDepartment?.name ?? '';
    _municipalitySearch.text = provider.selectedMunicipality?.name ?? item.name;
    _corregimientoSearch.clear();
    _villageSearch.clear();

    setState(() {
      _activeLevel = 'corregimiento';
      _validationMessage = null;
    });
  }

  // =============================================================
  // SELECCIONAR CORREGIMIENTO
  // =============================================================

  Future<void> _selectCorregimiento(CorregimientoModel item) async {
    await provider.selectCorregimiento(item);

    if (!mounted) {
      return;
    }

    _departmentSearch.text = provider.selectedDepartment?.name ?? '';
    _municipalitySearch.text = provider.selectedMunicipality?.name ?? '';
    _corregimientoSearch.text =
        provider.selectedCorregimiento?.name ?? item.name;
    _villageSearch.clear();

    setState(() {
      _activeLevel = 'village';
      _validationMessage = null;
    });
  }

  // =============================================================
  // SELECCIONAR VEREDA
  // =============================================================

  Future<void> _selectVillage(VillageModel item) async {
    await provider.selectVillage(item);

    if (!mounted) {
      return;
    }

    _departmentSearch.text = provider.selectedDepartment?.name ?? '';
    _municipalitySearch.text = provider.selectedMunicipality?.name ?? '';
    _corregimientoSearch.text = provider.selectedCorregimiento?.name ?? '';
    _villageSearch.text = provider.selectedVillage?.name ?? item.name;

    setState(() {
      _activeLevel = 'village';
      _validationMessage = null;
    });
  }

  // =============================================================
  // GUARDAR NUEVO REGISTRO
  // =============================================================
  Future<bool> _saveNew(String level, [String? directValue]) async {
    final String value = (directValue ?? _addController(level).text).trim();

    if (value.isEmpty) {
      setState(() {
        _validationMessage = 'Escriba un nombre antes de guardar.';
      });
      return false;
    }

    bool success = false;

    switch (level) {
      case 'municipality':
        success = await provider.addMunicipality(name: value);
        break;

      case 'corregimiento':
        success = await provider.addCorregimiento(name: value);
        break;

      case 'village':
        success = await provider.addVillage(name: value);
        break;

      default:
        success = await provider.addDepartment(name: value);
    }

    if (!mounted) {
      return false;
    }

    if (success) {
      _addController(level).clear();

      _setAdding(level, false);

      _searchController(level).text = value;

      setState(() {
        _validationMessage = null;
        _activeLevel = level;
      });

      return true;
    } else {
      setState(() {
        _validationMessage =
            provider.errorMessage ?? 'No fue posible guardar el registro.';
      });

      provider.clearError();

      return false;
    }
  }
  // =============================================================
  // CANCELAR AGREGAR
  // =============================================================

  void _cancelAdd(String level) {
    _addController(level).clear();

    _setAdding(level, false);

    setState(() {
      _validationMessage = null;
    });
  }

  // =============================================================
  // DETERMINAR SI EL NIVEL PUEDE BUSCARSE
  // =============================================================

  bool _canOpen(String level) {
    switch (level) {
      case 'municipality':
        return true;

      case 'corregimiento':
        return true;

      case 'village':
        return true;

      default:
        return true;
    }
  }

  // =============================================================
  // VALIDACIÓN FINAL
  // =============================================================
  //
  // La ubicación solo se acepta cuando están seleccionados
  // los cuatro niveles.
  // =============================================================

  bool _validate() {
    if (provider.selectedDepartment == null) {
      setState(() {
        _validationMessage = 'Seleccione un departamento.';

        _activeLevel = 'department';
      });

      return false;
    }

    if (provider.selectedMunicipality == null) {
      setState(() {
        _validationMessage = 'Seleccione un municipio.';

        _activeLevel = 'municipality';
      });

      return false;
    }

    if (provider.selectedCorregimiento == null) {
      setState(() {
        _validationMessage = 'Seleccione un corregimiento.';

        _activeLevel = 'corregimiento';
      });

      return false;
    }

    if (provider.selectedVillage == null) {
      setState(() {
        _validationMessage = 'Seleccione una vereda.';

        _activeLevel = 'village';
      });

      return false;
    }

    return true;
  }

  // =============================================================
  // ACEPTAR Y REGISTRAR FRECUENCIA DE UBICACIONES
  // =============================================================

  Future<void> _accept() async {
    if (!_validate()) {
      return;
    }

    final department = provider.selectedDepartment!;
    final municipality = provider.selectedMunicipality!;
    final corregimiento = provider.selectedCorregimiento!;
    final village = provider.selectedVillage!;

    try {
      // Registrar departamento, excepto "No aplica".
      if (department.name.trim().toLowerCase() != 'no aplica') {
        await provider.registerLocationSelection(
          locationType: 'department',

          locationId: department.id!,
        );
      }

      // Registrar municipio, excepto "No aplica".
      if (municipality.name.trim().toLowerCase() != 'no aplica') {
        await provider.registerLocationSelection(
          locationType: 'municipality',

          locationId: municipality.id!,
        );
      }

      // Registrar corregimiento, excepto "No aplica".
      if (corregimiento.name.trim().toLowerCase() != 'no aplica') {
        await provider.registerLocationSelection(
          locationType: 'corregimiento',

          locationId: corregimiento.id!,
        );
      }

      // Registrar vereda, excepto "No aplica".
      if (village.name.trim().toLowerCase() != 'no aplica') {
        await provider.registerLocationSelection(
          locationType: 'village',

          locationId: village.id!,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        LocationSelection(
          department: department,
          municipality: municipality,
          corregimiento: corregimiento,
          village: village,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _validationMessage =
            'No fue posible registrar la selección. Intente nuevamente.';
      });
    }
  }

  // =============================================================
  // CONSTRUIR TARJETA
  // =============================================================
  Widget _buildSearchCard<T>({
    required BuildContext context,
    required String level,
    required String title,
    required String hint,
    required IconData icon,
    required T? selected,
    required List<T> items,
    required String Function(T) label,
    required bool enabled,
    required Future<void> Function(T item) onSelected,
    required bool isAdding,
    required VoidCallback onAdd,
    required VoidCallback onCancelAdd,
    required Future<void> Function() onSaveAdd,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String valueText = selected != null ? label(selected) : hint;

    final bool isActive = _activeLevel == level;

    final bool hasValue = selected != null;

    return InkWell(
      onTap: enabled
          ? () => _openLevelPage<T>(
              level: level,
              title: title,
              hint: hint,
              items: items,
              selected: selected,
              label: label,
              onSelected: onSelected,
              onAdd: (query) async {
                return await _saveNew(level, query);
              },
            )
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF39434F) : const Color(0xFFE5EAF0),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isActive
                    ? (isDark
                          ? const Color(0xFF263B55)
                          : const Color(0xFFEAF3FF))
                    : (isDark
                          ? const Color(0xFF29313B)
                          : const Color(0xFFF3F6FA)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: const Color(0xFF1E6ACB)),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF7A8798),
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    valueText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
                      color: hasValue
                          ? (isDark ? Colors.white : const Color(0xFF17365D))
                          : (isDark ? Colors.white60 : const Color(0xFF9AA5B1)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF1E6ACB),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    final double height = MediaQuery.of(context).size.height;

    final bool compact = width < 600;

    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E252D) : Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 24,
            vertical: 12,
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
          contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 4, 24, 22),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF263B55)
                      : const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF1E6ACB),
                  size: 27,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Seleccionar ubicación',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF17365D),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Define el lugar del aspirante',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF7A8798),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: compact ? width * .92 : 560,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: compact ? height * .52 : 620,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // =================================================
                    // DEPARTAMENTO
                    // =================================================
                    _buildSearchCard<DepartmentModel>(
                      context: context,
                      level: 'department',
                      title: 'Departamento',
                      hint: 'Buscar departamento...',
                      icon: Icons.map_outlined,
                      selected: provider.selectedDepartment,
                      items: provider.departments,
                      label: (item) => item.name,
                      enabled: _canOpen('department'),
                      onSelected: _selectDepartment,
                      isAdding: _addingDepartment,
                      onAdd: () => _setAdding('department', true),
                      onCancelAdd: () => _cancelAdd('department'),
                      onSaveAdd: () => _saveNew('department'),
                    ),

                    // =================================================
                    // MUNICIPIO
                    // =================================================
                    _buildSearchCard<MunicipalityModel>(
                      context: context,
                      level: 'municipality',
                      title: 'Municipio',
                      hint: 'Buscar municipio...',
                      icon: Icons.location_city_outlined,
                      selected: provider.selectedMunicipality,
                      items: provider.municipalities,
                      label: (item) => item.name,
                      enabled: _canOpen('municipality'),
                      onSelected: _selectMunicipality,
                      isAdding: _addingMunicipality,
                      onAdd: () => _setAdding('municipality', true),
                      onCancelAdd: () => _cancelAdd('municipality'),
                      onSaveAdd: () => _saveNew('municipality'),
                    ),

                    // =================================================
                    // CORREGIMIENTO
                    // =================================================
                    _buildSearchCard<CorregimientoModel>(
                      context: context,
                      level: 'corregimiento',
                      title: 'Corregimiento',
                      hint: 'Buscar corregimiento...',
                      icon: Icons.account_tree_outlined,
                      selected: provider.selectedCorregimiento,
                      items: provider.corregimientos,
                      label: (item) => item.name,
                      enabled: _canOpen('corregimiento'),
                      onSelected: _selectCorregimiento,
                      isAdding: _addingCorregimiento,
                      onAdd: () => _setAdding('corregimiento', true),
                      onCancelAdd: () => _cancelAdd('corregimiento'),
                      onSaveAdd: () => _saveNew('corregimiento'),
                    ),

                    // =================================================
                    // VEREDA
                    // =================================================
                    _buildSearchCard<VillageModel>(
                      context: context,
                      level: 'village',
                      title: 'Vereda',
                      hint: 'Buscar vereda...',
                      icon: Icons.landscape_outlined,
                      selected: provider.selectedVillage,
                      items: provider.villages,
                      label: (item) => item.name,
                      enabled: _canOpen('village'),
                      onSelected: _selectVillage,
                      isAdding: _addingVillage,
                      onAdd: () => _setAdding('village', true),
                      onCancelAdd: () => _cancelAdd('village'),
                      onSaveAdd: () => _saveNew('village'),
                    ),

                    // =================================================
                    // VALIDACIÓN
                    // =================================================
                    if (_validationMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _validationMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    // =================================================
                    // ERROR DEL PROVIDER
                    // =================================================
                    if (provider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    // =================================================
                    // CARGANDO
                    // =================================================
                    if (provider.isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.white
                            : const Color(0xFF1E6ACB),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF6FA8E8)
                              : const Color(0xFF1E6ACB),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _accept,
                      icon: const Icon(Icons.check_rounded, size: 22),
                      label: const Text(
                        'Aceptar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E6ACB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ===============================================================
// PÁGINA COMPLETA PARA SELECCIONAR UN NIVEL
// ===============================================================

class _LocationLevelPage<T> extends StatefulWidget {
  final String title;
  final String hint;
  final List<T> items;
  final T? selected;
  final String Function(T item) label;
  final Future<bool> Function(String query) onAdd;

  const _LocationLevelPage({
    required this.title,
    required this.hint,
    required this.items,
    required this.selected,
    required this.label,
    required this.onAdd,
  });

  @override
  State<_LocationLevelPage<T>> createState() => _LocationLevelPageState<T>();
}

class _LocationLevelPageState<T> extends State<_LocationLevelPage<T>> {
  final TextEditingController _searchController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =============================================================
  // FILTRAR RESULTADOS
  // =============================================================
  List<T> get _filteredItems {
    final String query = _normalize(_searchController.text);

    // Filtrar las opciones según lo que escriba el usuario.
    final List<T> results = widget.items.where((item) {
      final String name = _normalize(widget.label(item));

      return query.isEmpty || name.contains(query);
    }).toList();

    // Mostrar "No aplica" siempre primero.
    final List<T> noAplica = [];
    final List<T> others = [];

    for (final T item in results) {
      final String name = _normalize(widget.label(item));

      if (name == 'no aplica') {
        if (noAplica.isEmpty) {
          noAplica.add(item);
        }
      } else {
        others.add(item);
      }
    }

    // Mantener el orden recibido para las demás ubicaciones.
    return [...noAplica, ...others];
  }
  // =============================================================
  // NORMALIZAR TEXTO
  // =============================================================

  String _normalize(String value) {
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

  // =============================================================
  // MOSTRAR OPCIÓN DE AGREGAR
  // =============================================================

  bool get _showAddOption {
    final String query = _searchController.text.trim();

    if (query.isEmpty) {
      return false;
    }

    final String normalizedQuery = _normalize(query);

    // Revisamos TODA la lista, no solamente los resultados
    // filtrados. Así "bebe" y "bebé" se consideran iguales.
    return !widget.items.any(
      (item) => _normalize(widget.label(item)) == normalizedQuery,
    );
  }
  // =============================================================
  // COMPARAR SELECCIÓN
  // =============================================================

  bool _isSelected(T item) {
    if (widget.selected == null) {
      return false;
    }

    final dynamic selectedValue = widget.selected;
    final dynamic itemValue = item;

    if (selectedValue.id != null && itemValue.id != null) {
      return selectedValue.id == itemValue.id;
    }

    return identical(widget.selected, item);
  }

  // =============================================================
  // CONSTRUIR
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final List<T> filtered = _filteredItems;
    final bool showAdd = _showAddOption;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101820)
          : const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1B2733) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF24364B),
        elevation: 0,
        title: Text(
          'Seleccionar ${widget.title.toLowerCase()}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF24364B),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              // ===================================================
              // BUSCADOR
              // ===================================================
              TextField(
                controller: _searchController,
                autofocus: false,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF24364B),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: const Color(0xFF1E5AA8),

                textInputAction: TextInputAction.search,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF1E5AA8),
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar',
                          onPressed: () {
                            _searchController.clear();

                            setState(() {});
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF252A32) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD8E1EC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFD8E1EC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF1E5AA8),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ===================================================
              // LISTA COMPLETA Y DESPLAZABLE
              // ===================================================
              Expanded(
                child: filtered.isEmpty
                    ? ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          const SizedBox(height: 40),
                          Center(
                            child: Text(
                              'No se encontraron resultados.',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF7B8798),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (showAdd) ...[
                            const SizedBox(height: 16),
                            _buildAddOption(
                              context,
                              _searchController.text.trim(),
                            ),
                          ],
                        ],
                      )
                    : ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: filtered.length + (showAdd ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          if (showAdd && index == filtered.length) {
                            return _buildAddOption(
                              context,
                              _searchController.text.trim(),
                            );
                          }

                          final T item = filtered[index];

                          final bool selected = _isSelected(item);

                          return Material(
                            color: isDark
                                ? const Color(0xFF1B2733)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.of(context).pop<T>(item);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      selected
                                          ? Icons.check_circle_rounded
                                          : Icons.location_on_outlined,
                                      color: const Color(0xFF1E5AA8),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        widget.label(item),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF24364B),
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(
                                        Icons.check_rounded,
                                        color: Color(0xFF1E5AA8),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // OPCIÓN PARA AGREGAR
  // =============================================================

  Widget _buildAddOption(BuildContext context, String query) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF263443) : const Color(0xFFF1F6FD),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isSaving
            ? null
            : () async {
                setState(() {
                  _isSaving = true;
                });

                final bool saved = await widget.onAdd(query);

                if (!context.mounted) {
                  return;
                }

                if (saved) {
                  Navigator.of(context).pop();
                  return;
                }

                setState(() {
                  _isSaving = false;
                });
              },

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              if (_isSaving)
                const SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF1E5AA8),
                  ),
                )
              else
                const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Color(0xFF1E5AA8),
                  size: 23,
                ),

              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isSaving ? 'Guardando...' : 'Agregar $query',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9CC8FF)
                        : const Color(0xFF1E5AA8),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
