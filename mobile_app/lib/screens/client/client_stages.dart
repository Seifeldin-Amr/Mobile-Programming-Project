import 'package:flutter/material.dart';
import 'package:mobile_app/screens/client/client_documents_screen.dart';
import '../../models/project_document.dart';
import '../../models/project.dart';
import '../../services/project_service.dart';
import '../../services/document_service.dart';

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
  bool _isLoading = true;
  final ProjectService _projectService = ProjectService();
  final DocumentService _documentService = DocumentService();
  Project? _project;
  Map<ProjectStage, int> _approvedDocumentCounts = {};
  Map<ProjectStage, int> _totalDocumentCounts = {};

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  Future<void> _loadProjectData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load the project data
      final project = await _projectService.getProject(widget.projectId);

      // Initialize document counts
      Map<ProjectStage, int> approvedCounts = {};
      Map<ProjectStage, int> totalCounts = {};

      // Get document counts for each stage
      for (final stage in ProjectStage.values) {
        // Get the total document count for this stage
        final stageKey = stage.toString().split('.').last;
        final totalCount = project.getStageDocumentCount(stage);
        totalCounts[stage] = totalCount;

        // Get the count of approved documents
        final docs = await _documentService.getDocumentsByProjectAndStage(
            widget.projectId, stage);
        final approvedDocs = docs
            .where((doc) => doc.approvalStatus?.toLowerCase() == 'approved')
            .length;
        approvedCounts[stage] = approvedDocs;
      }

      setState(() {
        _project = project;
        _approvedDocumentCounts = approvedCounts;
        _totalDocumentCounts = totalCounts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading project data: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading project data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Project: ${widget.projectName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjectData,
            tooltip: 'Refresh',
          ),
        ],
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
    if (_project == null) {
      return const Center(child: Text('No project data available'));
    }

    // Define and populate the project stages dynamically from project data
    final List<Map<String, dynamic>> stages = [
      _buildStageData(
        ProjectStage.stage1Planning,
        'Planning & Design',
      ),
      _buildStageData(
        ProjectStage.stage2Design,
        'Design Development',
      ),
      _buildStageData(
        ProjectStage.stage3Execution,
        'Execution',
      ),
      _buildStageData(
        ProjectStage.stage4Completion,
        'Completion',
      ),
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

  Map<String, dynamic> _buildStageData(
      ProjectStage stageEnum, String stageName) {
    // Get status from project data
    final stageStatus = _project!.getStageStatus(stageEnum);

    // Calculate progress based on approved documents
    final approvedCount = _approvedDocumentCounts[stageEnum] ?? 0;
    final totalCount = _totalDocumentCounts[stageEnum] ?? 0;

    // Calculate progress percentage (defaults to 0 if no documents)
    double progress = 0.0;
    if (totalCount > 0) {
      progress = approvedCount /
          (totalCount > 0 ? totalCount : 3); // Default to 3 if no count
    }

    // For completed stages, always show 100%
    if (stageStatus == 'completed') {
      progress = 1.0;
    }

    // Determine if stage is active (can be clicked)
    final isActive = _project!.isStageUnlocked(stageEnum);

    // Format the status for display
    String displayStatus = _formatStatus(stageStatus);

    return {
      'name': stageName,
      'status': displayStatus,
      'progress': progress,
      'isActive': isActive,
      'stageEnum': stageEnum,
      'approvedCount': approvedCount,
      'totalCount': totalCount,
    };
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'notstarted':
        return 'Not Started';
      default:
        return status.replaceFirst(status[0], status[0].toUpperCase());
    }
  }

  Widget _buildStageCard(Map<String, dynamic> stage) {
    final isActive = stage['isActive'] as bool;
    final progress = stage['progress'] as double;
    final approvedCount = stage['approvedCount'] as int;
    final totalCount = stage['totalCount'] as int;

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
                  stage: stage['stageEnum'] as ProjectStage,
                ),
              ),
            ).then((_) => _loadProjectData()); // Refresh after returning
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
                        'Documents: $approvedCount of $totalCount approved (${(progress * 100).toInt()}%)',
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
