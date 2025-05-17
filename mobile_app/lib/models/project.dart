import 'package:cloud_firestore/cloud_firestore.dart';
import 'project_document.dart';

class Project {
  final String id;
  final String name;
  final String type;
  final String description;
  final String status;
  final String? clientId;
  final String? clientName;
  final String adminId;
  final DateTime createdAt;
  final Map<String, dynamic> stages;

  Project({
    required this.id,
    required this.name,
    required this.type,
    this.description = '',
    required this.status,
    this.clientId,
    this.clientName,
    required this.adminId,
    required this.createdAt,
    required this.stages,
  });

  // Create from Firestore document
  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Project',
      type: data['type'] ?? 'General Project',
      description: data['description'] ?? '',
      status: data['status'] ?? 'active',
      clientId: data['clientId'],
      clientName: data['clientName'],
      adminId: data['adminId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stages: data['stages'] ??
          {
            'stage1Planning': {'status': 'pending'},
            'stage2Design': {'status': 'notStarted'},
            'stage3Execution': {'status': 'notStarted'},
            'stage4Completion': {'status': 'notStarted'},
          },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'status': status,
      'clientId': clientId,
      'clientName': clientName,
      'adminId': adminId,
      'createdAt': Timestamp.fromDate(createdAt),
      'stages': stages,
    };
  }

  String getStageStatus(ProjectStage stage) {
    final stageKey = stage.toString().split('.').last;
    if (stages.containsKey(stageKey) && stages[stageKey] is Map) {
      return (stages[stageKey] as Map)['status'] ?? 'pending';
    }
    return 'notStarted';
  }

  bool isStageUnlocked(ProjectStage stage) {
    if (stage == ProjectStage.stage1Planning) return true;

    if (stage == ProjectStage.stage2Design) {
      return getStageStatus(ProjectStage.stage1Planning) == 'completed';
    } else if (stage == ProjectStage.stage3Execution) {
      return getStageStatus(ProjectStage.stage2Design) == 'completed';
    } else if (stage == ProjectStage.stage4Completion) {
      return getStageStatus(ProjectStage.stage3Execution) == 'completed';
    }

    return false;
  }

  int getStageDocumentCount(ProjectStage stage) {
    final stageKey = stage.toString().split('.').last;
    if (stages.containsKey(stageKey) && stages[stageKey] is Map) {
      return (stages[stageKey] as Map)['documentCount'] ?? 0;
    }
    return 0;
  }
}
