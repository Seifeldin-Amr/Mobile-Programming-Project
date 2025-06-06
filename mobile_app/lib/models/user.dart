import 'dart:typed_data';

class UserData {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final bool isAdmin;
  final Uint8List? profileImageBytes;
  final String? imageBase64;

  UserData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.isAdmin,
    this.profileImageBytes,
    this.imageBase64,
  });
}