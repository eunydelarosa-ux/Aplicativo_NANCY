// =============================================================
// APLICATIVO NANCY
// REGISTRO DE ASPIRANTES
// =============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/applicant_model.dart';
import '../../repositories/applicant_repository.dart';

import '../../../profile/models/user_profile_model.dart';
import '../../../profile/repositories/user_profile_repository.dart';

import '../../../catalogs/providers/catalog_provider.dart';

import '../../../location/providers/location_provider.dart';
import '../../../location/presentation/widgets/location_selector.dart';

import 'applicant_list_page.dart';

import '../widgets/personal_information_card.dart';
import '../widgets/academic_information_card.dart';
import '../widgets/contact_information_card.dart';
import '../widgets/observations_card.dart';
import '../widgets/save_button.dart';

// =============================================================
// PÁGINA DE REGISTRO
// =============================================================

class ApplicantRegisterPage extends StatefulWidget {
  final ApplicantModel? applicant;

  const ApplicantRegisterPage({super.key, this.applicant});

  @override
  State<ApplicantRegisterPage> createState() => _ApplicantRegisterPageState();
}

// =============================================================
// ESTADO
// =============================================================

class _ApplicantRegisterPageState extends State<ApplicantRegisterPage> {
  // =============================================================
  // PALETA VISUAL NANCY
  // =============================================================

  static const Color _primaryBlue = Color(0xFF1E5AA8);

  static const Color _institutionalGreen = Color(0xFF249A88);

  bool _isDark = false;

  Color get _softGreen =>
      _isDark ? const Color(0xFF183B35) : const Color(0xFFE8F6F1);

  Color get _backgroundColor =>
      _isDark ? const Color(0xFF101820) : const Color(0xFFF3F7FC);

  Color get _cardColor => _isDark ? const Color(0xFF1B2733) : Colors.white;

  Color get _silverColor =>
      _isDark ? const Color(0xFF354657) : const Color(0xFFDCE4EF);

  Color get _textColor => _isDark ? Colors.white : const Color(0xFF24364B);

  // =============================================================
  // GRADIENTE DEL ENCABEZADO
  // =============================================================

