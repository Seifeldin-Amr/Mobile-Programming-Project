import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project.dart';
import '../models/project_document.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new project
  Future<String> createProject({
    required String name,
    required String type,
    String description = '',
    String? clientId,
    String? clientName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final projectData = {
        'name': name,
        'type': type,
        'description': description,
        'status': 'active',
        'clientId': clientId,
        'clientName': clientName,
        'adminId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'stages': {
          'stage1Planning': {
            'status': 'pending',
            'startedAt': FieldValue.serverTimestamp(),
          },
          'stage2Design': {
            'status': 'notStarted',
          },
          'stage3Execution': {
            'status': 'notStarted',
          },
          'stage4Completion': {
            'status': 'notStarted',
          },
        },
      };

      final docRef = await _firestore.collection('projects').add(projectData);

      print('Project created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating project: $e');
      throw Exception('Failed to create project: $e');
    }
  }

  // Get all projects for admin
  Future<List<Project>> getAdminProjects() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      try {
        final querySnapshot = await _firestore
            .collection('projects')
            .where('adminId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();

        return querySnapshot.docs
            .map((doc) => Project.fromFirestore(doc))
            .toList();
      } catch (e) {
        print('Error: $e');

        return [];
      }
    } catch (e) {
      print('Error fetching admin projects: $e');
      throw Exception('Failed to fetch admin projects: $e');
    }
  }

  // Get all projects for client
  Future<List<Project>> getClientProjects() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      try {
        final querySnapshot = await _firestore
            .collection('projects')
            .where('clientId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();

        return querySnapshot.docs
            .map((doc) => Project.fromFirestore(doc))
            .toList();
      } catch (e) {
        print('Error: $e');

        return [];
      }
    } catch (e) {
      print('Error fetching client projects: $e');
      throw Exception('Failed to fetch client projects: $e');
    }
  }

  // Get a specific project by ID
  Future<Project> getProject(String projectId) async {
    try {
      final docSnapshot =
          await _firestore.collection('projects').doc(projectId).get();

      if (!docSnapshot.exists) {
        throw Exception('Project not found');
      }

      return Project.fromFirestore(docSnapshot);
    } catch (e) {
      print('Error fetching project: $e');
      throw Exception('Failed to fetch project: $e');
    }
  }

  // Get all clients (users that are not admins)
  Future<List<Map<String, dynamic>>> getAllClients() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['displayName'] =
            '${data['firstName'] ?? ''} ${data['lastName'] ?? ''} (${data['email'] ?? 'No email'})';
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching clients: $e');
      throw Exception('Failed to fetch clients: $e');
    }
  }

  // Update project details
  Future<void> updateProject({
    required String projectId,
    String? name,
    String? type,
    String? status,
    String? clientId,
    String? clientName,
    String? description,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (type != null) updateData['type'] = type;
      if (status != null) updateData['status'] = status;
      if (clientId != null) updateData['clientId'] = clientId;
      if (clientName != null) updateData['clientName'] = clientName;
      if (description != null) updateData['description'] = description;

      await _firestore.collection('projects').doc(projectId).update(updateData);
      print('Project updated successfully: $projectId');
    } catch (e) {
      print('Error updating project: $e');
      throw Exception('Failed to update project: $e');
    }
  }

  // Update project stage status
  Future<void> updateProjectStage(
      String projectId, ProjectStage stage, String status) async {
    try {
      final stageKey = stage.toString().split('.').last;

      await _firestore.collection('projects').doc(projectId).update({
        'stages.$stageKey.status': status,
        'stages.$stageKey.updatedAt': FieldValue.serverTimestamp(),
      });

      print('Project stage updated successfully');
    } catch (e) {
      print('Error updating project stage: $e');
      throw Exception('Failed to update project stage: $e');
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      await _firestore.collection('projects').doc(projectId).delete();
      print('Project deleted successfully: $projectId');
    } catch (e) {
      print('Error deleting project: $e');
      throw Exception('Failed to delete project: $e');
    }
  }

  // Check and update stages based on document approvals
  Future<void> checkAndAdvanceProjectStages(String projectId) async {
    try {
      final projectDoc =
          await _firestore.collection('projects').doc(projectId).get();
      if (!projectDoc.exists) {
        throw Exception('Project not found');
      }

      final projectData = projectDoc.data() as Map<String, dynamic>;
      final stages = projectData['stages'] as Map<String, dynamic>;

      final stageOrder = [
        'stage1Planning',
        'stage2Design',
        'stage3Execution',
        'stage4Completion'
      ];

      Map<String, dynamic> updates = {};
      for (int i = 0; i < stageOrder.length - 1; i++) {
        final currentStageKey = stageOrder[i];
        final nextStageKey = stageOrder[i + 1];

        if (stages.containsKey(currentStageKey) &&
            stages[currentStageKey] is Map &&
            (stages[currentStageKey] as Map)['status'] == 'completed') {
          if (stages.containsKey(nextStageKey) &&
              stages[nextStageKey] is Map &&
              (stages[nextStageKey] as Map)['status'] == 'notStarted') {
            updates['stages.$nextStageKey.status'] = 'pending';
            updates['stages.$nextStageKey.startedAt'] =
                FieldValue.serverTimestamp();
            print(
                'Setting $nextStageKey to pending as $currentStageKey is completed');
          }
        }
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('projects').doc(projectId).update(updates);
        print('Project stages updated successfully: $updates');
        return;
      }

      String currentStageKey = '';
      String nextStageKey = '';

      for (int i = 0; i < stageOrder.length; i++) {
        final stageKey = stageOrder[i];
        if (stages.containsKey(stageKey) &&
            stages[stageKey] is Map &&
            (stages[stageKey] as Map)['status'] == 'pending') {
          currentStageKey = stageKey;
          nextStageKey = i < stageOrder.length - 1 ? stageOrder[i + 1] : '';
          break;
        }
      }

      if (currentStageKey.isEmpty) {
        print('No pending stage found to advance');
        return;
      }

      print('Found pending stage: $currentStageKey');

      final querySnapshot = await _firestore
          .collection('project_documents')
          .where('projectId', isEqualTo: projectId)
          .where('stage', isEqualTo: currentStageKey)
          .where('approvalStatus', isEqualTo: 'approved')
          .get();

      if (querySnapshot.docs.length >= 3) {
        print(
            'Found ${querySnapshot.docs.length} approved documents in $currentStageKey or stage is already completed, advancing to next stage');

        // 4. Update the project stages
        final docUpdates = {
          'stages.$currentStageKey.status': 'completed',
          'stages.$currentStageKey.completedAt': FieldValue.serverTimestamp(),
        };

        // Only update the next stage if there is one
        if (nextStageKey.isNotEmpty) {
          docUpdates['stages.$nextStageKey.status'] = 'pending';
          docUpdates['stages.$nextStageKey.startedAt'] =
              FieldValue.serverTimestamp();
        }

        await _firestore
            .collection('projects')
            .doc(projectId)
            .update(docUpdates);

        print('Project stages updated successfully based on documents');
      } else {
        print(
            'Not enough approved documents (${querySnapshot.docs.length}/3) to advance project stages');
      }
    } catch (e) {
      print('Error checking/advancing project stages: $e');
      throw Exception('Failed to advance project stages: $e');
    }
  }
}
