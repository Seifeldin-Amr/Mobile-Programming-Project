import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/services/user_service.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_button.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/reviews_service.dart';

class ReviewScreen extends StatefulWidget {
  final String projectName;
  final String projectId;

  const ReviewScreen({
    Key? key,
    required this.projectName,
    required this.projectId,
  }) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final TextEditingController _reviewController = TextEditingController();
  final UserService _userService = UserService();
  final User? _user = FirebaseAuth.instance.currentUser;
  String? _photoImage;
  int _rating = 0;
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isFormValid = false;
  final ReviewsService _reviewsService = ReviewsService();

  @override
  void initState() {
    super.initState();
    _reviewController.addListener(_validateForm);
    _userService.getUserData(_user!.uid).then((user) {
      setState(() {
        _photoImage = user?.imageBase64;
      });
    });
  }

  @override
  void dispose() {
    _reviewController.removeListener(_validateForm);
    _reviewController.dispose();
    super.dispose();
  }

  // Validate all required fields
  void _validateForm() {
    setState(() {
      _isFormValid = _rating > 0 && _reviewController.text.trim().isNotEmpty;
    });
  }

  // Prepare form data for API submission
  Map<String, dynamic> _prepareFormData() {
    return {
      'project_name': widget.projectName,
      'project_id': widget.projectId,
      'rating': _rating,
      'review_text': _reviewController.text.trim(),
      'images': _images, // Array of image data
    };
  }

  Future<void> _addImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _images.add(File(image.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          'Leave a Review',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project info
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.defaultBorderRadius),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppConstants.defaultPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Completed',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            widget.projectName,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.largePadding),

              // Rating section
              Text(
                'How would you rate your experience?*', // Added asterisk to indicate required field
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: index < _rating ? Colors.amber : Colors.grey,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                        _validateForm(); // Validate form when rating changes
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.largePadding),

              // Image Upload Section
              Text(
                'Share Project Photos (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload images of your completed project',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              // Image Preview Grid
              if (_images.isNotEmpty)
                Container(
                  height: 120,
                  margin: const EdgeInsets.only(
                      bottom: AppConstants.defaultPadding),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _images[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // Upload Button (Gallery only)
              InkWell(
                onTap: _addImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                    ),
                    borderRadius:
                        BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Select Photos from Gallery',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.largePadding),

              // Review text field
              Text(
                'Your Review*', // Added asterisk to indicate required field
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              TextField(
                controller: _reviewController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Share your experience with this project...',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.defaultBorderRadius),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.defaultBorderRadius),
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '* Required fields',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.largePadding * 2),

              // Submit button
              CustomButton(
                text: 'Submit Review',
                onPressed: () {
                  if (_isFormValid) {
                    // Get prepared data for API submission
                    final formData = _prepareFormData();
                    // Handle API submission
                    _submitReview(formData);

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Review submitted successfully!')),
                    );
                  }
                },
                width: double.infinity,
                // Add disabled styling if needed
                backgroundColor: _isFormValid
                    ? null // Use default color when enabled
                    : Colors.grey[300], // Use grey when disabled
                textColor: _isFormValid
                    ? null // Use default text color when enabled
                    : Colors.grey[600], // Use grey text when disabled
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to submit the review with images
  Future<void> _submitReview(Map<String, dynamic> formData) async {
    _reviewsService
        .createReview(
      projectId: formData['project_id'],
      projectName: formData['project_name'],
      ratingStars: formData['rating'],
      description: formData['review_text'],
      imagesUrl: formData['images'],
      clientImageUrl: _photoImage,
    )
        .then((_) {
      // Handle success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );
    }).catchError((error) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $error')),
      );
    });

    // Optionally, navigate back or show a success message
    Navigator.pop(context);
  }
}
