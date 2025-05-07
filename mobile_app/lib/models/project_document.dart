import 'package:cloud_firestore/cloud_firestore.dart';

enum DocumentType {
  meetingSummary,
  conceptDesign,
  designBrief,
  other
}

extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.meetingSummary:
        return 'Meeting Summary';
      case DocumentType.conceptDesign:
        return 'Concept Design';
      case DocumentType.designBrief:
        return 'Design Brief';
      case DocumentType.other:
        return 'Other';
    }
  }
}

class ProjectDocument {
  final String id;
  final String name;
  final String url;
  final DocumentType type;
  final String projectId;
  final DateTime uploadDate;
  final String uploadedBy;
  final String description;

  ProjectDocument({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.projectId,
    required this.uploadDate,
    required this.uploadedBy,
    this.description = '',
  });

  // Create from Firestore map
  factory ProjectDocument.fromMap( Map<String, dynamic> data) {
    return ProjectDocument(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Unnamed document',
      url: data['url'] ?? '',
      type: _getDocumentTypeFromString(data['type'] ?? 'other'),
      projectId: data['projectId'] ?? '',
      uploadDate: (data['uploadDate'] is Timestamp)
          ? (data['uploadDate'] as Timestamp).toDate()
          : DateTime.now(),
      uploadedBy: data['uploadedBy'] ?? '',
      description: data['description'] ?? '',
    );
  }
  

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'type': type.toString().split('.').last,
      'projectId': projectId,
      'uploadDate': uploadDate,
      'uploadedBy': uploadedBy,
      'description': description,
    };
  }

  // Helper method to convert string to DocumentType enum
  static DocumentType _getDocumentTypeFromString(String typeString) {
    switch (typeString) {
      case 'meetingSummary':
        return DocumentType.meetingSummary;
      case 'conceptDesign':
        return DocumentType.conceptDesign;
      case 'designBrief':
        return DocumentType.designBrief;
      default:
        return DocumentType.other;
    }
  }
}
