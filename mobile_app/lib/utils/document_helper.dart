import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;


class DocumentHelper {
  
  // Download and optionally open a document
  static Future<Map<String, dynamic>> downloadDocument({
    required String? documentId,
    required String? base64Content,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      // If base64Content is not available, fetch it from Firestore
      String contentToUse = base64Content ?? '';

      if (contentToUse != '') {
        // Decode the base64 content
        final Uint8List fileBytes = base64Decode(contentToUse);

        // Save to temporary directory (works on all platforms without permissions)
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(fileBytes);

        if (!await file.exists()) {
          throw Exception('Failed to save document to storage');
        }

        print('File saved to: ${file.path}');

        return {
          'success': true,
          'filePath': file.path,
          'message': 'File downloaded successfully'
        };
      } else {
        return {
          'success': false,
          'message': 'File content is missing or empty',
        };
      }
    } catch (e) {
      print('Error in downloadDocument: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Get icon for document based on file type
  static IconData getDocumentIcon(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Icons.image;
      case '.txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Format file size for display
  static String formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
