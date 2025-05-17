import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/services/auth_service.dart';
import '../services/user_service.dart';
class PersonalDetailsScreen extends StatefulWidget {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber; // optional
  final String? profileImageBase64; // optional: pass existing base64 image

  const PersonalDetailsScreen({
    super.key,
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber = '',
    this.profileImageBase64,
  });

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isEditing = false;
  Uint8List? _imageBytes;
  String? _imageBase64;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController = TextEditingController(text: widget.lastName);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phoneNumber);

    if (widget.profileImageBase64 != null) {
      _imageBase64 = widget.profileImageBase64;
      _imageBytes = base64Decode(_imageBase64!);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveDetails() async {
    await UserService().updateUserProfile(
      uid: widget.uid,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      profileImageBytes: _imageBase64,
      );

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Details saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Details'),
        leading: BackButton(),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveDetails();
              } else {
                _toggleEdit();
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isEditing ? _pickImage : null,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                child: _imageBytes == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('First Name', _firstNameController,
                enabled: _isEditing),
            const SizedBox(height: 16),
            _buildTextField('Last Name', _lastNameController,
                enabled: _isEditing),
            const SizedBox(height: 16),
            _buildTextField('Email', _emailController,
                enabled: _isEditing), // Email editable now
            const SizedBox(height: 16),
            _buildTextField('Phone Number', _phoneController,
                enabled: _isEditing),
            const SizedBox(height: 16),
            if (_isEditing)
              ElevatedButton(
                onPressed: () {
                  // Here you can add password update logic or navigate to a password change screen
                  _showPasswordUpdateDialog();
                },
                child: const Text('Change Password'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _showPasswordUpdateDialog() {
    final TextEditingController _oldPasswordController =
        TextEditingController();
    final TextEditingController _newPasswordController =
        TextEditingController();
    final TextEditingController _confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Password'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Old Password'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm Password'),
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
            onPressed: () async {
              final oldPassword = _oldPasswordController.text;
              final newPassword = _newPasswordController.text;
              final confirmPassword = _confirmPasswordController.text;

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

              if (newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Password must be at least 6 characters')),
                );
                return;
              }

              try {
                await UserService().updateUserPassword(
                  currentPassword: oldPassword,
                  newPassword: newPassword,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Password updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
