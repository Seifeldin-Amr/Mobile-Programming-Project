import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/widgets/pdf_viewer_screen.dart';
import '../../models/project_document.dart';
import '../../models/document_approval.dart';
import '../../services/approval_service.dart';
import '../../services/document_service.dart';
import '../../utils/document_helper.dart';
import 'document_approval_dialog.dart';

class ClientDocumentsScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final ProjectStage stage;

  const ClientDocumentsScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.stage,
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
  bool _isProcessing = false;
  List<Map<String, dynamic>> _documents = [];
  Map<String, ApprovalStatus?> _documentApprovalStatus = {};

  @override
  void initState() {
    super.initState();
    // Both stages have 3 tabs
    int tabCount = 3;
    _tabController = TabController(length: tabCount, vsync: this);
    _loadDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    if (_isProcessing) return; // Prevent multiple simultaneous loads

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the new service method to get documents with approval status for current stage
      final result = await _documentService.getProjectDocumentsWithApproval(
          widget.projectId, widget.stage);

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading documents: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getDocumentsByType(DocumentType type) {
    return _documents.where((doc) => doc['documentType'] == type).toList();
  }

  // A simplified method that uses DocumentHelper utility
  Future<void> _downloadDocument(Map<String, dynamic> document) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing document...')),
    );

    final result = await DocumentHelper.downloadDocument(
      documentId: document['id'] as String?,
      base64Content: document['fileContent'] as String?,
      fileName: (document['name'] as String?) ?? 'document.pdf',
      context: context,
    );

    // Handle the result
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  Future<void> _showApprovalDialog(Map<String, dynamic> document) async {
    final documentId = document['id']?.toString();
    if (documentId == null || documentId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Document ID is missing')),
        );
      }
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => DocumentApprovalDialog(
        documentName: document['name'] ?? 'Unnamed Document',
      ),
    );

    if (result != null) {
      final bool isApproved = result['isApproved'] == true;
      final String comments = result['comments']?.toString() ?? '';

      try {
        setState(() {
          _isProcessing = true;
        });

        final status =
            isApproved ? ApprovalStatus.approved : ApprovalStatus.rejected;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Processing approval...')),
          );
        }

        try {
          setState(() {
            _documentApprovalStatus[documentId] = status;

            for (int i = 0; i < _documents.length; i++) {
              if (_documents[i]['id']?.toString() == documentId) {
                final statusString = status.toString().split('.').last;
                _documents[i]['approvalStatus'] = statusString;
                break;
              }
            }
          });
        } catch (uiError) {
          print("UI update error: $uiError");
        }

        // Server call
        await _approvalService.processDocumentApproval(
          documentId: documentId,
          projectId: widget.projectId,
          status: status,
          comments: comments, // Will be correctly handled by updated service
        );

        // Sync with latest DB state
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          final result = await _documentService.getProjectDocumentsWithApproval(
            widget.projectId,
            widget
                .stage, // Use the current stage instead of hardcoding stage1Planning
          );

          setState(() {
            _documents = result['documents'] as List<Map<String, dynamic>>;
            _documentApprovalStatus =
                result['approvalStatus'] as Map<String, ApprovalStatus?>;
          });
        }

        // Show success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Document ${isApproved ? 'approved' : 'rejected'} successfully',
              ),
            ),
          );
        }
      } catch (e) {
        // Catch any remaining errors
        print('Error processing approval: $e');
        await _loadDocuments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        setState(() {
          _isProcessing = false;
        });
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
          tabs: widget.stage == ProjectStage.stage1Planning
              ? const [
                  Tab(text: 'Concept Designs'),
                  Tab(text: 'Design Briefs'),
                  Tab(text: 'Meeting Summaries'),
                ]
              : const [
                  Tab(text: 'Concept Designs'),
                  Tab(text: 'MEP Drawings'),
                  Tab(text: 'Construction Documents'),
                ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: widget.stage == ProjectStage.stage1Planning
                  ? [
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
                    ]
                  : [
                      _buildDocumentList(
                        _getDocumentsByType(DocumentType.conceptDesign),
                        'Concept Designs',
                        Icons.architecture,
                        Colors.blue,
                      ),
                      _buildDocumentList(
                        _getDocumentsByType(DocumentType.mepDrawings),
                        'MEP Drawings',
                        Icons.engineering,
                        Colors.purple,
                      ),
                      _buildDocumentList(
                        _getDocumentsByType(DocumentType.constructionDocuments),
                        'Construction Documents',
                        Icons.apartment,
                        Colors.brown,
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
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Download Button
                    OutlinedButton.icon(
                      onPressed: () => _downloadDocument(document),
                      icon: const Icon(Icons.download, size: 32),
                      label: const Text('Download',
                          style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Uint8List bytes;
                        try {
                          bytes = base64Decode(document['fileContent']);
                        } catch (e) {
                          print('Error decoding document: $e');
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfViewerScreen(
                              pdfData: bytes,
                              documentName: document['name'],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility, size: 32),
                      label:
                          const Text('Preview', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Approve/Reject Button
                    if (approvalStatus != ApprovalStatus.approved &&
                        approvalStatus != ApprovalStatus.rejected)
                      ElevatedButton.icon(
                        onPressed: () => _showApprovalDialog(document),
                        icon: const Icon(Icons.check_circle,
                            size: 32, color: Colors.white),
                        label: const Text('Approve',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
