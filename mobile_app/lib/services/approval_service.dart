import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/document_approval.dart';
import 'notification_service.dart';
import 'project_service.dart';

class ApprovalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final ProjectService _projectService = ProjectService();

  // Process document approval (approve or reject)
  Future<void> processDocumentApproval({
    required String documentId,
    required String projectId,
    required ApprovalStatus status,
    required String? comments,
  }) async {
    try {
      final commentsStr =
          comments ?? ''; // Convert possible null to empty string

      // Validate inputs - only check if empty when rejected
      if (status == ApprovalStatus.rejected && commentsStr.isEmpty) {
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
        comments: commentsStr,
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
        updateData['approvalComments'] = commentsStr;
      } else if (status == ApprovalStatus.rejected) {
        updateData['rejectedBy'] = user.uid;
        updateData['rejectionDate'] = FieldValue.serverTimestamp();
        updateData['rejectionComments'] = commentsStr;
      }

      // Update document in Firestore
      await _firestore
          .collection('project_documents')
          .doc(documentId)
          .update(updateData);

      // Get admin ID (for notification) - Fix null issue by defaulting to a system ID if not found
      final adminId = docData['uploadedBy'] as String? ?? 'system';

      // Only send notification if we have a valid admin ID
      if (adminId != 'system') {
        // Send notification to admin
        await _notificationService.sendDocumentApprovalNotification(
          adminId: adminId,
          documentTitle: documentName,
          documentId: documentId,
          projectId: projectId,
          status: status,
        );
      } else {
        print('⚠️ No admin ID found for document, notification not sent');
      }

      // If the document was approved, check if we can advance project stages
      if (status == ApprovalStatus.approved) {
        await _projectService.checkAndAdvanceProjectStages(projectId);
      }
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

      // First try to get the status directly from the document
      final docSnapshot = await _firestore
          .collection('project_documents')
          .doc(documentId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        if (data.containsKey('approvalStatus')) {
          final statusString = data['approvalStatus'] as String?;
          if (statusString != null && statusString != 'pending') {
            // If document already has a non-pending status, use that
            return ApprovalStatus.values.firstWhere(
              (e) => e.toString().split('.').last == statusString,
              orElse: () => ApprovalStatus.pending,
            );
          }
        }
      }

      // Otherwise check for approvals in the approvals collection
      final querySnapshot = await _firestore
          .collection('document_approvals')
          .where('documentId', isEqualTo: documentId)
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return ApprovalStatus.pending;
      }

      final approvalData = querySnapshot.docs.first.data();
      final statusString = approvalData['status'] as String?;

      if (statusString == null) {
        return ApprovalStatus.pending;
      }

      return ApprovalStatus.values.firstWhere(
        (e) => e.toString().split('.').last == statusString,
        orElse: () => ApprovalStatus.pending,
      );
    } catch (e) {
      print('Failed to get document approval status: $e');
      // Don't throw an exception, just return pending status
      return ApprovalStatus.pending;
    }
  }
}
