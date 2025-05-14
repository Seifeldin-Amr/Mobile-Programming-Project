import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/project.dart';
import '../models/project_document.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new project (Stage 1)
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

      // Prepare project data
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
            'documents': [],
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

      // Create project in Firestore
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

      // Try to fetch with original query (requires index)
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
        // If index error occurs, fallback to simplified query without sorting
        if (e.toString().contains('failed-precondition') ||
            e.toString().contains('requires an index')) {
          print('Index error detected, using fallback query without sorting');

          final querySnapshot = await _firestore
              .collection('projects')
              .where('adminId', isEqualTo: user.uid)
              .get();

          // Manually sort results by createdAt if possible
          final projects = querySnapshot.docs
              .map((doc) => Project.fromFirestore(doc))
              .toList();

          // Try to sort locally (might not work correctly for server timestamps)
          projects.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return projects;
        } else {
          // Rethrow if it's not an index-related error
          throw e;
        }
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

      // Try to fetch with original query (requires index)
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
        // If index error occurs, fallback to simplified query without sorting
        if (e.toString().contains('failed-precondition') ||
            e.toString().contains('requires an index')) {
          print('Index error detected, using fallback query without sorting');

          final querySnapshot = await _firestore
              .collection('projects')
              .where('clientId', isEqualTo: user.uid)
              .get();

          // Manually sort results by createdAt if possible
          final projects = querySnapshot.docs
              .map((doc) => Project.fromFirestore(doc))
              .toList();

          // Try to sort locally (might not work correctly for server timestamps)
          projects.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return projects;
        } else {
          // Rethrow if it's not an index-related error
          throw e;
        }
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

  // Delete a project
  Future<void> deleteProject(String projectId) async {
    try {
      // Delete project document
      await _firestore.collection('projects').doc(projectId).delete();
      print('Project deleted successfully: $projectId');

      // Note: You might want to also delete related documents
      // This would require fetching all documents with this projectId and deleting them
    } catch (e) {
      print('Error deleting project: $e');
      throw Exception('Failed to delete project: $e');
    }
  }

  // Check and update stages based on document approvals
  Future<void> checkAndAdvanceProjectStages(String projectId) async {
    try {
      // 1. Get the project document
      final projectDoc =
          await _firestore.collection('projects').doc(projectId).get();
      if (!projectDoc.exists) {
        throw Exception('Project not found');
      }

      // 2. Get all approved documents in stage 1
      final querySnapshot = await _firestore
          .collection('project_documents')
          .where('projectId', isEqualTo: projectId)
          .where('stage', isEqualTo: 'stage1Planning')
          .where('approvalStatus', isEqualTo: 'approved')
          .get();

      // 3. Check if we have at least 3 approved documents
      if (querySnapshot.docs.length >= 3) {
        print(
            'Found ${querySnapshot.docs.length} approved documents in stage 1, advancing project stages');

        // 4. Update the project stages
        await _firestore.collection('projects').doc(projectId).update({
          'stages.stage1Planning.status': 'completed',
          'stages.stage1Planning.completedAt': FieldValue.serverTimestamp(),
          'stages.stage2Design.status': 'pending',
          'stages.stage2Design.startedAt': FieldValue.serverTimestamp(),
        });

        print('Project stages updated successfully');
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
