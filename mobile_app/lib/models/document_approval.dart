import 'package:cloud_firestore/cloud_firestore.dart';


enum ApprovalStatus {
  pending,
  approved,
  rejected,
}

class DocumentApproval {
  final String id;
  final String documentId;
  final String projectId;
  final String userId;
  final ApprovalStatus status;
  final DateTime timestamp;
  final String? comments;

  DocumentApproval({
    required this.id,
    required this.documentId,
    required this.projectId,
    required this.userId,
    required this.status,
    required this.timestamp,
    this.comments,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'projectId': projectId,
      'userId': userId,
      'status': status.toString().split('.').last,
      'timestamp': timestamp,
      'comments': comments,
    };
  }

  factory DocumentApproval.fromMap(String id, Map<String, dynamic> map) {
    return DocumentApproval(
      id: id,
      documentId: map['documentId'] ?? '',
      projectId: map['projectId'] ?? '',
      userId: map['userId'] ?? '',
      status: ApprovalStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => ApprovalStatus.pending,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      comments: map['comments'],
    );
  }
}
