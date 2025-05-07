import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_constants.dart';
import '../../models/project_document.dart';
import '../../models/project.dart';
import '../../services/document_service.dart';

class DocumentUploadScreen extends StatefulWidget {
  final ProjectStage stage;
  final String? projectId;

  const DocumentUploadScreen({
    super.key,
    required this.stage,
    this.projectId,
  });

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentService = DocumentService();
  final _projectIdController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fileNameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  DocumentType _selectedDocumentType = DocumentType.meetingSummary;
  File? _selectedFile;
  bool _isUploading = false;
  bool _isPdf = false;

  @override
  void initState() {
    super.initState();
    if (widget.projectId != null) {
      _projectIdController.text = widget.projectId!;
    }
  }

  @override
  void dispose() {
    _projectIdController.dispose();
    _descriptionController.dispose();
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _isPdf = false;
          // Extract file name from path and set it as default
          String fileName = pickedFile.name;
          _fileNameController.text = fileName;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final fileName = result.files.single.name;

        setState(() {
          _selectedFile = file;
          _isPdf = true;
          _fileNameController.text = fileName;

          // Set document type based on what the PDF likely contains
          _selectedDocumentType = DocumentType.other;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking PDF: $e')),
      );
    }
  }

  Future<void> _uploadDocument() async {
    if (_formKey.currentState!.validate() && _selectedFile != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        final fileName = _fileNameController.text.isNotEmpty
            ? _fileNameController.text
            : _selectedFile!.path.split('/').last;

        await _documentService.uploadDocument(
          file: _selectedFile!,
          fileName: fileName,
          type: _selectedDocumentType,
          stage: widget.stage,
          projectId: _projectIdController.text,
          description: _descriptionController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document uploaded successfully')),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading document: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  void _showDocumentSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Document Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Image Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF Document'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPdf();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String stageTitle = widget.stage.displayName;

    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Document - $stageTitle'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading document...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project ID
                    TextFormField(
                      controller: _projectIdController,
                      decoration: const InputDecoration(
                        labelText: 'Project ID',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: widget.projectId != null,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a project ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),

                    // Document Type
                    DropdownButtonFormField<DocumentType>(
                      value: _selectedDocumentType,
                      decoration: const InputDecoration(
                        labelText: 'Document Type',
                        border: OutlineInputBorder(),
                      ),
                      items: DocumentType.values.map((type) {
                        return DropdownMenuItem<DocumentType>(
                          value: type,
                          child: Text(type.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedDocumentType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),

                    // File Name
                    TextFormField(
                      controller: _fileNameController,
                      decoration: const InputDecoration(
                        labelText: 'File Name (with extension)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a file name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),

                    // Document Selection
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(AppConstants.defaultPadding),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(
                            AppConstants.defaultBorderRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Document File',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppConstants.smallPadding),
                          if (_selectedFile != null) ...[
                            Text(
                              'Selected file: ${_selectedFile!.path.split(Platform.isWindows ? '\\' : '/').last}',
                              style: const TextStyle(color: Colors.green),
                            ),
                            const SizedBox(height: 12),
                            if (!_isPdf)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedFile!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf,
                                      size: 64,
                                      color: Colors.red,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'PDF Document',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                          ] else
                            const Text(
                              'No file selected',
                              style: TextStyle(color: Colors.red),
                            ),
                          const SizedBox(height: AppConstants.smallPadding),
                          ElevatedButton.icon(
                            onPressed: _showDocumentSourceDialog,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Select Document'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.largePadding),

                    // Upload Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _selectedFile != null ? _uploadDocument : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Upload Document'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
