import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../models/project_document.dart';
import '../../services/project_service.dart';
import 'stage_documents_screen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final ProjectService _projectService = ProjectService();
  late Future<Project> _projectFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  void _loadProject() {
    _projectFuture = _projectService.getProject(widget.projectId);
  }

  Future<void> _checkAndUpdateStages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _projectService.checkAndAdvanceProjectStages(widget.projectId);

      setState(() {
        _projectFuture = _projectService.getProject(widget.projectId);
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Project stages checked and updated if necessary')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating stages: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Check & Update Stages',
            onPressed: _isLoading ? null : _checkAndUpdateStages,
          ),
        ],
      ),
      body: FutureBuilder<Project>(
        future: _projectFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('No project found'),
            );
          }

          final project = snapshot.data!;
          return _buildProjectDetails(project);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _checkAndUpdateStages,
        icon: const Icon(Icons.refresh),
        label: const Text('Check & Update Stages'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildProjectDetails(Project project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProjectInfoCard(project),
          const SizedBox(height: 16),
          const Text(
            'Project Stages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildStageCard(
            context,
            'Stage 1: Planning',
            project.getStageStatus(ProjectStage.stage1Planning),
            project,
            ProjectStage.stage1Planning,
          ),
          _buildStageCard(
            context,
            'Stage 2: Design',
            project.getStageStatus(ProjectStage.stage2Design),
            project,
            ProjectStage.stage2Design,
          ),
          _buildStageCard(
            context,
            'Stage 3: Execution',
            project.getStageStatus(ProjectStage.stage3Execution),
            project,
            ProjectStage.stage3Execution,
          ),
          _buildStageCard(
            context,
            'Stage 4: Completion',
            project.getStageStatus(ProjectStage.stage4Completion),
            project,
            ProjectStage.stage4Completion,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectInfoCard(Project project) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await _showEditProjectDialog(context, project);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Type: ${project.type}'),
            if (project.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Description: ${project.description}'),
              ),
            const SizedBox(height: 8),
            Text('Client: ${project.clientName ?? 'No client assigned'}'),
            const SizedBox(height: 8),
            Text('Status: ${project.status}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStageCard(
    BuildContext context,
    String title,
    String status,
    Project project,
    ProjectStage stage,
  ) {
    // Determine status color
    Color statusColor;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'notStarted':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.blue;
    }

    // Determine if this stage is locked
    final bool isLocked = !project.isStageUnlocked(stage);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: isLocked
            ? null
            : () {
                // Navigate to stage details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StageDocumentsScreen(
                      projectId: project.id,
                      projectName: project.name,
                      stage: stage,
                    ),
                  ),
                ).then((_) => _loadProject());
              },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Status: ${status.replaceFirst(status[0], status[0].toUpperCase())}',
                        ),
                      ],
                    ),
                    if (isLocked)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Complete previous stage to unlock',
                          style: TextStyle(
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!isLocked) const Icon(Icons.arrow_forward_ios, size: 16)
            ],
          ),
        ),
      ),
    );
  }

  // Method to show the edit project dialog
  Future<void> _showEditProjectDialog(
      BuildContext context, Project project) async {
    final nameController = TextEditingController(text: project.name);
    final descriptionController =
        TextEditingController(text: project.description);
    String selectedType = project.type;
    String selectedStatus = project.status;
    String? selectedClientId = project.clientId;
    String? selectedClientName = project.clientName;

    // Loading state for clients
    bool isLoadingClients = true;
    List<Map<String, dynamic>> clients = [];

    final types = [
      'Renovation',
      'New Construction',
      'Interior Design',
      'Landscaping',
      'Other'
    ];
    final statuses = ['active', 'pending', 'completed', 'cancelled'];

    if (!types.contains(selectedType)) {
      types.add(selectedType);
    }

    if (!statuses.contains(selectedStatus)) {
      statuses.add(selectedStatus);
    }

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    // Load clients list
    try {
      clients = await _projectService.getAllClients();
      isLoadingClients = false;
    } catch (e) {
      print('Error loading clients: $e');
      isLoadingClients = false;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Project'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Project Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Project name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Project Type',
                        border: OutlineInputBorder(),
                      ),
                      items: types
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Project Status',
                        border: OutlineInputBorder(),
                        hintText: 'Select status',
                      ),
                      items: statuses
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status.replaceFirst(
                                      status[0], status[0].toUpperCase()),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  isLoadingClients
                      ? const Center(child: CircularProgressIndicator())
                      : Container(
                          width: double.infinity,
                          child: DropdownButtonFormField<String?>(
                            isExpanded: true,
                            value: selectedClientId,
                            decoration: const InputDecoration(
                              labelText: 'Assigned Client',
                              border: OutlineInputBorder(),
                              hintText: 'Select a client',
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'No Client (Remove Assignment)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              ...clients
                                  .map((client) => DropdownMenuItem<String?>(
                                        value: client['id'],
                                        child: Text(
                                          client['displayName'] ??
                                              'Unknown Client',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedClientId = value;
                                if (value != null) {
                                  final selectedClient = clients.firstWhere(
                                    (client) => client['id'] == value,
                                    orElse: () =>
                                        {'displayName': 'Unknown Client'},
                                  );
                                  selectedClientName =
                                      selectedClient['displayName'];
                                } else {
                                  selectedClientName = null;
                                }
                              });
                            },
                          ),
                        ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          isSaving = true;
                        });

                        try {
                          await _projectService.updateProject(
                            projectId: project.id,
                            name: nameController.text,
                            type: selectedType,
                            status: selectedStatus,
                            description: descriptionController.text,
                            clientId: selectedClientId,
                            clientName: selectedClientName,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Project updated successfully')),
                            );
                            Navigator.pop(context);

                            // Reload project data
                            _loadProject();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error updating project: $e')),
                            );
                            setState(() {
                              isSaving = false;
                            });
                          }
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );

    // Clean up the controllers
    nameController.dispose();
    descriptionController.dispose();
  }
}
