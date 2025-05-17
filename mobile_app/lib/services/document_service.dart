import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import '../models/project_document.dart';
import '../models/document_approval.dart';
import '../services/approval_service.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApprovalService _approvalService = ApprovalService();

  // Maximum file size for Firestore storage (1MB limit per document, using 900KB to be safe)
  static const int _maxFileSizeBytes = 900 * 1024; // 900KB

  Future<void> uploadDocument({
    required File file,
    required String fileName,
    required DocumentType type,
    required ProjectStage stage,
    required String projectId,
    String description = '',
  }) async {
    try {
      // Check file size first
      final fileSize = await file.length();
      if (fileSize > _maxFileSizeBytes) {
        throw Exception(
            'File size exceeds maximum allowed (${_maxFileSizeBytes / 1024}KB)');
      }

      final bytes = await file.readAsBytes();

      final base64String = base64Encode(bytes);

      final timestamp = DateTime.now();

      final docId = _firestore.collection('project_documents').doc().id;

      final docMetadata = {
        'id': docId,
        'name': fileName,
        'fileContent': base64String,
        'fileType': _getFileType(fileName),
        'fileSize': fileSize,
        'description': description,
        'uploadedAt': Timestamp.fromDate(timestamp),
        'uploadDate': Timestamp.fromDate(timestamp),
        'type': type.name,
        'projectId': projectId,
        'stage': stage.name,
        'approvalStatus': 'pending',
        'uploadedBy': 'userId',
      };

      await _firestore
          .collection('project_documents')
          .doc(docId)
          .set(docMetadata);

      final projectRef = _firestore.collection('projects').doc(projectId);
      final stageKey = 'stages.${stage.name}';

      await projectRef.update({
        '$stageKey.lastUpdated': FieldValue.serverTimestamp(),
        '$stageKey.documentCount': FieldValue.increment(1),
      });

      print('✅ Document successfully stored in Firestore');
    } catch (e) {
      print('❌ Error uploading document: $e');
      rethrow; // Rethrow to handle in the UI
    }
  }

  // Get all documents for a specific project and stage with their approval status
  Future<Map<String, dynamic>> getProjectDocumentsWithApproval(
      String projectId, ProjectStage stage) async {
    try {
      final querySnapshot = await _firestore
          .collection('project_documents')
          .where('projectId', isEqualTo: projectId)
          .where('stage', isEqualTo: stage.name)
          .orderBy('uploadDate', descending: true)
          .get();

      List<Map<String, dynamic>> documents = [];
      Map<String, ApprovalStatus?> approvalStatus = {};

      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        data['id'] = doc.id;

        ApprovalStatus? status =
            await _approvalService.getDocumentApprovalStatus(doc.id);
        approvalStatus[doc.id] = status;

        DocumentType type = DocumentType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => DocumentType.meetingSummary,
        );

        documents.add({
          ...data,
          'documentType': type,
        });
      }

      return {
        'documents': documents,
        'approvalStatus': approvalStatus,
      };
    } catch (e) {
      print('❌ Error loading documents with approval status: $e');
      throw Exception('Failed to load documents: $e');
    }
  }

  // Get all documents for a specific project and stage (directly from project_documents collection)
  Future<List<ProjectDocument>> getDocumentsByProjectAndStage(
      String projectId, ProjectStage stage) async {
    try {
      final querySnapshot = await _firestore
          .collection('project_documents')
          .where('projectId', isEqualTo: projectId)
          .where('stage', isEqualTo: stage.name)
          .orderBy('uploadDate', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProjectDocument.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Failed to retrieve documents: $e');
      return [];
    }
  }

  // Get a single document with its full content
  Future<Map<String, dynamic>?> getDocumentWithContent(
      String documentId) async {
    try {
      final docSnapshot = await _firestore
          .collection('project_documents')
          .doc(documentId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Document not found');
      }

      return docSnapshot.data();
    } catch (e) {
      print('❌ Error retrieving document: $e');
      return null;
    }
  }

  // Delete a document
  Future<void> deleteDocument(ProjectDocument document) async {
    try {
      final documentId = document.id;

      final docSnapshot = await _firestore
          .collection('project_documents')
          .doc(documentId)
          .get();

      if (!docSnapshot.exists) {
        print('Warning: Document metadata not found in Firestore');
        return;
      }

      final data = docSnapshot.data()!;
      final stageName = data['stage'] as String;

      await _firestore.collection('project_documents').doc(documentId).delete();

      print('✅ Document deleted from Firestore');

      // Update the document count in the project stage
      final projectRef =
          _firestore.collection('projects').doc(document.projectId);

      await projectRef.update({
        'stages.$stageName.documentCount': FieldValue.increment(-1),
        'stages.$stageName.lastUpdated': FieldValue.serverTimestamp(),
      });

      print('✅ Document count updated in project stage');
    } catch (e) {
      print('❌ Error deleting document: $e');
      throw Exception('Failed to delete document: $e');
    }
  }

  // Update a document (e.g., to change approval status)
  Future<void> updateDocument(ProjectDocument document) async {
    try {
      final documentId = document.id;

      await _firestore.collection('project_documents').doc(documentId).update({
        'approvalStatus': document.approvalStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('✅ Document approval status updated in Firestore');

      // Update the lastUpdated timestamp in the project stage
      final projectRef =
          _firestore.collection('projects').doc(document.projectId);
      final stageName = document.stage ?? 'stage1Planning';

      await projectRef.update({
        'stages.$stageName.lastUpdated': FieldValue.serverTimestamp(),
      });

      print('✅ Project stage timestamp updated');
    } catch (e) {
      print('❌ Error updating document: $e');
      throw Exception('Failed to update document: $e');
    }
  }

  String _getFileType(String fileName) {
    final extension =
        path.extension(fileName).toLowerCase().replaceAll('.', '');

    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream'; // Default binary stream
    }
  }
}
