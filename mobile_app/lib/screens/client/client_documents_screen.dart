import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../models/project_document.dart';
import '../../models/document_approval.dart';
import '../../services/approval_service.dart';
import '../../services/document_service.dart';
import '../../utils/document_helper.dart';
import 'document_approval_dialog.dart';

class ClientDocumentsScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ClientDocumentsScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ClientDocumentsScreen> createState() => _ClientDocumentsScreenState();
}

class _ClientDocumentsScreenState extends State<ClientDocumentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _approvalService = ApprovalService();
  final _documentService = DocumentService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _documents = [];
  Map<String, ApprovalStatus?> _documentApprovalStatus = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the new service method to get documents with approval status
      final result = await _documentService.getProjectDocumentsWithApproval(
          widget.projectId, ProjectStage.stage1Planning);

      setState(() {
        _documents = result['documents'] as List<Map<String, dynamic>>;
        _documentApprovalStatus =
            result['approvalStatus'] as Map<String, ApprovalStatus?>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading documents: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _getDocumentsByType(DocumentType type) {
    return _documents.where((doc) => doc['documentType'] == type).toList();
  }

  // A simplified method that uses DocumentHelper utility
  Future<void> _downloadAndOpenDocument(Map<String, dynamic> document) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing document...')),
    );

    final result = await DocumentHelper.downloadDocument(
      documentId: document['id'] as String?,
      base64Content: document['fileContent'] as String?,
      fileName: (document['name'] as String?) ?? 'document.pdf',
      context: context,
      openAfterDownload: true,
    );

    // Handle the result
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  Future<void> _showApprovalDialog(Map<String, dynamic> document) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => DocumentApprovalDialog(
        documentName: document['name'],
      ),
    );

    if (result != null) {
      final bool isApproved = result['isApproved'];
      final String? comments = result['comments'];

      try {
        await _approvalService.processDocumentApproval(
          documentId: document['id'],
          projectId: widget.projectId,
          status:
              isApproved ? ApprovalStatus.approved : ApprovalStatus.rejected,
          comments: comments,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Document ${isApproved ? 'approved' : 'rejected'} successfully')),
        );

        // Refresh document list
        _loadDocuments();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Project: ${widget.projectName}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Concept Designs'),
            Tab(text: 'Design Briefs'),
            Tab(text: 'Meeting Summaries'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDocumentList(
                  _getDocumentsByType(DocumentType.conceptDesign),
                  'Concept Designs',
                  Icons.architecture,
                  Colors.blue,
                ),
                _buildDocumentList(
                  _getDocumentsByType(DocumentType.designBrief),
                  'Design Briefs',
                  Icons.design_services,
                  Colors.purple,
                ),
                _buildDocumentList(
                  _getDocumentsByType(DocumentType.meetingSummary),
                  'Meeting Summaries',
                  Icons.meeting_room,
                  Colors.green,
                ),
              ],
            ),
    );
  }

  Widget _buildDocumentList(
    List<Map<String, dynamic>> documents,
    String emptyMessage,
    IconData icon,
    Color color,
  ) {
    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: color.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No $emptyMessage Available',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Documents will appear here when uploaded by the admin',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        final documentId = document['id'];
        final approvalStatus = _documentApprovalStatus[documentId];

        // Format upload date
        final uploadDate = (document['uploadDate'] as Timestamp).toDate();
        final formattedDate = DateFormat('MMM dd, yyyy').format(uploadDate);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document['name'] ?? 'Untitled Document',
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
                    if (approvalStatus != null)
                      _buildStatusBadge(approvalStatus),
                  ],
                ),
              ),

              // Document Description
              if (document['description'] != null &&
                  document['description'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    document['description'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),

              // Document Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Download Button
                    OutlinedButton.icon(
                      onPressed: () => _downloadAndOpenDocument(document),
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    ),
                    const SizedBox(width: 12),

                    // Approve/Reject Button
                    if (approvalStatus != ApprovalStatus.approved &&
                        approvalStatus != ApprovalStatus.rejected)
                      ElevatedButton.icon(
                        onPressed: () => _showApprovalDialog(document),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ApprovalStatus status) {
    IconData icon;
    String text;
    Color color;

    switch (status) {
      case ApprovalStatus.approved:
        icon = Icons.check_circle;
        text = 'Approved';
        color = Colors.green;
        break;
      case ApprovalStatus.rejected:
        icon = Icons.cancel;
        text = 'Rejected';
        color = Colors.red;
        break;
      case ApprovalStatus.pending:
      default:
        icon = Icons.pending;
        text = 'Pending';
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
