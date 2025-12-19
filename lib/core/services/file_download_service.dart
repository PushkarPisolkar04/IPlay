import 'dart:io';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Service for handling file downloads with user-selected locations
class FileDownloadService {
  /// Save file with user-selected location
  /// Returns the file path if successful, null if cancelled
  Future<String?> saveFile({
    required Uint8List bytes,
    required String suggestedName,
    required String mimeType,
    String? dialogTitle,
  }) async {
    try {
      if (Platform.isAndroid) {
        // On Android 10+, save directly to Downloads using file_saver
        // This works without special permissions using MediaStore
        final ext = _getExtension(suggestedName);
        final nameWithoutExt = suggestedName.replaceAll('.$ext', '');
        
        final filePath = await FileSaver.instance.saveAs(
          name: nameWithoutExt,
          bytes: bytes,
          ext: ext,
          mimeType: _getMimeTypeEnum(suggestedName),
        );
        
        if (kDebugMode) {
          print('File saved to: $filePath');
        }
        
        return filePath;
      } else {
        // On iOS/Desktop, let user pick location
        final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: dialogTitle ?? 'Choose where to save',
        );

        if (selectedDirectory == null) {
          // User cancelled
          return null;
        }

        // Create the file in the selected directory
        final filePath = '$selectedDirectory/$suggestedName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        return filePath;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving file: $e');
      }
      rethrow;
    }
  }

  /// Save file and optionally share it
  Future<String?> saveAndShare({
    required Uint8List bytes,
    required String suggestedName,
    required String mimeType,
    String? shareText,
    bool autoShare = false,
  }) async {
    try {
      // Android: Use temp directory for sharing
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$suggestedName');
      await tempFile.writeAsBytes(bytes);

      if (autoShare) {
        // Share immediately
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          text: shareText,
        );
      }

      // Then let user choose permanent location
      return await saveFile(
        bytes: bytes,
        suggestedName: suggestedName,
        mimeType: mimeType,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in saveAndShare: $e');
      }
      rethrow;
    }
  }

  /// Share file without saving
  Future<void> shareFile({
    required Uint8List bytes,
    required String fileName,
    String? shareText,
  }) async {
    try {
      // Android: Use temp directory for sharing
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: shareText,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing file: $e');
      }
      rethrow;
    }
  }

  /// Get file extension from filename
  String _getExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  /// Get MIME type from extension
  String getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'csv':
        return 'text/csv';
      case 'xlsx':
      case 'xls':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'doc':
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get MimeType enum from filename extension
  MimeType _getMimeTypeEnum(String filename) {
    final ext = _getExtension(filename).toLowerCase();
    switch (ext) {
      case 'pdf':
        return MimeType.pdf;
      case 'csv':
        return MimeType.csv;
      case 'xlsx':
      case 'xls':
        return MimeType.microsoftExcel;
      case 'doc':
      case 'docx':
        return MimeType.microsoftWord;
      case 'png':
        return MimeType.png;
      case 'jpg':
      case 'jpeg':
        return MimeType.jpeg;
      default:
        return MimeType.other;
    }
  }
}
