// =============================================================
// APLICATIVO NANCY
// Servicio de Exportación a Excel
// =============================================================

import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../applicants/models/applicant_model.dart';

class ExcelExportService {
  ExcelExportService();

  static const MethodChannel _channel = MethodChannel(
    'com.example.nancy_app/excel_export',
  );

  // =============================================================
  // MÉTODO PRINCIPAL

  // =============================================================

  Future<File> exportApplicants({
    required List<ApplicantModel> applicants,
  }) async {
    final Uint8List fileBytes = await buildExcelBytes(applicants: applicants);

    return createPreviewFile(fileBytes: fileBytes);
  }

  // =============================================================
  // GENERAR EXCEL SIN GUARDAR
  // =============================================================

  Future<Uint8List> buildExcelBytes({
    required List<ApplicantModel> applicants,
  }) async {
    final Excel excel = Excel.createExcel();

    final String defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';

    final Sheet sheet = excel[defaultSheet];
    // Ahora tenemos 19 columnas.
    const int totalColumns = 19;

    // =============================================================
    // BORDES
    // =============================================================

    final Border tableBorder = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('#7F8C8D'),
    );

    final Border headerBorder = Border(
      borderStyle: BorderStyle.Medium,
      borderColorHex: ExcelColor.fromHexString('#1F4E78'),
    );

