import 'package:flutter/material.dart';

class DocumentApprovalDialog extends StatefulWidget {
  final String documentName;

  const DocumentApprovalDialog({
    super.key,
    required this.documentName,
  });

  @override
  State<DocumentApprovalDialog> createState() => _DocumentApprovalDialogState();
}

class _DocumentApprovalDialogState extends State<DocumentApprovalDialog> {
  bool _isApproved = true;
  final _commentsController = TextEditingController();

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Review Document: ${widget.documentName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Approval Options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 140, // Fixed width to prevent text wrapping
                child: RadioListTile<bool>(
                  title: const Text(
                    'Approve',
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                  value: true,
                  groupValue: _isApproved,
                  onChanged: (value) {
                    setState(() {
                      _isApproved = value ?? true;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 140, // Fixed width to prevent text wrapping
                child: RadioListTile<bool>(
                  title: const Text(
                    'Reject',
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                  value: false,
                  groupValue: _isApproved,
                  onChanged: (value) {
                    setState(() {
                      _isApproved = value ?? false;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Comments Field
          TextField(
            controller: _commentsController,
            decoration: InputDecoration(
              labelText: _isApproved
                  ? 'Comments (Recommended)'
                  : 'Reason for Rejection (Required)',
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),

          // Guidance text based on approval status
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _isApproved
                  ? 'Adding comments for approval is recommended to provide feedback.'
                  : 'Please provide feedback on why this document is being rejected.',
              style: TextStyle(
                color: _isApproved ? Colors.blue[700] : Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_isApproved && _commentsController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Comments are required when rejecting a document')),
              );
              return;
            }

            Navigator.of(context).pop({
              'isApproved': _isApproved,
              'comments': _commentsController.text.isEmpty
                  ? (_isApproved ? 'Document approved' : '')
                  : _commentsController.text,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isApproved ? Colors.green : Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(_isApproved ? 'Approve' : 'Reject'),
        ),
      ],
    );
  }
}
