import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/constants/app_constants.dart';
import 'package:mobile_app/screens/client/client_stages.dart';
import '../client/client_documents_screen.dart';

class ClientProjectsScreen extends StatefulWidget {
  const ClientProjectsScreen({super.key});

  @override
  State<ClientProjectsScreen> createState() => _ClientProjectsScreenState();
}

class _ClientProjectsScreenState extends State<ClientProjectsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _projects = [];
        });
        return;
      }

      try {
        final querySnapshot = await _firestore
            .collection('projects')
            .where('clientId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();

        List<Map<String, dynamic>> projects = [];
        for (var doc in querySnapshot.docs) {
          var data = doc.data();
          data['id'] = doc.id;
          projects.add(data);
        }

        setState(() {
          _projects = projects;
          _isLoading = false;
        });
      } catch (e) {
        // If we get an index error, fallback to a simpler query
        if (e.toString().contains('failed-precondition') ||
            e.toString().contains('requires an index')) {
          print('Index error detected, using fallback query without sorting');

          // Fallback query without ordering
          final querySnapshot = await _firestore
              .collection('projects')
              .where('clientId', isEqualTo: user.uid)
              .get();

          List<Map<String, dynamic>> projects = [];
          for (var doc in querySnapshot.docs) {
            var data = doc.data();
            data['id'] = doc.id;
            projects.add(data);
          }

          // Sort manually by createdAt if available
          projects.sort((a, b) {
            if (a['createdAt'] == null || b['createdAt'] == null) return 0;
            final aTimestamp = a['createdAt'] as Timestamp;
            final bTimestamp = b['createdAt'] as Timestamp;
            return bTimestamp.compareTo(aTimestamp); // Descending order
          });

          setState(() {
            _projects = projects;
            _isLoading = false;
          });
        } else {
          // If it's a different error, rethrow it
          throw e;
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading projects: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjects,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? _buildEmptyState()
              : _buildProjectsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Projects Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any projects assigned yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        final projectName = project['name'] ?? 'Unnamed Project';
        final projectStatus = project['status'] ?? 'Unknown';
        final projectType = project['type'] ?? 'General Renovation';

        // Format date if it exists
        String formattedDate = 'No date';
        if (project['createdAt'] != null) {
          final timestamp = project['createdAt'] as Timestamp;
          final dateTime = timestamp.toDate();
          formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClientStagesScreen(
                    projectId: project['id'],
                    projectName: projectName,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project Status Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          projectName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(projectStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getStatusColor(projectStatus),
                          ),
                        ),
                        child: Text(
                          projectStatus,
                          style: TextStyle(
                            color: _getStatusColor(projectStatus),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Project Details
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Type: $projectType',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Created: $formattedDate',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'on hold':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
