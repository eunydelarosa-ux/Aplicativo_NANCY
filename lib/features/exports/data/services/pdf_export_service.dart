// =============================================================
// APLICATIVO NANCY
// Servicio de Exportación a PDF
// =============================================================

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../applicants/models/applicant_model.dart';

class PdfExportService {
  PdfExportService();

  static const MethodChannel _channel = MethodChannel(
    'com.example.nancy_app/excel_export',
  );

  // =============================================================
  // GENERAR PDF TEMPORAL
  // =============================================================

  Future<File> exportApplicants({
    required List<ApplicantModel> applicants,
  }) async {
    final pw.Document pdf = pw.Document();

    final DateTime generatedAt = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),

        // =======================================================
        // ENCABEZADO
        // =======================================================
        header: (pw.Context context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.blueGrey200),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'NANCY - Reporte de aspirantes',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                'Pagina ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.blueGrey700,
                ),
              ),
            ],
          ),
        ),

        // =======================================================
        // CONTENIDO
        // =======================================================
        build: (pw.Context context) => [
          pw.Text(
            'Listado de aspirantes',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),

          pw.SizedBox(height: 4),

          pw.Text(
            'Generado el ${_formatDateTime(generatedAt)} - '
            'Total de registros: ${applicants.length}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.blueGrey700,
            ),
          ),

          pw.SizedBox(height: 16),

          // =====================================================
          // TABLA DE ASPIRANTES
          // =====================================================
          pw.TableHelper.fromTextArray(
            headers: const [
              'Documento',
              'Nombre completo',
              'Escolaridad',
              'Programa',
              'Telefono',
              'Departamento',
              'Municipio',
              'Corregimiento',
              'Vereda',
              'Responsable del registro',
              'Observaciones',
              'Estado de sincronización',
              'Fecha de registro',
            ],
            data: applicants.map((ApplicantModel applicant) {
              return [
                applicant.documentNumber,
                '${applicant.firstName} ${applicant.lastName}',
                applicant.schooling,
                applicant.program,
                applicant.phone,
                applicant.department,
                applicant.municipality,
                applicant.corregimiento,
                applicant.village,

                // Responsable: nombre, cédula y rol
                '${applicant.responsibleName}\n'
                    'CC: ${applicant.responsibleCedula}\n'
                    'Rol: ${applicant.responsibleRole}',

                applicant.observations,
                applicant.syncStatus,
                _formatDateTime(applicant.createdAt),
              ];
            }).toList(),

            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 7,
              color: PdfColors.white,
            ),

            cellStyle: const pw.TextStyle(fontSize: 6),

            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),

            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.blue50),

            border: pw.TableBorder.all(
              color: PdfColors.blueGrey200,
              width: 0.4,
            ),

            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 3,
              vertical: 4,
            ),

            cellAlignment: pw.Alignment.centerLeft,

            // ===================================================
            // ANCHOS DE COLUMNAS
            // ===================================================
            columnWidths: const {
              0: pw.FlexColumnWidth(1.2), // Documento
              1: pw.FlexColumnWidth(1.8), // Nombre completo
              2: pw.FlexColumnWidth(1.2), // Escolaridad
              3: pw.FlexColumnWidth(2.0), // Programa
              4: pw.FlexColumnWidth(1.2), // Telefono
              5: pw.FlexColumnWidth(1.5), // Departamento
              6: pw.FlexColumnWidth(1.1), // Municipio
              7: pw.FlexColumnWidth(1.6), // Corregimiento
              8: pw.FlexColumnWidth(1.2), // Vereda
              9: pw.FlexColumnWidth(2.0), // Responsable del registro
              10: pw.FlexColumnWidth(2.0), // Observaciones
              11: pw.FlexColumnWidth(1.8), // Estado de sincronización
              12: pw.FlexColumnWidth(1.7), // Fecha de registro
            },
          ),
        ],
      ),
    );

    // =============================================================
    // GENERAR BYTES DEL PDF
    // =============================================================

    final List<int> pdfBytes = await pdf.save();

    final String fileName = 'aspirantes_${_fileTimestamp(generatedAt)}.pdf';

    // =============================================================
    // ARCHIVO TEMPORAL PARA VISTA PREVIA
    //
    // NO SE GUARDA DEFINITIVAMENTE.
    // =============================================================

    final Directory temporaryDirectory = await getTemporaryDirectory();

    final File temporaryFile = File('${temporaryDirectory.path}/$fileName');

    await temporaryFile.writeAsBytes(pdfBytes, flush: true);

    return temporaryFile;
  }

  // =============================================================
  // GUARDAR PDF DEFINITIVAMENTE
  // =============================================================

  Future<String?> savePdf({required File file}) async {
    try {
      final List<int> fileBytes = await file.readAsBytes();

      final String fileName = file.path.split(Platform.pathSeparator).last;

      // =========================================================
      // ANDROID
      // =========================================================

      if (Platform.isAndroid) {
        final String? savedUri = await _saveFileOnAndroid(
          fileName: fileName,
          fileBytes: Uint8List.fromList(fileBytes),
        );

        if (savedUri == null || savedUri.trim().isEmpty) {
          throw Exception(
            'El guardado del archivo fue cancelado por el usuario.',
          );
        }

        // =======================================================
        // COPIA LOCAL PARA PODER ABRIR EL ARCHIVO DESDE LA APP
        // =======================================================

        final Directory directory = await getApplicationDocumentsDirectory();

        final File localFile = File('${directory.path}/$fileName');

        await localFile.writeAsBytes(fileBytes, flush: true);

        return localFile.path;
      }

      // =========================================================
      // OTRAS PLATAFORMAS
      // =========================================================

      final Directory directory = await getApplicationDocumentsDirectory();

      final File savedFile = File('${directory.path}/$fileName');

      await savedFile.writeAsBytes(fileBytes, flush: true);

      return savedFile.path;
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'No fue posible guardar el archivo PDF.');
    } catch (e) {
      throw Exception('Error al guardar el archivo PDF: $e');
    }
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
        'savePdfFile',
        <String, dynamic>{'fileName': fileName, 'bytes': fileBytes},
      );
    } on PlatformException catch (e) {
      throw Exception(e.message ?? 'No fue posible guardar el archivo PDF.');
    } catch (e) {
      throw Exception('Error al guardar el archivo PDF: $e');
    }
  }

  // =============================================================
  // GENERAR FECHA PARA EL NOMBRE DEL ARCHIVO
  // =============================================================

  String _fileTimestamp(DateTime date) {
    return '${date.year}_'
        '${date.month.toString().padLeft(2, '0')}_'
        '${date.day.toString().padLeft(2, '0')}_'
        '${date.hour.toString().padLeft(2, '0')}_'
        '${date.minute.toString().padLeft(2, '0')}_'
        '${date.second.toString().padLeft(2, '0')}';
  }

  // =============================================================
  // FORMATEAR FECHA
  // =============================================================

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
