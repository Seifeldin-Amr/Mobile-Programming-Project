import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/project.dart';
import '../../models/project_document.dart';
import '../../models/document_approval.dart';
import '../../services/document_service.dart';
import 'document_upload.dart';

class DocumentListScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final ProjectStage stage;
  final DocumentType documentType;
  final List<Map<String, dynamic>> documents;
  final bool allowUpload;

  const DocumentListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.stage,
    required this.documentType,
    required this.documents,
    this.allowUpload = true, // Default to true for backward compatibility
  });

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final DocumentService _documentService = DocumentService();
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with the documents passed in
    _documents = List.from(widget.documents);
  }

  Future<void> _refreshDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final documents = await _documentService.getDocumentsByProjectAndStage(
        widget.projectId,
        widget.stage,
      );

      // Filter and convert to maps
      final filteredDocs =
          documents.where((doc) => doc.type == widget.documentType).map((doc) {
        final Map<String, dynamic> docMap = doc.toMap();
        docMap['id'] = doc.id;
        return docMap;
      }).toList();

      setState(() {
        _documents = filteredDocs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing documents: $e')),
        );
      }
    }
  }

  void _navigateToUploadDocument() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentUploadScreen(
          stage: widget.stage,
          projectId: widget.projectId,
          documentType: widget.documentType,
        ),
      ),
    );

    if (result == true) {
      // If document was uploaded successfully, refresh the list
      _refreshDocuments();
    }
  }

  Future<void> _deleteDocument(Map<String, dynamic> document) async {
    try {
      // Convert map to ProjectDocument object
      final projectDoc = ProjectDocument.fromMap(document);

      await _documentService.deleteDocument(projectDoc);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted successfully')),
      );

      _refreshDocuments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting document: $e')),
      );
    }
  }

  Future<void> _confirmDeleteDocument(Map<String, dynamic> document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${document['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteDocument(document);
    }
  }

  Future<void> _updateApprovalStatus(
      Map<String, dynamic> document, String status) async {
    try {
      // Convert map to ProjectDocument object
      final projectDoc = ProjectDocument.fromMap(document);
      projectDoc.approvalStatus = status;

      await _documentService.updateDocument(projectDoc);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document $status successfully')),
      );

      _refreshDocuments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating approval status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentType.displayName),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshDocuments,
              child: _documents.isEmpty
                  ? _buildEmptyState()
                  : _buildDocumentsList(),
            ),
      floatingActionButton: widget.allowUpload
          ? FloatingActionButton(
              onPressed: _navigateToUploadDocument,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getDocumentTypeIcon(),
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No ${widget.documentType.displayName} Documents',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a new document by tapping the + button',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];
        return _buildDocumentCard(document);
      },
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document) {
    final uploadDate = (document['uploadDate'] as DateTime?) ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(uploadDate);

    // Get approval status if available
    String? approvalStatus = document['approvalStatus'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getDocumentTypeIcon(),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document['name'] ?? 'Unnamed Document',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Uploaded on $formattedDate',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Fix the status badge condition
                if (approvalStatus != null)
                  _buildStatusBadge(approvalStatus)
                else
                  _buildStatusBadge("pending")
              ],
            ),
          ),

          // Description
          if (document['description'] != null &&
              document['description'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(document['description']),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Preview Button - could be implemented to open the document
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement document preview
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Document preview not implemented')),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Preview'),
                    ),
                    const SizedBox(width: 8),
                    // Delete Button
                    OutlinedButton.icon(
                      onPressed: () => _confirmDeleteDocument(document),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDocumentTypeIcon() {
    switch (widget.documentType) {
      case DocumentType.meetingSummary:
        return Icons.summarize;
      case DocumentType.conceptDesign:
        return Icons.architecture;
      case DocumentType.designBrief:
        return Icons.description;
      default:
        return Icons.file_present;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        text = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
