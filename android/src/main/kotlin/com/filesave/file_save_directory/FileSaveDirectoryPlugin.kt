package com.filesave.file_save_directory

import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.OutputStream

/** FileSaveDirectoryPlugin */
class FileSaveDirectoryPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.flutterPluginBinding = flutterPluginBinding
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.filesave/file_save_directory")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "saveFile") {
      val fileName = call.argument<String>("fileName")
      val fileBytes = call.argument<ByteArray>("fileBytes")
      val folder = call.argument<String>("folder") ?: "Downloads"

      if (fileName != null && fileBytes != null) {
        val isSaved = saveFileToFolder(fileName, fileBytes, folder)
        result.success(isSaved)
      } else {
        result.error("INVALID_ARGUMENTS", "Invalid arguments passed", null)
      }
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun saveFileToFolder(fileName: String, fileBytes: ByteArray, folder: String): Boolean {
    return try {
      var adjustedFileName = fileName
      var fileNumber = 1

      val resolver = flutterPluginBinding.applicationContext.contentResolver
      val contentUri = when (folder) {
        "Documents" -> {
          // For Documents, we need to use Files URI and specify the Documents directory
          MediaStore.Files.getContentUri("external")
        }
        else -> MediaStore.Downloads.EXTERNAL_CONTENT_URI
      }

      // Check if a file with the same name exists
      var cursor: Cursor? = resolver.query(
        contentUri,
        null,
        "${MediaStore.Downloads.DISPLAY_NAME} = ?",
        arrayOf(adjustedFileName),
        null
      )

      // Adjust file name until a unique one is found
      while (cursor != null && cursor.moveToFirst()) {
        adjustedFileName = "${fileNameWithoutExtension(fileName)} $fileNumber.${fileExtension(fileName)}"
        fileNumber++
        cursor = resolver.query(
          contentUri,
          null,
          "${MediaStore.Downloads.DISPLAY_NAME} = ?",
          arrayOf(adjustedFileName),
          null
        )
      }
      cursor?.close()

      // Create content values with the adjusted file name
      val contentValues = ContentValues().apply {
        put(MediaStore.Downloads.DISPLAY_NAME, adjustedFileName)
        put(MediaStore.Downloads.MIME_TYPE, getMimeType(adjustedFileName))
        put(MediaStore.Downloads.RELATIVE_PATH, 
          if (folder == "Documents") Environment.DIRECTORY_DOCUMENTS 
          else Environment.DIRECTORY_DOWNLOADS
        )
      }

      // Save the file
      val uri: Uri? = resolver.insert(contentUri, contentValues)
      uri?.let {
        val outputStream: OutputStream? = resolver.openOutputStream(it)
        outputStream?.use { stream ->
          stream.write(fileBytes)
          stream.flush()
        }
        return true
      } ?: false
    } catch (e: Exception) {
      e.printStackTrace()
      false
    }
  }

  private fun fileNameWithoutExtension(fileName: String): String {
    return fileName.substringBeforeLast(".")
  }

  private fun fileExtension(fileName: String): String {
    return fileName.substringAfterLast(".")
  }

  private fun getMimeType(fileName: String): String {
    val extension = fileName.substringAfterLast(".").lowercase()
    return when (extension) {
      "jpg", "jpeg", "png" -> "image/jpeg"
      "pdf" -> "application/pdf"
      "txt" -> "text/plain"
      "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      "zip" -> "application/zip"
      else -> "application/octet-stream"
    }
  }
}