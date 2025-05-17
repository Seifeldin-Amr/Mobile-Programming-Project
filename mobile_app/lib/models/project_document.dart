import 'package:cloud_firestore/cloud_firestore.dart';

enum DocumentType {
  meetingSummary,
  conceptDesign,
  designBrief,
  mepDrawings,
  constructionDocuments,
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
      case DocumentType.mepDrawings:
        return 'MEP Drawings';
      case DocumentType.constructionDocuments:
        return 'Construction Documents';
      case DocumentType.other:
        return 'Other';
    }
  }
}

enum ProjectStage {
  stage1Planning,
  stage2Design,
  stage3Execution,
  stage4Completion
}

extension ProjectStageExtension on ProjectStage {
  String get displayName {
    switch (this) {
      case ProjectStage.stage1Planning:
        return 'Stage 1: Planning';
      case ProjectStage.stage2Design:
        return 'Stage 2: Design';
      case ProjectStage.stage3Execution:
        return 'Stage 3: Execution';
      case ProjectStage.stage4Completion:
        return 'Stage 4: Completion';
    }
  }

  String get name {
    return toString().split('.').last;
  }
}

class ProjectDocument {
  final String id;
  final String name;
  final DocumentType type;
  final String projectId;
  final DateTime uploadDate;
  final String uploadedBy;
  final String description;
  String? approvalStatus;
  final String? stage;
  final String? fileContent;

  ProjectDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.projectId,
    required this.uploadDate,
    required this.uploadedBy,
    this.description = '',
    this.approvalStatus,
    this.stage,
    this.fileContent,
  });

  factory ProjectDocument.fromMap(Map<String, dynamic> data) {
    return ProjectDocument(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Unnamed document',
      type: _getDocumentTypeFromString(data['type'] ?? 'other'),
      projectId: data['projectId'] ?? '',
      uploadDate: (data['uploadDate'] is Timestamp)
          ? (data['uploadDate'] as Timestamp).toDate()
          : DateTime.now(),
      uploadedBy: data['uploadedBy'] ?? '',
      description: data['description'] ?? '',
      approvalStatus: data['approvalStatus'],
      stage: data['stage'],
      fileContent: data['fileContent'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.toString().split('.').last,
      'projectId': projectId,
      'uploadDate': uploadDate,
      'uploadedBy': uploadedBy,
      'description': description,
      'approvalStatus': approvalStatus,
      'stage': stage,
      'fileContent': fileContent,
    };
  }

  ProjectStage get stageEnum {
    if (stage == null) return ProjectStage.stage1Planning;

    switch (stage) {
      case 'stage1Planning':
        return ProjectStage.stage1Planning;
      case 'stage2Design':
        return ProjectStage.stage2Design;
      case 'stage3Execution':
        return ProjectStage.stage3Execution;
      case 'stage4Completion':
        return ProjectStage.stage4Completion;
      default:
        return ProjectStage.stage1Planning;
    }
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
      case 'mepDrawings':
        return DocumentType.mepDrawings;
      case 'constructionDocuments':
        return DocumentType.constructionDocuments;
      default:
        return DocumentType.other;
    }
  }
}
