import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if the current user has admin privileges
  Future<bool> isCurrentUserAdmin() async {
    try {
      // Get the current user
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // Check if user has admin role in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return false;
      }

      final userData = userDoc.data();
      return userData != null && userData['isAdmin'] == true;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  
 
}
