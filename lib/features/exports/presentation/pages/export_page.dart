// =============================================================
// APLICATIVO NANCY
// Página de Exportaciones
// =============================================================

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../../applicants/models/applicant_model.dart';
import '../../../applicants/repositories/applicant_repository.dart';

import '../../data/services/excel_export_service.dart';
import '../../data/services/pdf_export_service.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  // =============================================================
  // COLORES
  // =============================================================

  static const Color _primaryColor = Color(0xFF2D8FE5);

  static const Color _darkColor = Color(0xFF1F2A44);

  static const Color _backgroundColor = Color(0xFFF4F7FB);

  static const Color _borderColor = Color(0xFFE1E8F0);

  // =============================================================
  // REPOSITORIES / PROVIDERS
  // =============================================================

  final ApplicantRepository _applicantRepository = ApplicantRepository();

  final ExcelExportService _excelExportService = ExcelExportService();

  final PdfExportService _pdfExportService = PdfExportService();

  // =============================================================
  // DATOS
  // =============================================================

  List<ApplicantModel> _allApplicants = [];

  List<ApplicantModel> _filteredApplicants = [];

  // =============================================================
  // BÚSQUEDA GENERAL
  // =============================================================

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  // Filtro por fecha de registro
  DateTime? _startDate;
  DateTime? _endDate;

  // =============================================================
  // ESTADO
  // =============================================================

  bool _isLoading = true;

  String? _errorMessage;

  // =============================================================
  // PAGINACIÓN
  // =============================================================

  static const int _itemsPerPage = 10;

  int _currentPage = 0;

  // =============================================================
  // INIT STATE
  // =============================================================

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  // =============================================================
  // CARGAR DATOS
  // =============================================================

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final List<ApplicantModel> applicants = await _applicantRepository
          .getAllApplicants();

      if (!mounted) return;

      setState(() {
        _allApplicants = applicants;

        _filteredApplicants = List.from(applicants);

        _currentPage = 0;

        _isLoading = false;
      });

      _refreshResults();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _errorMessage = 'No fue posible cargar la información.';
      });
    }
  }

  // =============================================================
  // PAGINACIÓN
  // =============================================================

  int get _totalPages {
    if (_filteredApplicants.isEmpty) {
      return 0;
    }

    return (_filteredApplicants.length / _itemsPerPage).ceil();
  }

  List<ApplicantModel> get _currentPageApplicants {
    if (_filteredApplicants.isEmpty) {
      return [];
    }

    final int startIndex = _currentPage * _itemsPerPage;

    if (startIndex >= _filteredApplicants.length) {
      return [];
    }

    final int endIndex = (startIndex + _itemsPerPage).clamp(
      0,
      _filteredApplicants.length,
    );

    return _filteredApplicants.sublist(startIndex, endIndex);
  }

  int get _firstItemNumber {
    if (_filteredApplicants.isEmpty) {
      return 0;
    }

    return (_currentPage * _itemsPerPage) + 1;
  }

  int get _lastItemNumber {
    if (_filteredApplicants.isEmpty) {
      return 0;
    }

    final int last = (_currentPage + 1) * _itemsPerPage;

    if (last > _filteredApplicants.length) {
      return _filteredApplicants.length;
    }

    return last;
  }

  // =============================================================
  // IR A UNA PÁGINA
  // =============================================================

  void _goToPage(int page) {
    if (page < 0 || page >= _totalPages) {
      return;
    }

    setState(() {
      _currentPage = page;
    });
  }

  // =============================================================
  // NORMALIZAR TEXTO DE BÚSQUEDA
  // =============================================================

  String _normalizeSearchText(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n');
  }

  // =============================================================
  // FILTRO POR FECHA DE REGISTRO
  // =============================================================

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _chooseStartDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? _endDate ?? now,
      firstDate: DateTime(2000),
      lastDate: _endDate ?? DateTime(now.year + 10),
      helpText: 'Seleccionar fecha inicial de registro',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
      if (_endDate != null && _startDate!.isAfter(_endDate!)) {
        _endDate = _startDate;
      }
    });
    _refreshResults();
  }

  Future<void> _chooseEndDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(now.year + 10),
      helpText: 'Seleccionar fecha final de registro',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _endDate = DateTime(picked.year, picked.month, picked.day);
      if (_startDate != null && _endDate!.isBefore(_startDate!)) {
        _startDate = _endDate;
      }
    });
    _refreshResults();
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _refreshResults();
  }

  bool _matchesDateRange(ApplicantModel applicant) {
    final DateTime registrationDate = applicant.createdAt;
    final DateTime dateOnly = DateTime(
      registrationDate.year,
      registrationDate.month,
      registrationDate.day,
    );

    if (_startDate != null && dateOnly.isBefore(_startDate!)) return false;
    if (_endDate != null && dateOnly.isAfter(_endDate!)) return false;
    return true;
  }

  int _relevanceScore(ApplicantModel applicant, String query) {
    if (query.isEmpty) return 0;

    final String fullName = _normalizeSearchText(
      '${applicant.firstName} ${applicant.lastName}',
    );
    final String firstName = _normalizeSearchText(applicant.firstName);
    final String lastName = _normalizeSearchText(applicant.lastName);
    final String document = _normalizeSearchText(applicant.documentNumber);

    if (fullName == query ||
        firstName == query ||
        lastName == query ||
        document == query) {
      return 0; // Coincidencia exacta
    }
    if (fullName.startsWith(query) ||
        firstName.startsWith(query) ||
        lastName.startsWith(query) ||
        document.startsWith(query)) {
      return 1; // Coincidencia al inicio
    }
    if (fullName.contains(query) ||
        firstName.contains(query) ||
        lastName.contains(query) ||
        document.contains(query)) {
      return 2; // Coincidencia en nombre, apellido o documento
    }
    return 3; // Coincidencia en otros campos
  }

  void _refreshResults() {
    final String query = _normalizeSearchText(_searchQuery);

    final List<ApplicantModel> results = _allApplicants.where((applicant) {
      if (!_matchesDateRange(applicant)) return false;
      if (query.isEmpty) return true;

      final List<String> searchableFields = [
        applicant.documentType,
        applicant.documentNumber,
        applicant.firstName,
        applicant.lastName,
        '${applicant.firstName} ${applicant.lastName}',
        applicant.birthDate.toString(),
        applicant.gender,
        applicant.schooling,
        applicant.program,
        applicant.phone,
        applicant.email,
        applicant.address,
        applicant.department,
        applicant.municipality,
        applicant.corregimiento,
        applicant.village,
        applicant.responsibleName,
        applicant.responsibleCedula,
        applicant.responsibleRole,
        applicant.observations,
        applicant.syncStatus,
        applicant.createdAt.toString(),
        applicant.updatedAt.toString(),
      ];

      return searchableFields.any(
        (field) => _normalizeSearchText(field).contains(query),
      );
    }).toList();

    results.sort((a, b) {
      final int scoreComparison = _relevanceScore(
        a,
        query,
      ).compareTo(_relevanceScore(b, query));
      if (scoreComparison != 0) return scoreComparison;
      return a.createdAt.compareTo(b.createdAt);
    });

    if (!mounted) return;
    setState(() {
      _filteredApplicants = results;
      _currentPage = 0;
    });
  }

  // =============================================================
  // BUSCAR ASPIRANTES POR TODOS LOS CRITERIOS
  // =============================================================

  void _searchApplicants(String value) {
    _searchQuery = value;
    _refreshResults();
  }

  // =============================================================
  // EXPORTAR A EXCEL
  // =============================================================

  Future<void> _exportToExcel() async {
    if (_filteredApplicants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay aspirantes para exportar.')),
      );
      return;
    }

    await _previewExcel();
  }

  // =============================================================
  // VISTA PREVIA DE EXCEL
  // =============================================================

  Future<void> _previewExcel() async {
    try {
      final File previewFile = await _excelExportService.exportApplicants(
        applicants: _filteredApplicants,
      );

      if (!mounted) return;

      final result = await OpenFilex.open(previewFile.path);

      if (!mounted) return;

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el archivo: ${result.message}'),
          ),
        );
        return;
      }

      await _showExportSuccessDialog(
        filePath: previewFile.path,
        fileType: 'Excel',
        saveFile: (String previewPath) async {
          final Uint8List fileBytes = await File(previewPath).readAsBytes();

          final File savedFile = await _excelExportService.saveExcel(
            fileBytes: fileBytes,
          );

          return savedFile.path;
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible generar el Excel: $e')),
      );
    }
  }

  // =============================================================
  // DIÁLOGO DE OPCIONES DESPUÉS DE LA VISTA PREVIA
  // =============================================================

  Future<void> _showExportSuccessDialog({
    required String filePath,
    required String fileType,
    Future<String?> Function(String filePath)? saveFile,
  }) async {
    if (!mounted) return;

    String currentFilePath = filePath;
    bool isSaved = false;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1B2936) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isSaved ? 'Archivo guardado' : 'Vista previa completada',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF26364F),
                ),
              ),
              content: Text(
                isSaved
                    ? 'El archivo $fileType fue guardado correctamente. '
                          'Ahora puedes abrirlo o volver a exportaciones.'
                    : 'El archivo $fileType fue abierto en vista previa. '
                          'Ahora puedes guardarlo o volver a exportaciones.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: isDark
                      ? const Color(0xFFC0CCD7)
                      : const Color(0xFF596579),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              actions: [
                // =================================================
                // GUARDAR ARCHIVO
                // =================================================
                if (!isSaved && saveFile != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setDialogState(() {
                                isSaving = true;
                              });

                              try {
                                final String? savedPath = await saveFile(
                                  currentFilePath,
                                );

                                if (!dialogContext.mounted) return;

                                if (savedPath == null ||
                                    savedPath.trim().isEmpty) {
                                  throw Exception(
                                    'No fue posible obtener la ubicación del archivo guardado.',
                                  );
                                }

                                setDialogState(() {
                                  currentFilePath = savedPath;
                                  isSaved = true;
                                  isSaving = false;
                                });

                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Archivo guardado correctamente.',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!dialogContext.mounted) return;

                                setDialogState(() {
                                  isSaving = false;
                                });

                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'No fue posible guardar el archivo: $e',
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_alt_rounded),
                      label: Text(
                        isSaving ? 'Guardando...' : 'Guardar archivo',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                /// =================================================
                // ABRIR ARCHIVO GUARDADO
                // =================================================
                if (isSaved)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await OpenFilex.open(currentFilePath);
                      },
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Abrir archivo guardado'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26364F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                if (!isSaved && saveFile != null) const SizedBox(height: 10),

                const SizedBox(height: 10),
                // =================================================
                // VOLVER
                // =================================================
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: _primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Volver a exportaciones',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =============================================================
  // EXPORTAR A PDF
  // =============================================================

  Future<void> _exportToPdf() async {
    if (_filteredApplicants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay aspirantes para exportar.')),
      );

      return;
    }

    try {
      // ===========================================================
      // 1. GENERAR PDF TEMPORAL
      // ===========================================================

      final File previewFile = await _pdfExportService.exportApplicants(
        applicants: _filteredApplicants,
      );

      if (!mounted) return;

      // ===========================================================
      // 2. ABRIR PDF PARA VISTA PREVIA
      // ===========================================================

      final result = await OpenFilex.open(previewFile.path);

      if (!mounted) return;

      // ===========================================================
      // 3. VERIFICAR QUE SE HAYA PODIDO ABRIR
      // ===========================================================

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el archivo: ${result.message}'),
          ),
        );

        return;
      }

      // ===========================================================
      // 4. MOSTRAR OPCIONES DESPUÉS DE LA VISTA PREVIA
      // ===========================================================

      await _showExportSuccessDialog(
        filePath: previewFile.path,
        fileType: 'PDF',
        saveFile: (String previewPath) async {
          return _pdfExportService.savePdf(file: File(previewPath));
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible generar el PDF: $e')),
      );
    }
  }

  // =============================================================
  // BARRA ÚNICA DE BÚSQUEDA PARA EXPORTACIONES
  // =============================================================

  Widget _buildUnifiedSearchBar(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: _searchController,

        onChanged: _searchApplicants,

        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFFE6EDF5) : const Color(0xFF1E293B),
        ),

        decoration: InputDecoration(
          hintText: 'Buscar nombre, documento, programa, ubicación...',

          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF91A1B2) : const Color(0xFF94A3B8),
          ),

          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 22,
            color: Color(0xFF2563A8),
          ),

          prefixIconConstraints: const BoxConstraints(minWidth: 46),

          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Limpiar búsqueda',

                  onPressed: () {
                    _searchController.clear();
                    _searchApplicants('');
                  },

                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: isDark
                        ? const Color(0xFFB6C2CE)
                        : const Color(0xFF64748B),
                  ),
                )
              : null,

          filled: true,
          fillColor: isDark ? const Color(0xFF1B2936) : const Color(0xFFF1F8FF),
          isDense: true,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF42617B) : const Color(0xFFB9DDFF),
              width: 1,
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF42617B) : const Color(0xFFB9DDFF),
              width: 1,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF5CAEF0), width: 1.4),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // FILTRO VISUAL POR FECHA DE REGISTRO
  // =============================================================

  Widget _buildRegistrationDateFilter(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasDateFilter = _startDate != null || _endDate != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A37) : const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF344F65) : const Color(0xFFD0E6FF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                'Filtrar por fecha de registro',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF26364F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _chooseStartDate,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(
                    _startDate == null ? 'Desde' : _formatDate(_startDate!),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _chooseEndDate,
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: Text(
                    _endDate == null ? 'Hasta' : _formatDate(_endDate!),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (hasDateFilter) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Quitar filtro de fechas',
                  onPressed: _clearDateFilter,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ],
          ),
          if (hasDateFilter)
            Text(
              'Se muestran aspirantes registrados dentro del rango elegido.',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFFB6C2CE)
                    : const Color(0xFF64748B),
              ),
            ),
        ],
      ),
    );
  }

  // =============================================================
  // TARJETA DE RESULTADO
  // =============================================================

  Widget _buildApplicantCard(ApplicantModel applicant, BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2936) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF344657) : _borderColor,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D8FE5), Color(0xFF6BB6F5)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${applicant.firstName} '
                  '${applicant.lastName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF26364F),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 14,
                      color: isDark
                          ? const Color(0xFFB6C2CE)
                          : const Color(0xFF8793A5),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        applicant.documentNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFFB6C2CE)
                              : const Color(0xFF8793A5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  applicant.program,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFFC0CCD7)
                        : const Color(0xFF596579),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildStatusBadge(applicant.syncStatus, context),
        ],
      ),
    );
  }

  // =============================================================
  // ESTADO
  // =============================================================

  Widget _buildStatusBadge(String status, BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(maxWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A3A49) : const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.isEmpty ? 'Sin estado' : status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFD5DEE8) : const Color(0xFF596579),
        ),
      ),
    );
  }

  // =============================================================
  // BOTONES DE EXPORTACIÓN
  // =============================================================

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _exportToExcel,
            icon: const Icon(Icons.table_chart_outlined),
            label: const Text('Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF168F5B),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _exportToPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE05A47),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // PAGINACIÓN
  // =============================================================

  Widget _buildPagination(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (_filteredApplicants.isEmpty || _totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2936) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF344657) : _borderColor,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Mostrando $_firstItemNumber - $_lastItemNumber '
            'de ${_filteredApplicants.length}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFC0CCD7) : const Color(0xFF596579),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Página anterior',
                onPressed: _currentPage > 0
                    ? () {
                        _goToPage(_currentPage - 1);
                      }
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF203849)
                      : const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Página ${_currentPage + 1} '
                  'de $_totalPages',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Página siguiente',
                onPressed: _currentPage < _totalPages - 1
                    ? () {
                        _goToPage(_currentPage + 1);
                      }
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101820) : _backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF17232E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                tooltip: 'Volver',
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark
                      ? const Color(0xFFE6EDF5)
                      : const Color(0xFF26364F),
                ),
              )
            : null,
        title: Text(
          'Exportaciones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2A44),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, color: _primaryColor),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  // =============================================================
  // CUERPO
  // =============================================================

  Widget _buildBody(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: Color(0xFFE57373),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF26364F),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Intentar nuevamente'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
        children: [
          // =====================================================
          // BOTONES DE EXPORTACIÓN
          // =====================================================
          _buildExportButtons(),

          const SizedBox(height: 14),

          // =====================================================
          // BARRA ÚNICA DE BÚSQUEDA
          // =====================================================
          _buildUnifiedSearchBar(context),

          // FILTRO POR FECHA DE REGISTRO
          _buildRegistrationDateFilter(context),

          // =====================================================
          // ASPIRANTES ENCONTRADOS
          // =====================================================
          // =====================================================
          // RESUMEN
          // =====================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: isDark
                    ? const [Color(0xFF203849), Color(0xFF243F54)]
                    : const [Color(0xFFEAF4FF), Color(0xFFD5E9FF)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF3B5B72)
                    : const Color(0xFFB9D9FF),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF294B61)
                        : const Color(0xFFD2E8FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.groups_rounded, color: _primaryColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aspirantes encontrados',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFFB6C2CE)
                              : const Color(0xFF8793A5),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_filteredApplicants.length} registros',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFF1F5F9) : _darkColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // =====================================================
          // LISTA DE ASPIRANTES
          // =====================================================
          if (_filteredApplicants.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2936) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF344657) : _borderColor,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 50,
                    color: Color(0xFF9AA5B5),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'No se encontraron aspirantes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF26364F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Intente con otro nombre, documento o criterio de búsqueda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFFB6C2CE)
                          : const Color(0xFF8793A5),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ..._currentPageApplicants.map(
              (ApplicantModel applicant) =>
                  _buildApplicantCard(applicant, context),
            ),
            _buildPagination(context),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =============================================================
  // DISPOSE
  // =============================================================
  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }
}
