import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updatePaymentStatus({
    required String projectName,
    required String stageName,
  }) async {
    try {
      print('=== Starting Payment Status Update ===');
      print('Project Name: $projectName');
      print('Stage Name: $stageName');
      
      // Map display names to database stage keys
      final stageKeyMap = {
        'Planning & Design': 'stage1Planning',
        'Design Development': 'stage2Design',
        'Execution': 'stage3Execution',
        'Completion': 'stage4Completion',
      };
      
      final stageKey = stageKeyMap[stageName];
      if (stageKey == null) {
        print('Invalid stage name: $stageName');
        throw Exception('Invalid stage name');
      }
      
      // First, let's check if we can access the collection
      print('Checking project collection...');
      final collectionRef = _firestore.collection('projects');
      print('Collection reference obtained');
      
      // Try to get all documents first to verify database access
      print('Fetching all projects to verify database access...');
      final allProjects = await collectionRef.get();
      print('Total projects in database: ${allProjects.docs.length}');
      print('Projects found:');
      for (var doc in allProjects.docs) {
        print('Document ID: ${doc.id}');
        print('Data: ${doc.data()}');
      }
      
      // Now try the specific query
      print('\nQuerying for specific project...');
      final querySnapshot = await collectionRef
          .where('name', isEqualTo: projectName)
          .get();

      print('Query completed');
      print('Documents found: ${querySnapshot.docs.length}');

      if (querySnapshot.docs.isEmpty) {
        print('No project found with name: $projectName');
        throw Exception('Project not found');
      }

      final projectDoc = querySnapshot.docs.first;
      print('\nFound project document:');
      print('Document ID: ${projectDoc.id}');
      print('Project data: ${projectDoc.data()}');
      
      // Get the stages map from the project document
      final data = projectDoc.data();
      
      if (!data.containsKey('stages')) {
        print('No stages found in project document');
        throw Exception('No stages found in project');
      }

      final stages = data['stages'] as Map<String, dynamic>;
      print('\nStages found:');
      print('Stages data: $stages');
      
      // Find the stage in the map and update its payment status
      if (!stages.containsKey(stageKey)) {
        print('Stage not found: $stageKey');
        throw Exception('Stage not found');
      }

      print('\nUpdating payment status...');
      
      // Update the stage's payment status
      stages[stageKey]['pay_status'] = 'paid';
      stages[stageKey]['paid_at'] = FieldValue.serverTimestamp();

      // Update the project document with the modified stages map
      print('Saving changes to database...');
      await projectDoc.reference.update({
        'stages': stages,
      });
      
      print('=== Payment Status Update Completed Successfully ===');
    } catch (e) {
      print('=== Error in Payment Status Update ===');
      print('Error details: $e');
      throw Exception('Failed to update payment status: $e');
    }
  }
} 