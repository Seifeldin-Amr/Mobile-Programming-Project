import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/project.dart';
import '../../services/project_service.dart';
import 'document_upload.dart';
import 'stage_documents_screen.dart';
import '../../models/project_document.dart';
import 'project_details_screen.dart';

class AdminProjectManagementScreen extends StatefulWidget {
  const AdminProjectManagementScreen({super.key});

  @override
  State<AdminProjectManagementScreen> createState() =>
      _AdminProjectManagementScreenState();
}

class _AdminProjectManagementScreenState
    extends State<AdminProjectManagementScreen> {
  final ProjectService _projectService = ProjectService();
  List<Project> _projects = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final projects = await _projectService.getAdminProjects();
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load projects: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createProject() async {
    // Show dialog to create a new project
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Project'),
        content: SingleChildScrollView(
          child: CreateProjectForm(
            onProjectCreated: (String projectId) {
              _loadProjects();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Project created successfully')),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _assignClient(Project project) async {
    // Show dialog to assign a client to the project
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Client to Project'),
        content: SingleChildScrollView(
          child: AssignClientForm(
            projectId: project.id,
            onClientAssigned: () {
              _loadProjects();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Client assigned successfully')),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _projects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No projects found'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _createProject,
                            child: const Text('Create Project'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProjects,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.all(AppConstants.defaultPadding),
                        itemCount: _projects.length,
                        itemBuilder: (context, index) {
                          final project = _projects[index];
                          return ProjectCard(
                            project: project,
                            onAssignClient: () => _assignClient(project),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createProject,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onAssignClient;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onAssignClient,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    _buildStatusBadge(context),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Type: ${project.type}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (project.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Description: ${project.description}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Client: ${project.clientName ?? 'Not assigned'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Created: ${project.createdAt.toString().split('.').first}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

         

          // Actions
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectDetailsScreen(
                          projectId: project.id,
                        ),
                      ),
                    );
                  },
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                if (project.clientId == null) ...[
                  TextButton.icon(
                    onPressed: onAssignClient,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Assign Client'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  

  

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    switch (project.status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        project.status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class CreateProjectForm extends StatefulWidget {
  final Function(String) onProjectCreated;

  const CreateProjectForm({
    super.key,
    required this.onProjectCreated,
  });

  @override
  State<CreateProjectForm> createState() => _CreateProjectFormState();
}

class _CreateProjectFormState extends State<CreateProjectForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'Renovation';
  final List<String> _projectTypes = [
    'Renovation',
    'New Construction',
    'Interior Design',
    'Landscaping',
    'Other',
  ];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final projectService = ProjectService();
      final projectId = await projectService.createProject(
        name: _nameController.text,
        type: _selectedType,
        description: _descriptionController.text,
      );

      widget.onProjectCreated(projectId);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create project: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Project Name',
              hintText: 'Enter a name for the project',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a project name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Project Type',
            ),
            items: _projectTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter a description for the project',
            ),
            maxLines: 3,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Project'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AssignClientForm extends StatefulWidget {
  final String projectId;
  final VoidCallback onClientAssigned;

  const AssignClientForm({
    super.key,
    required this.projectId,
    required this.onClientAssigned,
  });

  @override
  State<AssignClientForm> createState() => _AssignClientFormState();
}

class _AssignClientFormState extends State<AssignClientForm> {
  final ProjectService _projectService = ProjectService();
  List<Map<String, dynamic>> _clients = [];
  String? _selectedClientId;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final clients = await _projectService.getAllClients();
      setState(() {
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load clients: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _assignClient() async {
    if (_selectedClientId == null) {
      setState(() {
        _errorMessage = 'Please select a client';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Find selected client to get their name
      final client = _clients.firstWhere((c) => c['id'] == _selectedClientId);
      final clientName = client['displayName'] ?? 'Unknown Client';

      await _projectService.updateProject(
        projectId: widget.projectId,
        clientId: _selectedClientId,
        clientName: clientName,
      );

      widget.onClientAssigned();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to assign client: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_clients.isEmpty)
          const Text('No clients available. Add clients first.')
        else
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Client',
            ),
            value: _selectedClientId,
            hint: const Text('Select a client to assign'),
            items: _clients.map((client) {
              return DropdownMenuItem<String>(
                value: client['id'],
                child: Text(client['displayName'] ?? 'Unknown Client'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedClientId = value;
              });
            },
          ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSubmitting || _isLoading || _clients.isEmpty
                  ? null
                  : _assignClient,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Assign Client'),
            ),
          ],
        ),
      ],
    );
  }
}