  LinearGradient get _headerGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: _isDark
        ? const [Color(0xFF142B45), Color(0xFF1D4268), Color(0xFF285783)]
        : const [Color(0xFF2F6097), Color(0xFF5E91C2), Color(0xFFBFD7EA)],
  );

  // =============================================================
  // CONTROLADOR DE PÁGINAS
  // =============================================================

  final PageController _pageController = PageController();

  int _currentStep = 0;

  final int _totalSteps = 2;

  // =============================================================
  // PROVIDER DE CATÁLOGOS
  // =============================================================
  //
  // SOLO se utiliza para:
  //
  // - document_type
  // - gender
  // - schooling
  // - program
  //
  // IMPORTANTE:
  // Departamento y municipio YA NO salen del catálogo.
  // =============================================================

  late final CatalogProvider _catalogProvider;

  // Provider de ubicación independiente de los catálogos.
  late final LocationProvider _locationProvider;

  // =============================================================
  // PERFIL DEL USUARIO RESPONSABLE DEL REGISTRO
  // =============================================================

  final UserProfileRepository _userProfileRepository = UserProfileRepository();

  UserProfileModel? _userProfile;

  // =============================================================
  // CONTROLADORES
  // INFORMACIÓN PERSONAL
  // =============================================================

  final TextEditingController _documentController = TextEditingController();

  final TextEditingController _firstNameController = TextEditingController();

  final TextEditingController _lastNameController = TextEditingController();

  final TextEditingController _birthDateController = TextEditingController();

  // =============================================================
  // CONTROLADORES
  // CONTACTO
  // =============================================================

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _addressController = TextEditingController();

  // =============================================================
  // OBSERVACIONES
  // =============================================================

  final TextEditingController _observationsController = TextEditingController();

  // =============================================================
  // VALORES DE LOS CATÁLOGOS
  // =============================================================

  String? _documentType;

  String? _gender;

  String? _schooling;

  String? _program;

  // =============================================================
  // UBICACIÓN
  // =============================================================
  //
  // La ubicación ya NO se administra mediante controles
  // independientes.
  //
  // Todo pasa por LocationSelector.
  // =============================================================

  LocationSelection? _locationSelection;

  // =============================================================
  // FECHA DE NACIMIENTO
  // =============================================================

  DateTime? _birthDate;

  // =============================================================
  // ESTADO
  // =============================================================

  bool get _isEditing => widget.applicant != null;

  // =============================================================
  // CATÁLOGOS
  // =============================================================

  List<String> get _documentTypes => _getCatalogNames('document_type');

  List<String> get _genders => _getCatalogNames('gender');

  List<String> get _schoolings => _getCatalogNames('schooling');

  List<String> get _programs => _getCatalogNames('program');

  // =============================================================
  // OBTENER NOMBRES DEL CATÁLOGO
  // =============================================================

  List<String> _getCatalogNames(String catalogType) {
    return _catalogProvider.items
        .where(
          (item) =>
              item.catalogType.trim().toLowerCase() ==
              catalogType.trim().toLowerCase(),
        )
        .map((item) => item.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
  }

  // =============================================================
  // CAMBIOS DEL PROVIDER DE CATÁLOGOS
  // =============================================================

  void _onCatalogProviderChanged() {
    if (!mounted) return;

    setState(() {});
  }

  // =============================================================
  // CARGAR CATÁLOGOS
  // =============================================================

  Future<void> _loadCatalogs() async {
    await _catalogProvider.loadAll();
  }

  // =============================================================
  // CARGAR PERFIL DEL USUARIO
  // =============================================================

  Future<void> _loadUserProfile() async {
    try {
      final UserProfileModel? profile = await _userProfileRepository
          .getProfile();

      if (!mounted) return;

      setState(() {
        _userProfile = profile;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _userProfile = null;
      });
    }
  }

  // =============================================================
  // INICIALIZAR
  // =============================================================

  @override
  void initState() {
    super.initState();

    // ===========================================================
    // CATÁLOGOS
    // ===========================================================

    _catalogProvider = CatalogProvider();
    _locationProvider = LocationProvider();

    _catalogProvider.addListener(_onCatalogProviderChanged);

    _loadCatalogs();

    // ===========================================================
    // PERFIL DEL USUARIO
    // ===========================================================

    _loadUserProfile();

    // ===========================================================
    // EDITAR ASPIRANTE
    // ===========================================================

    final ApplicantModel? applicant = widget.applicant;

    if (applicant != null) {
      // ---------------------------------------------------------
      // INFORMACIÓN PERSONAL
      // ---------------------------------------------------------

      _documentController.text = applicant.documentNumber;

      _firstNameController.text = applicant.firstName;

      _lastNameController.text = applicant.lastName;

      _birthDate = applicant.birthDate;

      _birthDateController.text =
          '${applicant.birthDate.day.toString().padLeft(2, '0')}/'
          '${applicant.birthDate.month.toString().padLeft(2, '0')}/'
          '${applicant.birthDate.year}';

      _documentType = applicant.documentType.trim();

      _gender = applicant.gender.trim();

      // ---------------------------------------------------------
      // INFORMACIÓN ACADÉMICA
      // ---------------------------------------------------------

      _schooling = applicant.schooling.trim();

      _program = applicant.program.trim();

      // ---------------------------------------------------------
      // CONTACTO
      // ---------------------------------------------------------

      _phoneController.text = applicant.phone;

      _emailController.text = applicant.email;

      _addressController.text = applicant.address;

      // ---------------------------------------------------------
      // UBICACIÓN
      // ---------------------------------------------------------
      //
      // ApplicantModel guarda los nombres de ubicación como String.
      // LocationSelection, en cambio, guarda los modelos de las
      // tablas independientes de ubicación.
      //
      // Por eso NO se construye LocationSelection con Strings aquí.
      // La conversión nombre -> modelo se realiza de forma asíncrona
      // mediante LocationProvider.
      // ---------------------------------------------------------

      _loadInitialLocation(applicant);

      // ---------------------------------------------------------
      // OBSERVACIONES
      // ---------------------------------------------------------

      _observationsController.text = applicant.observations;
    }
  }

  // =============================================================
  // CARGAR UBICACIÓN INICIAL
  // =============================================================

  Future<void> _loadInitialLocation(ApplicantModel applicant) async {
    final String department = applicant.department.trim();
    final String municipality = applicant.municipality.trim();
    final String corregimiento = applicant.corregimiento.trim();
    final String village = applicant.village.trim();

    if (department.isEmpty &&
        municipality.isEmpty &&
        corregimiento.isEmpty &&
        village.isEmpty) {
      return;
    }

    try {
      await _locationProvider.initializeFromNames(
        departmentName: department.isEmpty ? null : department,
        municipalityName: municipality.isEmpty ? null : municipality,
        corregimientoName: corregimiento.isEmpty ? null : corregimiento,
        villageName: village.isEmpty ? null : village,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _locationSelection = LocationSelection(
          department: _locationProvider.selectedDepartment,
          municipality: _locationProvider.selectedMunicipality,
          corregimiento: _locationProvider.selectedCorregimiento,
          village: _locationProvider.selectedVillage,
        );
      });
    } catch (_) {
      // Si una ubicación antigua ya no existe en las tablas
      // independientes, se conserva la información original del
      // aspirante para que pueda ser revisada desde el selector.
      // No se crea un LocationSelection inválido con Strings.
    }
  }

  // =============================================================
  // FECHA DE NACIMIENTO
  // =============================================================

  Future<void> _selectBirthDate() async {
    final DateTime today = DateTime.now();

    // Última fecha de nacimiento permitida:
    // el aspirante debe tener al menos 10 años cumplidos.
    final DateTime latestAllowedBirthDate = DateTime(
      today.year - 10,
      today.month,
      today.day,
    );

    // Evita errores al editar un aspirante que ya tenga
    // registrada una fecha de nacimiento no permitida.
    final DateTime initialDate =
        _birthDate != null && !_birthDate!.isAfter(latestAllowedBirthDate)
        ? _birthDate!
        : latestAllowedBirthDate;

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: latestAllowedBirthDate,
      locale: const Locale('es', 'CO'),
      helpText: 'Seleccione la fecha de nacimiento',
      errorFormatText: 'Seleccione una fecha válida',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _birthDate = selectedDate;

      _birthDateController.text =
          '${selectedDate.day.toString().padLeft(2, '0')}/'
          '${selectedDate.month.toString().padLeft(2, '0')}/'
          '${selectedDate.year}';
    });
  }

  // =============================================================
  // SIGUIENTE PASO
  // =============================================================

  void _nextStep() {
    if (_currentStep >= _totalSteps - 1) {
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // =============================================================
  // PASO ANTERIOR
  // =============================================================

  void _previousStep() {
    if (_currentStep <= 0) {
      return;
    }

    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // =============================================================
  // VERIFICAR INFORMACIÓN
  // =============================================================

  bool get _hasFormData {
    final LocationSelection? location = _locationSelection;

    return _documentController.text.trim().isNotEmpty ||
        _firstNameController.text.trim().isNotEmpty ||
        _lastNameController.text.trim().isNotEmpty ||
        _birthDate != null ||
        _documentType != null ||
        _gender != null ||
        _schooling != null ||
        _program != null ||
        _phoneController.text.trim().isNotEmpty ||
        _emailController.text.trim().isNotEmpty ||
        _addressController.text.trim().isNotEmpty ||
        location?.department != null ||
        location?.municipality != null ||
        location?.corregimiento != null ||
        location?.village != null ||
        _observationsController.text.trim().isNotEmpty;
  }

  // =============================================================
  // CANCELAR REGISTRO
  // =============================================================

  Future<void> _cancelRegistration() async {
    if (!_hasFormData) {
      if (mounted) {
        context.pop();
      }

      return;
    }

    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _primaryBlue),
              SizedBox(width: 10),
              Expanded(child: Text('Cancelar registro')),
            ],
          ),
          content: const Text(
            'Hay información que aún no ha sido guardada. '
            'Si sale ahora, perderá los cambios realizados.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Continuar editando'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true && mounted) {
      context.pop();
    }
  }

  // =============================================================
  // GUARDAR ASPIRANTE
  // =============================================================

  Future<void> _saveApplicant() async {
    // ===========================================================
    // UBICACIÓN SELECCIONADA
    // ===========================================================

    final LocationSelection? location = _locationSelection;

    // ===========================================================
    // VALIDAR CAMPOS
    // ===========================================================

    final bool locationComplete =
        location != null &&
        location.isComplete &&
        location.departmentName.trim().isNotEmpty &&
        location.municipalityName.trim().isNotEmpty &&
        location.corregimientoName.trim().isNotEmpty &&
        location.villageName.trim().isNotEmpty;

    if (_documentType == null ||
        _documentController.text.trim().isEmpty ||
        _firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _birthDate == null ||
        _gender == null ||
        _schooling == null ||
        _program == null ||
        _phoneController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        !locationComplete) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Complete todos los campos obligatorios '
              'antes de guardar.',
            ),
          ),
        );

      return;
    }

    // =========================================================
    // VALIDAR EDAD MÍNIMA DE 10 AÑOS
    // =========================================================

    final DateTime today = DateTime.now();
    final DateTime latestAllowedBirthDate = DateTime(
      today.year - 10,
      today.month,
      today.day,
    );

    if (_birthDate != null && _birthDate!.isAfter(latestAllowedBirthDate)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Edad no permitida. El aspirante debe tener '
              'mínimo 10 años cumplidos para registrarse '
              'en un curso o programa.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );

      return;
    }

    // ===========================================================
    // VALIDAR RESPONSABLE DEL REGISTRO
    // SOLO PARA NUEVOS ASPIRANTES
    // ===========================================================

    if (!_isEditing &&
        (_userProfile == null ||
            _userProfile!.name.trim().isEmpty ||
            _userProfile!.role.trim().isEmpty)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No existe un perfil de usuario válido. '
              'Complete el nombre y cargo del perfil '
              'antes de registrar un aspirante.',
            ),
          ),
        );

      return;
    }

    try {
      // =========================================================
      // REPOSITORIO
      // =========================================================

      final ApplicantRepository repository = ApplicantRepository();

      // =========================================================
      // VERIFICAR DUPLICADO
      // =========================================================

      final bool duplicateExists = await repository.existsApplicantRegistration(
        documentType: _documentType!,
        documentNumber: _documentController.text.trim(),
        program: _program!,
        excludeApplicantId: _isEditing ? widget.applicant!.id : null,
      );

      if (duplicateExists) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Ya existe un aspirante activo registrado '
                'con el mismo tipo de documento, número de '
                'documento y programa.',
              ),
            ),
          );

        return;
      }

      // =========================================================
      // VALORES DE UBICACIÓN
      // =========================================================

      final String department = location.departmentName.trim();

      final String municipality = location.municipalityName.trim();

      final String corregimiento = location.corregimientoName.trim();

      final String village = location.villageName.trim();

      final DateTime now = DateTime.now();

      // =========================================================
      // MODELO
      // =========================================================

      final ApplicantModel applicant;

      // =========================================================
      // EDITAR ASPIRANTE
      // =========================================================

      if (_isEditing) {
        applicant = widget.applicant!.copyWith(
          documentType: _documentType!,
          documentNumber: _documentController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          birthDate: _birthDate!,
          gender: _gender!,
          schooling: _schooling!,
          program: _program!,
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          address: _addressController.text.trim(),

          // -----------------------------------------------------
          // UBICACIÓN
          // -----------------------------------------------------
          department: department,
          municipality: municipality,
          corregimiento: corregimiento,
          village: village,

          observations: _observationsController.text.trim(),

          updatedAt: now,
        );
      } else {
        // =======================================================
        // CREAR ASPIRANTE
        // =======================================================

        applicant = ApplicantModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),

          // =====================================================
          // INFORMACIÓN PERSONAL
          // =====================================================
          documentType: _documentType!,

          documentNumber: _documentController.text.trim(),

          firstName: _firstNameController.text.trim(),

          lastName: _lastNameController.text.trim(),

          birthDate: _birthDate!,

          gender: _gender!,

          // =====================================================
          // INFORMACIÓN ACADÉMICA
          // =====================================================
          schooling: _schooling!,

          program: _program!,

          // =====================================================
          // CONTACTO
          // =====================================================
          phone: _phoneController.text.trim(),

          email: _emailController.text.trim(),

          address: _addressController.text.trim(),

          // =====================================================
          // UBICACIÓN
          // =====================================================
          department: department,

          municipality: municipality,

          corregimiento: corregimiento,

          village: village,

          // =====================================================
          // OBSERVACIONES
          // =====================================================
          observations: _observationsController.text.trim(),

          // =====================================================
          // RESPONSABLE DEL REGISTRO
          // =====================================================
          responsibleName: _userProfile!.name.trim(),

          responsibleRole: _userProfile!.role.trim(),

          responsibleCedula: (_userProfile!.cedula ?? '').trim(),

          // =====================================================
          // IDENTIDAD INTERNA DEL ASPIRANTE
          // =====================================================
          createdByUserId: _userProfile!.id,

          siteId: _userProfile!.siteId,

          // =====================================================
          // SINCRONIZACIÓN
          // =====================================================
          syncStatus: 'Pendiente',

          // =====================================================
          // FECHAS
          // =====================================================
          createdAt: now,

          updatedAt: now,
        );
      }

      // =========================================================
      // GUARDAR O ACTUALIZAR
      // =========================================================

      if (_isEditing) {
        final int affectedRows = await repository.updateApplicant(applicant);

        if (affectedRows == 0) {
          if (!mounted) return;

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'No fue posible actualizar el aspirante. '
                  'El registro ya no está disponible o no tienes '
                  'permiso para modificarlo.',
                ),
              ),
            );

          return;
        }
      } else {
        await repository.insertApplicant(applicant);
      }

      if (!mounted) return;

      // =========================================================
      // SI ESTÁ EDITANDO
      // =========================================================

      if (_isEditing) {
        context.pop(applicant);

        return;
      }

      // =========================================================
      // LIMPIAR FORMULARIO
      // =========================================================

      setState(() {
        _documentController.clear();

        _firstNameController.clear();

        _lastNameController.clear();

        _birthDateController.clear();

        _phoneController.clear();

        _emailController.clear();

        _addressController.clear();

        _observationsController.clear();

        _documentType = null;

        _gender = null;

        _schooling = null;

        _program = null;

        _locationSelection = null;

        _birthDate = null;

        _currentStep = 0;
      });

      _pageController.jumpToPage(0);

      // =========================================================
      // CONFIRMACIÓN
      // =========================================================

      final String? action = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: _institutionalGreen,
                  size: 32,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aspirante guardado',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: const Text(
              'El registro fue guardado correctamente. '
              '¿Qué deseas hacer ahora?',
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actions: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop('continue');
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: _institutionalGreen,
                    side: const BorderSide(
                      color: _institutionalGreen,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Seguir agregando',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop('list');
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Ver lista',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          );
        },
      );

      // =========================================================
      // IR A LA LISTA
      // =========================================================

      if (!mounted) return;

      if (action == 'list') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ApplicantListPage(
              openedFromRegistration: true,
              highlightedApplicantId: applicant.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('No fue posible guardar los cambios: $e')),
        );
    }
  }

  // =============================================================
  // TÍTULO DEL PASO
  // =============================================================

  String get _currentStepTitle {
    const List<String> titles = [
      'Información personal y académica',
      'Información de contacto y ubicación',
    ];

    return titles[_currentStep];
  }

  // =============================================================
  // ENCABEZADO
  // =============================================================

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: _headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _cancelRegistration,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white,
                  ),

                  Expanded(
                    child: Text(
                      _isEditing ? 'Editar aspirante' : 'Registrar aspirante',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextButton(
                      onPressed: _cancelRegistration,
                      style: TextButton.styleFrom(
                        foregroundColor: _isDark
                            ? Colors.white
                            : _institutionalGreen,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _softGreen,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: _institutionalGreen,
                            size: 25,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            _currentStepTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Text(
                          '${_currentStep + 1} / $_totalSteps',
                          style: const TextStyle(
                            color: _institutionalGreen,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _buildStepIndicator(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // INDICADOR DE PASOS
  // =============================================================

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(_totalSteps, (index) {
        final bool isCompleted = index < _currentStep;

        final bool isActive = index == _currentStep;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == _totalSteps - 1 ? 0 : 7),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              height: 5,
              decoration: BoxDecoration(
                color: isCompleted || isActive
                    ? _institutionalGreen
                    : _silverColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      }),
    );
  }

  // =============================================================
  // TARJETA DEL PASO
  // =============================================================

  Widget _buildStepCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _silverColor.withValues(alpha: 0.85)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.only(top: 10, bottom: 28),
            child: child,
          ),
        ),
      ),
    );
  }

  // =============================================================
  // BOTÓN DEGRADADO
  // =============================================================

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF2F6097), Color(0xFF4F83BD), Color(0xFF7FAFD6)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: _cardColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(width: 8),

                Icon(icon, color: _cardColor, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // BOTÓN ANTERIOR
  // =============================================================

  Widget _buildPreviousButton() {
    return OutlinedButton.icon(
      onPressed: _previousStep,
      icon: const Icon(Icons.arrow_back_rounded, size: 22),
      label: const Text(
        'Anterior',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        foregroundColor: _institutionalGreen,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: _institutionalGreen.withValues(alpha: 0.65),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  // =============================================================
  // BOTONES DE NAVEGACIÓN
  // =============================================================

  Widget _buildNavigationButtons() {
    final bool isFirstStep = _currentStep == 0;

    final bool isLastStep = _currentStep == _totalSteps - 1;

    if (isLastStep) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(
          top: BorderSide(color: _silverColor.withValues(alpha: 0.7)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!isFirstStep) ...[
              Expanded(child: _buildPreviousButton()),

              const SizedBox(width: 12),
            ],

            Expanded(
              child: _buildGradientButton(
                onPressed: _nextStep,
                text: 'Continuar',
                icon: Icons.arrow_forward_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // BOTONES FINALES
  // =============================================================

  Widget _buildBottomFinalButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: _cardColor,
        border: Border(
          top: BorderSide(color: _silverColor.withValues(alpha: 0.7)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(child: _buildPreviousButton()),

            const SizedBox(width: 12),

            Expanded(child: SaveButton(onPressed: _saveApplicant)),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // LIBERAR RECURSOS
  // =============================================================

  @override
  void dispose() {
    _catalogProvider.removeListener(_onCatalogProviderChanged);

    _catalogProvider.dispose();

    _locationProvider.dispose();

    _pageController.dispose();

    _documentController.dispose();

    _firstNameController.dispose();

    _lastNameController.dispose();

    _birthDateController.dispose();

    _phoneController.dispose();

    _emailController.dispose();

    _addressController.dispose();

    _observationsController.dispose();

    super.dispose();
  }

  // =============================================================
  // INTERFAZ
  // =============================================================

  @override
  Widget build(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;
    final bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    final ThemeData currentTheme = Theme.of(context);
    final ColorScheme pageColorScheme = _isDark
        ? ColorScheme.dark(
            primary: _institutionalGreen,
            secondary: _primaryBlue,
            surface: _cardColor,
            error: Colors.redAccent,
            onSurface: Colors.white,
            onPrimary: Colors.white,
          )
        : currentTheme.colorScheme;

    return Theme(
      data: currentTheme.copyWith(
        colorScheme: pageColorScheme,
        scaffoldBackgroundColor: _backgroundColor,
        dialogTheme: currentTheme.dialogTheme.copyWith(
          backgroundColor: _cardColor,
        ),
        textTheme: _isDark
            ? currentTheme.textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              )
            : currentTheme.textTheme,
        iconTheme: _isDark
            ? const IconThemeData(color: Colors.white)
            : currentTheme.iconTheme,
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        resizeToAvoidBottomInset: true,
        body: Column(
          children: [
            // =====================================================
            // ENCABEZADO
            // =====================================================
            _buildHeader(),

            // =====================================================
            // CONTENIDO
            // =====================================================
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  // ===============================================
                  // PASO 1
                  // ===============================================
                  _buildStepCard(
                    child: Column(
                      children: [
                        // =========================================
                        // INFORMACIÓN PERSONAL
                        // =========================================
                        PersonalInformationCard(
                          documentController: _documentController,
                          firstNameController: _firstNameController,
                          lastNameController: _lastNameController,
                          birthDateController: _birthDateController,
                          documentType: _documentType,
                          gender: _gender,
                          documentTypes: _documentTypes,
                          genders: _genders,
                          onDocumentTypeChanged: (value) {
                            setState(() {
                              _documentType = value;
                            });
                          },
                          onGenderChanged: (value) {
                            setState(() {
                              _gender = value;
                            });
                          },
                          onBirthDateTap: _selectBirthDate,
                        ),

                        const SizedBox(height: 12),

                        // =========================================
                        // INFORMACIÓN ACADÉMICA
                        // =========================================
                        AcademicInformationCard(
                          schooling: _schooling,
                          program: _program,
                          schoolings: _schoolings,
                          programs: _programs,
                          onSchoolingChanged: (value) {
                            setState(() {
                              _schooling = value;
                            });
                          },
                          onProgramChanged: (value) {
                            setState(() {
                              _program = value;
                            });
                          },
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // ===============================================
                  // PASO 2
                  // ===============================================
                  _buildStepCard(
                    child: Column(
                      children: [
                        // =========================================
                        // CONTACTO Y UBICACIÓN
                        // =========================================
                        ContactInformationCard(
                          phoneController: _phoneController,
                          emailController: _emailController,
                          addressController: _addressController,

                          // ---------------------------------------
                          // UBICACIÓN
                          // ---------------------------------------
                          department:
                              _locationSelection?.departmentName ??
                              widget.applicant?.department,

                          municipality:
                              _locationSelection?.municipalityName ??
                              widget.applicant?.municipality,

                          corregimiento:
                              _locationSelection?.corregimientoName ??
                              widget.applicant?.corregimiento,

                          village:
                              _locationSelection?.villageName ??
                              widget.applicant?.village,

                          onLocationChanged: (selection) {
                            setState(() {
                              _locationSelection = selection;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        // =========================================
                        // OBSERVACIONES
                        // =========================================
                        ObservationsCard(controller: _observationsController),

                        const SizedBox(height: 26),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // =====================================================
            // NAVEGACIÓN INFERIOR
            // =====================================================
            if (!keyboardVisible)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _currentStep == _totalSteps - 1
                    ? _buildBottomFinalButtons()
                    : _buildNavigationButtons(),
              ),
          ],
        ),
      ),
    );
  }
}
