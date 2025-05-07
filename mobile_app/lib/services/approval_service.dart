import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project_document.dart';
import '../models/document_approval.dart';
import 'notification_service.dart';

class ApprovalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Process document approval (approve or reject)
  Future<void> processDocumentApproval({
    required String documentId,
    required String projectId,
    required ApprovalStatus status,
    String? comments,
  }) async {
    try {
      // Validate inputs
      if (status == ApprovalStatus.rejected &&
          (comments == null || comments.isEmpty)) {
        throw Exception('Comments are required when rejecting a document');
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get document details for notification
      final docSnapshot = await _firestore
          .collection('project_documents')
          .doc(documentId)
          .get();
      if (!docSnapshot.exists) {
        throw Exception('Document not found');
      }

      final docData = docSnapshot.data()!;
      final documentName = docData['name'] ?? 'Unknown document';

      // Create approval record
      final approval = DocumentApproval(
        id: '', // Will be set by Firestore
        documentId: documentId,
        projectId: projectId,
        userId: user.uid,
        status: status,
        timestamp: DateTime.now(),
        comments: comments,
      );

      // Add to Firestore
      await _firestore.collection('document_approvals').add(approval.toMap());

      // Update document status based on approval status
      final Map<String, dynamic> updateData = {
        'approvalStatus': status.toString().split('.').last,
        'lastUpdatedBy': user.uid,
        'lastUpdatedDate': FieldValue.serverTimestamp(),
      };

      // Add specific fields based on status
      if (status == ApprovalStatus.approved) {
        updateData['approvedBy'] = user.uid;
        updateData['approvalDate'] = FieldValue.serverTimestamp();
      } else if (status == ApprovalStatus.rejected) {
        updateData['rejectedBy'] = user.uid;
        updateData['rejectionDate'] = FieldValue.serverTimestamp();
        updateData['rejectionComments'] = comments;
      }

      // Update document in Firestore
      await _firestore
          .collection('project_documents')
          .doc(documentId)
          .update(updateData);

      // Get admin ID (for notification)
      final adminId = docData['uploadedBy'];

      // Send notification to admin
      await _notificationService.sendDocumentApprovalNotification(
        adminId: adminId,
        documentTitle: documentName,
        documentId: documentId,
        projectId: projectId,
        status: status,
      );
    } catch (e) {
      throw Exception('Failed to process document approval: $e');
    }
  }

  // Get approval status for a document
  Future<ApprovalStatus?> getDocumentApprovalStatus(String documentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final querySnapshot = await _firestore
          .collection('document_approvals')
          .where('documentId', isEqualTo: documentId)
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final approvalData = querySnapshot.docs.first.data();
      return ApprovalStatus.values.firstWhere(
        (e) => e.toString().split('.').last == approvalData['status'],
        orElse: () => ApprovalStatus.pending,
      );
    } catch (e) {
      throw Exception('Failed to get document approval status: $e');
    }
  }
}
