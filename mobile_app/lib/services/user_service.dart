import 'dart:convert';
import 'dart:typed_data';
import '../models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserData?> getUserData(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return null;
      }

      final data = docSnapshot.data()!;
      final String firstName = data['firstName'] ?? 'First Name';
      final String lastName = data['lastName'] ?? 'Last Name';
      final String email = data['email'] ?? 'Email';
      final String phoneNumber = data['number'] ?? 'Phone Number';
      final bool isAdmin = data['isAdmin'] == true;

      Uint8List? imageBytes;
      final String? base64Image = data['profileImage'];
      if (base64Image != null) {
        try {
          imageBytes = base64Decode(base64Image);
        } catch (e) {
          imageBytes = null;
        }
      }

      return UserData(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        isAdmin: isAdmin,
        imageBase64: base64Image,
        profileImageBytes: imageBytes,

      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? profileImageBytes,
  }) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final user = _auth.currentUser;

    if (user == null) throw Exception('No user is currently logged in');

    try {
      // Update email in Firebase Auth if it's different and provided
      if (email != null && email != user.email) {
        await user.verifyBeforeUpdateEmail(email);
      }

      // Build the data map, only keeping non-null entries
      final Map<String, dynamic> updatedData = {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'number': phoneNumber,
        if (profileImageBytes != null) 'profileImage': profileImageBytes,
      };

      // Only update if there is data to update
      if (updatedData.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updatedData);
      }
    } on FirebaseAuthException catch (e) {
      throw Exception('Auth error: ${e.message}');
    } catch (e) {
      throw Exception('Profile update failed: $e');
    }
  }

  Future<void> updateUserPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final user = _auth.currentUser;

    if (user == null) throw Exception('No user is currently logged in');

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw Exception('Password update failed: ${e.message}');
    }
  }
}
