import 'package:flutter/material.dart';
import 'package:mobile_app/screens/client/client_documents_screen.dart';

class ClientStagesScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ClientStagesScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ClientStagesScreen> createState() => _ClientStagesScreenState();
}

class _ClientStagesScreenState extends State<ClientStagesScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Project: ${widget.projectName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProjectStages(),
              ],
            ),
    );
  }

  Widget _buildProjectStages() {
    // Define the project stages
    final stages = [
      {
        'name': 'Planning & Design',
        'status': 'In Progress',
        'progress': 1 / 3,
        'isActive': true
      },
      {
        'name': 'Design Development',
        'status': 'Not Started yet',
        'progress': 0.0,
        'isActive': false
      },
      {
        'name': 'Execution',
        'status': 'Not Started yet',
        'progress': 0.0,
        'isActive': false
      },
      {
        'name': 'Completion',
        'status': 'Not Started yet',
        'progress': 0.0,
        'isActive': false
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Stages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...stages.map((stage) => _buildStageCard(stage)).toList(),
        ],
      ),
    );
  }

  Widget _buildStageCard(Map<String, dynamic> stage) {
    final isActive = stage['isActive'] as bool;
    final progress = stage['progress'] as double;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (isActive) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClientDocumentsScreen(
                  projectId: widget.projectId,
                  projectName: widget.projectName,
                ),
              ),
            );
          } else {
            null;
          }
        },
        child: Card(
          elevation: isActive ? 2 : 0,
          color: isActive ? Colors.white : Colors.grey[200],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage['name'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.black : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${stage['status']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}% completed',
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 40,
                  width: 40,
                  child: CircularProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    strokeWidth: 7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
