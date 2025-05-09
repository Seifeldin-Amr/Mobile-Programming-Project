import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_file_plus/open_file_plus.dart';
import '../services/document_service.dart';

class DocumentHelper {
  static final DocumentService _documentService = DocumentService();

  // Extract document ID from Firestore URL format
  static String? getDocumentIdFromUrl(String url) {
    if (url.startsWith('firestore://')) {
      final parts = url.split('/');
      if (parts.length >= 3) {
        return parts.last;
      }
    }
    return null;
  }

  // Retrieve document content from Firestore
  static Future<Uint8List?> getDocumentBytes(String url) async {
    try {
      final documentId = getDocumentIdFromUrl(url);
      if (documentId == null) {
        throw Exception('Invalid document URL format');
      }

      // Get document with content from Firestore
      final docData = await _documentService.getDocumentWithContent(documentId);
      if (docData == null) {
        throw Exception('Document not found');
      }

      // Extract and decode Base64 content
      final base64Content = docData['fileContent'] as String?;
      if (base64Content == null || base64Content.isEmpty) {
        throw Exception('Document content is empty');
      }

      return base64Decode(base64Content);
    } catch (e) {
      print('❌ Error getting document bytes: $e');
      return null;
    }
  }

  // Save document to temporary file and return file path
  static Future<String?> saveDocumentToTemp(String url, String fileName) async {
    try {
      final bytes = await getDocumentBytes(url);
      if (bytes == null) {
        return null;
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(tempDir.path, fileName);

      // Write bytes to file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      print('❌ Error saving document to temp: $e');
      return null;
    }
  }

  // Download and optionally open a document
  static Future<Map<String, dynamic>> downloadDocument({
    required String? documentId,
    required String? base64Content,
    required String fileName,
    required BuildContext context,
    bool openAfterDownload = true,
  }) async {
    try {
      // If base64Content is not available, fetch it from Firestore
      String? contentToUse = base64Content;
      if (contentToUse == null || contentToUse.isEmpty) {
        if (documentId == null) {
          throw Exception('Document ID is missing');
        }

        // Fetch document with content from service
        final fullDoc =
            await _documentService.getDocumentWithContent(documentId);
        if (fullDoc == null) {
          throw Exception('Document not found');
        }
        contentToUse = fullDoc['fileContent'] as String?;

        if (contentToUse == null || contentToUse.isEmpty) {
          throw Exception('File content is missing or empty');
        }
      }

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

      // Try to open the file if requested
      OpenResult? openResult;
      if (openAfterDownload) {
        try {
          openResult = await OpenFile.open(file.path);
          print('OpenFile result: ${openResult.type} - ${openResult.message}');
        } catch (e) {
          print('Error opening file: $e');
          // We'll still return success since the file was downloaded
        }
      }

      return {
        'success': true,
        'filePath': file.path,
        'openResult': openResult,
        'message': 'File downloaded successfully'
      };
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