    final Border titleBorder = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('#1F4E78'),
    );

    // =============================================================
    // ESTILOS
    // =============================================================

    final CellStyle titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1F4E78'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: titleBorder,
      rightBorder: titleBorder,
      topBorder: titleBorder,
      bottomBorder: titleBorder,
    );

    final CellStyle subtitleStyle = CellStyle(
      italic: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#404040'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final CellStyle headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#2E75B6'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: headerBorder,
      rightBorder: headerBorder,
      topBorder: headerBorder,
      bottomBorder: headerBorder,
    );

    final CellStyle evenRowStyle = CellStyle(
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );

    final CellStyle oddRowStyle = CellStyle(
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      backgroundColorHex: ExcelColor.fromHexString('#EAF3F8'),
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );

    // =============================================================
    // TÍTULO
    // =============================================================

    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(
      'LISTADO DE ASPIRANTES',
    );

    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByColumnRow(columnIndex: totalColumns - 1, rowIndex: 0),
    );

    sheet.cell(CellIndex.indexByString('A1')).cellStyle = titleStyle;

    sheet.setMergedCellStyle(CellIndex.indexByString('A1'), titleStyle);

    sheet.setRowHeight(0, 28);

    // =============================================================
    // INFORMACIÓN DE GENERACIÓN
    // =============================================================

    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue(
      'Generado el ${_formatDateTime(DateTime.now())} - '
      'Total de registros: ${applicants.length}',
    );

    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByColumnRow(columnIndex: totalColumns - 1, rowIndex: 1),
    );

    sheet.cell(CellIndex.indexByString('A2')).cellStyle = subtitleStyle;

    sheet.setRowHeight(1, 20);

    // =============================================================
    // ENCABEZADOS
    // =============================================================

    final List<String> headers = [
      'Tipo de documento',
      'Número de documento',
      'Nombre',
      'Apellidos',
      'Fecha de nacimiento',
      'Género',
      'Escolaridad',
      'Programa',
      'Teléfono',
      'Correo electrónico',
      'Dirección',
      'Departamento',
      'Municipio',
      'Corregimiento',
      'Vereda',
      'Responsable del registro',
      'Observaciones',
      'Estado de sincronización',
      'Fecha de registro',
    ];

    const int headerRow = 2;

    sheet.appendRow(
      headers.map((String header) => TextCellValue(header)).toList(),
    );

    for (int column = 0; column < headers.length; column++) {
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: column,
                  rowIndex: headerRow,
                ),
              )
              .cellStyle =
          headerStyle;
    }

    sheet.setRowHeight(headerRow, 40);

    // =============================================================
    // ANCHOS DE COLUMNAS
    // =============================================================

    final List<double> columnWidths = [
      22, // Tipo de documento
      20, // Número de documento
      18, // Nombre
      20, // Apellidos
      18, // Fecha de nacimiento
      13, // Género
      22, // Escolaridad
      28, // Programa
      17, // Teléfono
      32, // Correo electrónico
      32, // Dirección
      20, // Departamento
      20, // Municipio
      24, // Corregimiento
      26, // Vereda
      38, // Responsable del registro
      40, // Observaciones
      25, // Estado
      20, // Fecha de registro
    ];

    for (int column = 0; column < columnWidths.length; column++) {
      sheet.setColumnWidth(column, columnWidths[column]);
    }

    // =============================================================
    // FILAS DE ASPIRANTES
    // =============================================================

    for (int index = 0; index < applicants.length; index++) {
      final ApplicantModel applicant = applicants[index];

      sheet.appendRow([
        TextCellValue(applicant.documentType),
        TextCellValue(applicant.documentNumber),
        TextCellValue(applicant.firstName),
        TextCellValue(applicant.lastName),
        TextCellValue(_formatDate(applicant.birthDate)),
        TextCellValue(applicant.gender),
        TextCellValue(applicant.schooling),
        TextCellValue(applicant.program),
        TextCellValue(applicant.phone),
        TextCellValue(applicant.email),
        TextCellValue(applicant.address),
        TextCellValue(applicant.department),
        TextCellValue(applicant.municipality),
        TextCellValue(applicant.corregimiento),
        TextCellValue(applicant.village),

        // Responsable del registro en una sola columna
        TextCellValue(
          '${applicant.responsibleName}\n'
          'CC: ${applicant.responsibleCedula}\n'
          'Rol: ${applicant.responsibleRole}',
        ),

        TextCellValue(applicant.observations),
        TextCellValue(applicant.syncStatus),
        TextCellValue(_formatDateTime(applicant.createdAt)),
      ]);

      final int dataRow = headerRow + 1 + index;

      final CellStyle rowStyle = index.isEven ? evenRowStyle : oddRowStyle;

      for (int column = 0; column < totalColumns; column++) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: column,
                    rowIndex: dataRow,
                  ),
                )
                .cellStyle =
            rowStyle;
      }

      sheet.setRowHeight(dataRow, 60);
    }

    // =============================================================
    // GENERAR ARCHIVO EN MEMORIA
    // =============================================================

    final List<int>? fileBytes = excel.encode();

    if (fileBytes == null) {
      throw Exception('No fue posible generar el archivo Excel.');
    }

    return Uint8List.fromList(fileBytes);
  }

  // =============================================================
  // CREAR ARCHIVO TEMPORAL PARA VISTA PREVIA
  //
  // Genera un archivo temporal que se puede abrir antes de que
  // el usuario decida guardarlo definitivamente.
  // =============================================================

  Future<File> createPreviewFile({required Uint8List fileBytes}) async {
    final DateTime now = DateTime.now();

    final String timestamp =
        '${now.year}_'
        '${now.month.toString().padLeft(2, '0')}_'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}_'
        '${now.minute.toString().padLeft(2, '0')}_'
        '${now.second.toString().padLeft(2, '0')}';

    final String fileName = 'vista_previa_aspirantes_$timestamp.xlsx';

    final Directory temporaryDirectory = await getTemporaryDirectory();

    final File previewFile = File('${temporaryDirectory.path}/$fileName');

    await previewFile.writeAsBytes(fileBytes, flush: true);

    return previewFile;
  }

  // =============================================================
  // ABRIR VISTA PREVIA
  // =============================================================

  Future<File> previewExcel({required List<ApplicantModel> applicants}) async {
    final Uint8List fileBytes = await buildExcelBytes(applicants: applicants);

    return createPreviewFile(fileBytes: fileBytes);
  }

  // =============================================================
  // GUARDAR EXCEL
  //
  // Este método se llamará DESPUÉS de la vista previa.
  // =============================================================

  Future<File> saveExcel({required Uint8List fileBytes}) async {
    final DateTime now = DateTime.now();

    final String timestamp =
        '${now.year}_'
        '${now.month.toString().padLeft(2, '0')}_'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}_'
        '${now.minute.toString().padLeft(2, '0')}_'
        '${now.second.toString().padLeft(2, '0')}';

    final String fileName = 'aspirantes_$timestamp.xlsx';

    // =============================================================
    // ANDROID
    // =============================================================

    if (Platform.isAndroid) {
      final String? savedUri = await _saveFileOnAndroid(
        fileName: fileName,
        fileBytes: fileBytes,
      );

      if (savedUri == null || savedUri.trim().isEmpty) {
        throw Exception('La exportación fue cancelada por el usuario.');
      }

      final Directory temporaryDirectory = await getTemporaryDirectory();

      final File temporaryFile = File('${temporaryDirectory.path}/$fileName');

      await temporaryFile.writeAsBytes(fileBytes, flush: true);

      return temporaryFile;
    }

    // =============================================================
    // OTRAS PLATAFORMAS
    // =============================================================

    final Directory directory = await getApplicationDocumentsDirectory();

    final File file = File('${directory.path}/$fileName');

    await file.writeAsBytes(fileBytes, flush: true);

    return file;
  }

  // =============================================================
  // GUARDAR EN ANDROID
  // =============================================================

  Future<String?> _saveFileOnAndroid({
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    try {
      return await _channel.invokeMethod<String>(
        'saveExcelFile',
        <String, dynamic>{'fileName': fileName, 'bytes': fileBytes},
      );
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'No fue posible guardar el archivo Excel.');
    } catch (e) {
      throw Exception('Error al guardar el archivo Excel: $e');
    }
  }

  // =============================================================
  // FORMATEAR FECHA
  // =============================================================

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // =============================================================
  // FORMATEAR FECHA Y HORA
  // =============================================================

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
