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

  // Upload a document to Firestore as a Base64 encoded string
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
            'File size exceeds the maximum limit of 900KB. Please use a smaller file.');
      }

      // Step 1: Read the file as bytes and encode to Base64
      final fileBytes = await file.readAsBytes();
      final fileBase64 = base64Encode(fileBytes);

      print(
          '⏳ Encoding document of size: ${(fileSize / 1024).toStringAsFixed(2)}KB');

      // Step 2: Create a unique document ID
      final docId = _firestore.collection('project_documents').doc().id;
      final timestamp = DateTime.now();

      // Step 3: Build metadata with encoded file content
      final docMetadata = {
        'id': docId,
        'name': fileName,
        'fileType': _getFileType(fileName),
        'fileContent': fileBase64, // Store the file content as Base64 string
        'fileSize': fileSize,
        'description': description,
        'uploadedAt': Timestamp.fromDate(timestamp),
        'uploadDate': Timestamp.fromDate(timestamp),
        'type': type.name,
        'projectId': projectId,
        'stage': stage.name,
        'approvalStatus':
            'pending', // Mark document as pending approval by client
        'uploadedBy': 'userId', // Replace with actual user ID if needed
      };

      // Step 4: Store in Firestore - both as a separate document and in the project
      // First, save as a standalone document
      await _firestore
          .collection('project_documents')
          .doc(docId)
          .set(docMetadata);

      // Step 5: Add reference to the project document (without the Base64 content to save space)
      final projectRef = _firestore.collection('projects').doc(projectId);

      // Check if project exists first
      final projectDoc = await projectRef.get();
      if (!projectDoc.exists) {
        throw Exception('Project not found');
      }

      // Create a smaller version of metadata without the file content
      final documentReference = {
        'id': docId,
        'name': fileName,
        'fileType': _getFileType(fileName),
        'fileSize': fileSize,
        'description': description,
        'uploadedAt': Timestamp.fromDate(timestamp),
        'uploadDate': Timestamp.fromDate(timestamp),
        'type': type.name,
      };

      // Use the stage field to update the correct part of the document
      final stageKey = 'stages.${stage.name}';

      // Update the project document
      await projectRef.update({
        '$stageKey.documents': FieldValue.arrayUnion([documentReference]),
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

        // Check approval status
        ApprovalStatus? status =
            await _approvalService.getDocumentApprovalStatus(doc.id);
        approvalStatus[doc.id] = status;

        // Group by document type
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
      // Create a direct query on the project_documents collection
      // This approach requires the composite index mentioned in the error message
      final querySnapshot = await _firestore
          .collection('project_documents')
          .where('projectId', isEqualTo: projectId)
          .where('stage', isEqualTo: stage.name)
          .orderBy('uploadDate', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      // Convert query results to ProjectDocument objects
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

      // Get the document to confirm it exists and get stage info
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

      // Delete the document from Firestore
      await _firestore.collection('project_documents').doc(documentId).delete();

      print('✅ Document deleted from Firestore');

      // Update the project document to remove the reference
      final projectRef =
          _firestore.collection('projects').doc(document.projectId);
      final projectDoc = await projectRef.get();

      if (projectDoc.exists) {
        final projectData = projectDoc.data()!;
        final stagesData = projectData['stages'] as Map<String, dynamic>?;

        if (stagesData != null && stagesData.containsKey(stageName)) {
          final stageData = stagesData[stageName] as Map<String, dynamic>;

          if (stageData.containsKey('documents')) {
            List<dynamic> documents = List.from(stageData['documents'] ?? []);

            // Remove the document from the array
            documents.removeWhere((doc) => doc['id'] == documentId);

            // Update the project with the modified documents array
            await projectRef.update({
              'stages.$stageName.documents': documents,
              'stages.$stageName.lastUpdated': FieldValue.serverTimestamp(),
              'stages.$stageName.documentCount': FieldValue.increment(-1),
            });

            print(
                '✅ Document reference removed from project stage documents array');
          } else {
            // If no documents array exists, just update the count
            await projectRef.update({
              'stages.$stageName.documentCount': FieldValue.increment(-1),
              'stages.$stageName.lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      print('❌ Error deleting document: $e');
      throw Exception('Failed to delete document: $e');
    }
  }

  // Update a document (e.g., to change approval status)
  Future<void> updateDocument(ProjectDocument document) async {
    try {
      final documentId = document.id;

      // 1. Update in the project_documents collection
      await _firestore.collection('project_documents').doc(documentId).update({
        'approvalStatus': document.approvalStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('✅ Document approval status updated in Firestore');

      // 2. Update the reference in the project's stage documents
      final projectRef =
          _firestore.collection('projects').doc(document.projectId);
      final projectDoc = await projectRef.get();

      if (projectDoc.exists) {
        final projectData = projectDoc.data()!;
        final stagesData = projectData['stages'] as Map<String, dynamic>?;
        // Using the string value directly, not trying to access .name on a String
        final stageName = document.stage ?? 'stage1Planning';

        if (stagesData != null && stagesData.containsKey(stageName)) {
          final stageData = stagesData[stageName] as Map<String, dynamic>;

          if (stageData.containsKey('documents')) {
            List<dynamic> documents = List.from(stageData['documents'] ?? []);

            // Find and update the document in the array
            for (int i = 0; i < documents.length; i++) {
              if (documents[i]['id'] == documentId) {
                // Update the document approval status
                documents[i]['approvalStatus'] = document.approvalStatus;
                break;
              }
            }

            // Update the project with the modified documents array
            await projectRef.update({
              'stages.$stageName.documents': documents,
              'stages.$stageName.lastUpdated': FieldValue.serverTimestamp(),
            });

            print(
                '✅ Document reference updated in project stage documents array');
          }
        }
      }
    } catch (e) {
      print('❌ Error updating document: $e');
      throw Exception('Failed to update document: $e');
    }
  }

  // Helper method to determine file type from file name
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
