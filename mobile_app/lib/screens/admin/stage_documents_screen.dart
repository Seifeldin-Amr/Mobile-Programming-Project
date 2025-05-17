import 'package:flutter/material.dart';
import '../../models/project_document.dart';
import '../../services/document_service.dart';
import 'document_list_screen.dart';

class StageDocumentsScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final ProjectStage stage;

  const StageDocumentsScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.stage,
  });

  @override
  State<StageDocumentsScreen> createState() => _StageDocumentsScreenState();
}

class _StageDocumentsScreenState extends State<StageDocumentsScreen> {
  final DocumentService _documentService = DocumentService();
  bool _isLoading = true;
  List<DocumentType> _requiredDocumentTypes = [];
  Map<DocumentType, List<Map<String, dynamic>>> _documentsByType = {};

  @override
  void initState() {
    super.initState();
    _loadRequiredDocuments();
  }

  void _loadRequiredDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For Stage 1, we're showing these three required document types
      if (widget.stage == ProjectStage.stage1Planning) {
        _requiredDocumentTypes = [
          DocumentType.meetingSummary,
          DocumentType.conceptDesign,
          DocumentType.designBrief,
        ];
      }
      // For Stage 2 (Design), include MEP drawings and construction documents
      else if (widget.stage == ProjectStage.stage2Design) {
        _requiredDocumentTypes = [
          DocumentType.conceptDesign,
          DocumentType.mepDrawings,
          DocumentType.constructionDocuments,
        ];
      }

      // Load documents for this stage and project
      final documents = await _documentService.getDocumentsByProjectAndStage(
          widget.projectId, widget.stage);

      _documentsByType = {};
      for (var docType in _requiredDocumentTypes) {
        _documentsByType[docType] =
            documents.where((doc) => doc.type == docType).map((doc) {
          final Map<String, dynamic> docMap = doc.toMap();
          docMap['id'] = doc.id;
          return docMap;
        }).toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading documents: $e')),
        );
      }
    }
  }

  void _navigateToDocumentList(DocumentType documentType) {
    final documents = _documentsByType[documentType] ?? [];

    final hasApprovedOrPending = documents.any((doc) {
      final status = doc['approvalStatus']?.toString().toLowerCase();
      return status == 'approved' || status == 'pending';
    });

    if (hasApprovedOrPending) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentListScreen(
            projectId: widget.projectId,
            projectName: widget.projectName,
            stage: widget.stage,
            documentType: documentType,
            documents: documents,
            allowUpload: false,
          ),
        ),
      ).then((_) => _loadRequiredDocuments());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentListScreen(
            projectId: widget.projectId,
            projectName: widget.projectName,
            stage: widget.stage,
            documentType: documentType,
            documents: documents,
            allowUpload: true,
          ),
        ),
      ).then((_) => _loadRequiredDocuments());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.stage.displayName} - ${widget.projectName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required Documents (Pending Client Approval)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _requiredDocumentTypes.length,
                      itemBuilder: (context, index) {
                        final docType = _requiredDocumentTypes[index];
                        final documents = _documentsByType[docType] ?? [];
                        final count = documents.length;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          child: InkWell(
                            onTap: () => _navigateToDocumentList(docType),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  _buildDocumentTypeIcon(docType),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          docType.displayName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$count document${count == 1 ? '' : 's'} uploaded',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDocumentTypeIcon(DocumentType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case DocumentType.meetingSummary:
        iconData = Icons.summarize;
        color = Colors.blue;
        break;
      case DocumentType.conceptDesign:
        iconData = Icons.architecture;
        color = Colors.green;
        break;
      case DocumentType.designBrief:
        iconData = Icons.description;
        color = Colors.orange;
        break;
      case DocumentType.mepDrawings:
        iconData = Icons.engineering;
        color = Colors.purple;
        break;
      case DocumentType.constructionDocuments:
        iconData = Icons.apartment;
        color = Colors.brown;
        break;
      default:
        iconData = Icons.file_present;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 28,
      ),
    );
  }
}
