import 'package:flutter/material.dart';
import 'package:mobile_app/screens/client/client_documents_screen.dart';
import 'package:mobile_app/screens/checkout.dart';

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
        'isActive': true,
        'paymentStatus': 'paid'  // First stage is already paid
      },
      {
        'name': 'Design Development',
        'status': 'Not Started yet',
        'progress': 0.0,
        'isActive': false,
        'paymentStatus': 'pending'
      },
      {
        'name': 'Execution',
        'status': 'Not Started yet',
        'progress': 0.0,
        'isActive': false,
        'paymentStatus': 'pending'
      },
      {
        'name': 'Completion',
        'status': 'Not Started yet',
        'progress': 0.0,
        'isActive': false,
        'paymentStatus': 'pending'
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
                        stage['name'] ?? 'Unknown Stage',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stage['status'] ?? 'Unknown Status',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            value: stage['progress'] as double,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressColor(stage['progress'] as double),
                            ),
                          ),
                        ),
                        Text(
                          '${((stage['progress'] as double) * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    if (stage['paymentStatus'] != 'paid' && stage['name'] != 'Planning & Design')
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckoutScreen(
                                projectId:widget.projectId,
                                projectName:widget.projectName,
                                stageName: stage['name'],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(60, 30),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Pay'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.33) {
      return Colors.red;
    } else if (progress < 0.66) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }
}
