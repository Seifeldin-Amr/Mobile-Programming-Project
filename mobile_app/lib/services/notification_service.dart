import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/document_approval.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a notification in Firestore
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? documentId,
    String? projectId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'documentId': documentId,
        'projectId': projectId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Send document upload notification to the client
  Future<void> sendDocumentUploadNotification({
    required String clientId,
    required String documentTitle,
    required String documentId,
    required String projectId,
  }) async {
    try {
      await createNotification(
        userId: clientId,
        title: 'New Document Available',
        message: 'A new document "$documentTitle" is ready for your review',
        type: 'document_upload',
        documentId: documentId,
        projectId: projectId,
      );
    } catch (e) {
      throw Exception('Failed to send document upload notification: $e');
    }
  }

  // Send document approval notification to the admin
  Future<void> sendDocumentApprovalNotification({
    required String adminId,
    required String documentTitle,
    required String documentId,
    required String projectId,
    required ApprovalStatus status,
  }) async {
    try {
      final statusText =
          status == ApprovalStatus.approved ? 'approved' : 'rejected';

      await createNotification(
        userId: adminId,
        title: 'Document $statusText',
        message:
            'The document "$documentTitle" has been $statusText by the client',
        type: 'document_approval',
        documentId: documentId,
        projectId: projectId,
      );
    } catch (e) {
      throw Exception('Failed to send document approval notification: $e');
    }
  }

  // Get unread notifications count for current user
  Future<int> getUnreadNotificationsCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 0;
      }

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread notifications count: $e');
    }
  }

  // Get notifications for current user
  Future<List<Map<String, dynamic>>> getUserNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get user notifications: $e');
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }
}
