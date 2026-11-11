package com.example.nancy_app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "com.example.nancy_app/excel_export"
    private val createFileRequestCode = 1001

    private var pendingResult: MethodChannel.Result? = null
    private var pendingFileBytes: ByteArray? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(
            flutterEngine!!.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveExcelFile" -> saveFile(
                    result = result,
                    fileName = call.argument("fileName"),
                    bytes = call.argument("bytes"),
                    mimeType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    fileLabel = "Excel"
                )

                "savePdfFile" -> saveFile(
                    result = result,
                    fileName = call.argument("fileName"),
                    bytes = call.argument("bytes"),
                    mimeType = "application/pdf",
                    fileLabel = "PDF"
                )

                else -> result.notImplemented()
            }
        }
    }

    private fun saveFile(
        result: MethodChannel.Result,
        fileName: String?,
        bytes: ByteArray?,
        mimeType: String,
        fileLabel: String
    ) {
        if (fileName == null || bytes == null) {
            result.error(
                "INVALID_DATA",
                "No se recibio correctamente el archivo $fileLabel.",
                null
            )
            return
        }

        pendingResult = result
        pendingFileBytes = bytes

        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            putExtra(Intent.EXTRA_TITLE, fileName)
        }

        startActivityForResult(intent, createFileRequestCode)
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != createFileRequestCode) return

        val result = pendingResult
        val bytes = pendingFileBytes

        pendingResult = null
        pendingFileBytes = null

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result?.success(null)
            return
        }

        if (bytes == null) {
            result?.error(
                "NO_DATA",
                "No se encontraron los datos del archivo.",
                null
            )
            return
        }

        val uri: Uri = data.data!!

        try {
            contentResolver.openOutputStream(uri)?.use { outputStream ->
                outputStream.write(bytes)
                outputStream.flush()
            } ?: throw IllegalStateException("No fue posible abrir la ubicacion elegida.")

            result?.success(uri.toString())
        } catch (e: Exception) {
            result?.error(
                "SAVE_ERROR",
                "No fue posible guardar el archivo.",
                e.message
            )
        }
    }
}
