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
      
      // Determine the appropriate content URI and relative path based on the folder
      val (contentUri, relativePath) = when (folder) {
        "Documents" -> {
          Pair(
            MediaStore.Files.getContentUri("external"),
            Environment.DIRECTORY_DOCUMENTS
          )
        }
        "Music" -> {
          // Use Audio content URI for music files
          val extension = fileExtension(fileName).lowercase()
          if (extension in listOf("mp3", "wav", "m4a", "flac", "ogg", "aac")) {
            Pair(
              MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
              Environment.DIRECTORY_MUSIC
            )
          } else {
            // For non-audio files in Music folder, use Files URI
            Pair(
              MediaStore.Files.getContentUri("external"),
              Environment.DIRECTORY_MUSIC
            )
          }
        }
        "Videos" -> {
          // Use Video content URI for video files
          val extension = fileExtension(fileName).lowercase()
          if (extension in listOf("mp4", "avi", "mkv", "mov", "wmv", "flv", "webm", "m4v", "3gp")) {
            Pair(
              MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
              Environment.DIRECTORY_MOVIES
            )
          } else {
            // For non-video files in Videos folder, use Files URI
            Pair(
              MediaStore.Files.getContentUri("external"),
              Environment.DIRECTORY_MOVIES
            )
          }
        }
        else -> {
          Pair(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            Environment.DIRECTORY_DOWNLOADS
          )
        }
      }

      // Determine the correct column name based on content URI
      val displayNameColumn = when {
        contentUri == MediaStore.Audio.Media.EXTERNAL_CONTENT_URI -> MediaStore.Audio.Media.DISPLAY_NAME
        contentUri == MediaStore.Video.Media.EXTERNAL_CONTENT_URI -> MediaStore.Video.Media.DISPLAY_NAME
        contentUri == MediaStore.Downloads.EXTERNAL_CONTENT_URI -> MediaStore.Downloads.DISPLAY_NAME
        else -> MediaStore.Files.FileColumns.DISPLAY_NAME
      }

      // Check if a file with the same name exists
      var cursor: Cursor? = resolver.query(
        contentUri,
        null,
        "$displayNameColumn = ?",
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
          "$displayNameColumn = ?",
          arrayOf(adjustedFileName),
          null
        )
      }
      cursor?.close()

      // Create content values with the adjusted file name
      val contentValues = ContentValues().apply {
        when {
          contentUri == MediaStore.Audio.Media.EXTERNAL_CONTENT_URI -> {
            put(MediaStore.Audio.Media.DISPLAY_NAME, adjustedFileName)
            put(MediaStore.Audio.Media.MIME_TYPE, getMimeType(adjustedFileName))
            put(MediaStore.Audio.Media.RELATIVE_PATH, relativePath)
            // Add audio-specific metadata if needed
            put(MediaStore.Audio.Media.IS_MUSIC, 1)
          }
          contentUri == MediaStore.Video.Media.EXTERNAL_CONTENT_URI -> {
            put(MediaStore.Video.Media.DISPLAY_NAME, adjustedFileName)
            put(MediaStore.Video.Media.MIME_TYPE, getMimeType(adjustedFileName))
            put(MediaStore.Video.Media.RELATIVE_PATH, relativePath)
            // Add video-specific metadata if needed
            put(MediaStore.Video.Media.IS_PENDING, 0)
          }
          contentUri == MediaStore.Downloads.EXTERNAL_CONTENT_URI -> {
            put(MediaStore.Downloads.DISPLAY_NAME, adjustedFileName)
            put(MediaStore.Downloads.MIME_TYPE, getMimeType(adjustedFileName))
            put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
          }
          else -> {
            put(MediaStore.Files.FileColumns.DISPLAY_NAME, adjustedFileName)
            put(MediaStore.Files.FileColumns.MIME_TYPE, getMimeType(adjustedFileName))
            put(MediaStore.Files.FileColumns.RELATIVE_PATH, relativePath)
          }
        }
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
      // Image types
      "jpg", "jpeg" -> "image/jpeg"
      "png" -> "image/png"
      "gif" -> "image/gif"
      "bmp" -> "image/bmp"
      "webp" -> "image/webp"
      
      // Video types
      "mp4" -> "video/mp4"
      "avi" -> "video/x-msvideo"
      "mkv" -> "video/x-matroska"
      "mov" -> "video/quicktime"
      "wmv" -> "video/x-ms-wmv"
      "flv" -> "video/x-flv"
      "webm" -> "video/webm"
      "m4v" -> "video/mp4"
      "3gp" -> "video/3gpp"
      "mpeg" -> "video/mpeg"
      
      // Audio types
      "mp3" -> "audio/mpeg"
      "wav" -> "audio/wav"
      "m4a" -> "audio/mp4"
      "flac" -> "audio/flac"
      "ogg" -> "audio/ogg"
      "aac" -> "audio/aac"
      "wma" -> "audio/x-ms-wma"
      "opus" -> "audio/opus"
      
      // Document types
      "pdf" -> "application/pdf"
      "txt" -> "text/plain"
      "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      "zip" -> "application/zip"
      
      // Default
      else -> "application/octet-stream"
    }
  }
}