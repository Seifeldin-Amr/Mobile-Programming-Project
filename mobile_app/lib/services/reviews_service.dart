import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/models/reviews.dart';

class ReviewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper function to encode images to base64
  Future<List<String>> _encodeImagesToBase64(List<File>? images) async {
    if (images == null || images.isEmpty) {
      return [];
    }

    List<String> base64Images = [];

    for (var image in images) {
      try {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        base64Images.add(base64String);
      } catch (e) {
        print('Error encoding image to base64: $e');
      }
    }

    return base64Images;
  }

  Future<String> createReview({
    required String projectId,
    required String projectName,
    required int ratingStars,
    required String description,
    List<File>? imagesUrl,
    String? clientImageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Encode images to base64 if provided
      final List<String> encodedImages = await _encodeImagesToBase64(imagesUrl);

      // Prepare review data
      final reviewData = {
        'clientName': user.email ?? 'Anonymous',
        'clientId': user.uid,
        'clientImageUrl': clientImageUrl,
        'projectId': projectId,
        'projectName': projectName,
        'ratingStars': ratingStars,
        'description': description,
        'imagesUrl':
            encodedImages, // Base64 encoded images are now serializable
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Create review in Firestore
      final docRef = await _firestore.collection('reviews').add(reviewData);
      print('Review data: $reviewData');
      print('Review created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating review: $e');
      throw Exception('Failed to create review: $e');
    }
  }

  Future<List<ReviewData>> getAllReviews() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ReviewData.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error: $e');

      return [];
    }
  }
}
