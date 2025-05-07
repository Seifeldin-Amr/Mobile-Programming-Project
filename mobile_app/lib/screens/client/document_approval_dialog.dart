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
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Approve'),
                  value: true,
                  groupValue: _isApproved,
                  onChanged: (value) {
                    setState(() {
                      _isApproved = value ?? true;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Reject'),
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
                  ? 'Comments (Optional)'
                  : 'Reason for Rejection (Required)',
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),

          if (!_isApproved)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Please provide feedback on why this document is being rejected.',
                style: TextStyle(
                  color: Colors.red,
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
              'comments': _commentsController.text,
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
