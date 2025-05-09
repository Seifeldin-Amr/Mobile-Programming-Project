import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String encodedDocument; // Changed from documentUrl to encodedDocument
  final String documentName;
  final String documentType; // Add document type (pdf, doc, etc.)

  const DocumentViewerScreen({
    super.key,
    required this.encodedDocument,
    required this.documentName,
    required this.documentType,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  bool _isDownloading = false;
  String? _downloadedFilePath;
  double _downloadProgress = 0.0;

  Future<void> _openDocument() async {
    // First ensure the document is downloaded
    if (_downloadedFilePath == null) {
      await _downloadDocument();
    }

    // Then open the downloaded file
    if (_downloadedFilePath != null) {
      await _openDownloadedFile(_downloadedFilePath!);
    }
  }

  Future<void> _downloadDocument() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      // Create file name with the proper extension
      final fileName =
          '${widget.documentName.replaceAll(' ', '_')}.${widget.documentType}';

      // Get the documents directory for saving the file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        setState(() {
          _isDownloading = false;
          _downloadedFilePath = filePath;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File already downloaded'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => _openDownloadedFile(filePath),
                textColor: Colors.white,
              ),
            ),
          );
        }
        return;
      }

      // Process the encoded document data
      // Split the work for better UI responsiveness
      await compute<Map<String, dynamic>, Uint8List>(
        (data) {
          final encoded = data['encoded'] as String;
          return base64Decode(encoded);
        },
        {'encoded': widget.encodedDocument},
      ).then((bytes) async {
        // Report progress during writing - although this will be fast,
        // we simulate progress for better UX
        final totalChunks = bytes.length ~/ 10240;
        for (var i = 0; i < totalChunks; i++) {
          await Future.delayed(const Duration(milliseconds: 5));
          setState(() {
            _downloadProgress = (i + 1) / totalChunks;
          });
        }

        // Write the file
        await file.writeAsBytes(bytes);

        setState(() {
          _isDownloading = false;
          _downloadedFilePath = filePath;
          _downloadProgress = 1.0;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document saved to your device'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Open',
                onPressed: () => _openDownloadedFile(filePath),
                textColor: Colors.white,
              ),
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openDownloadedFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open file'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File no longer exists'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _downloadedFilePath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine icon and text based on document type
    IconData documentIcon;
    Color iconColor;

    switch (widget.documentType.toLowerCase()) {
      case 'pdf':
        documentIcon = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'doc':
      case 'docx':
        documentIcon = Icons.description;
        iconColor = Colors.blue;
        break;
      case 'xls':
      case 'xlsx':
        documentIcon = Icons.table_chart;
        iconColor = Colors.green;
        break;
      case 'ppt':
      case 'pptx':
        documentIcon = Icons.slideshow;
        iconColor = Colors.orange;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
        documentIcon = Icons.image;
        iconColor = Colors.purple;
        break;
      default:
        documentIcon = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentName),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _openDocument(),
            tooltip: 'Open in external viewer',
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  documentIcon,
                  size: 100,
                  color: iconColor,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.documentName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'This ${widget.documentType.toUpperCase()} document will be opened in your device\'s default viewer.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _openDocument,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open Document'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadDocument,
                      icon: Icon(_downloadedFilePath != null
                          ? Icons.check_circle
                          : Icons.download),
                      label: Text(_downloadedFilePath != null
                          ? 'Downloaded'
                          : 'Download Document'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        backgroundColor: _downloadedFilePath != null
                            ? Colors.green
                            : Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (_isDownloading) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: _downloadProgress,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Downloading... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_downloadedFilePath != null) ...[
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () => _openDownloadedFile(_downloadedFilePath!),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Open downloaded file'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
