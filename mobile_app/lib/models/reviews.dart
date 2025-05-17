import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewData {
  final String clientId;
  final String clientName;
  final String createdAt;
  final String description;
  final String projectId;
  final String projectName;
  final int ratingStars;
  final String? clientImageUrl;
  final List<String>? imagesUrl;

  ReviewData({
    required this.clientId,
    required this.clientName,
    required this.createdAt,
    required this.description,
    required this.projectId,
    required this.projectName,
    required this.ratingStars,
    this.clientImageUrl,
    this.imagesUrl,
  });

  factory ReviewData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewData(
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate().toString() ??
          DateTime.now().toString(),
      description: data['description'] ?? '',
      projectId: data['projectId'] ?? '',
      projectName: data['projectName'] ?? '',
      imagesUrl: List<String>.from(data['imagesUrl'] ?? []),
      clientImageUrl: data['clientImageUrl'] ?? '',
      ratingStars: data['ratingStars'] ?? 0,
    );
  }
}
