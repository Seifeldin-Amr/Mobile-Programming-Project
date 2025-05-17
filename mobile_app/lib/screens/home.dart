import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_app/services/admin_service.dart';
import 'package:mobile_app/services/project_service.dart';
import 'package:mobile_app/services/reviews_service.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_app_bar.dart';
import './review_screen.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProjectService _projectService = ProjectService();
  final AdminService _adminService = AdminService();
  final ReviewsService _reviewsService = ReviewsService();

  bool isAdmin = false;
  bool isLoading = true;
  List<dynamic> usersReviews = [];
  List<dynamic> completedProjects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      // Check if the user is an admin
      isAdmin = await _adminService.isCurrentUserAdmin();
      if (isAdmin) {
        // If the user is an admin, fetch all projects
        final allReviews = await _reviewsService.getAllReviews();
        setState(() {
          usersReviews = allReviews;
          isAdmin = isAdmin;
          isLoading = false;
        });

        return;
      } else {
        final allReviews = await _reviewsService.getAllReviews();
        final clientProjectss = await _projectService.getClientProjects();
        // Filter completed projects
        final filtered = clientProjectss
            .where((project) => project.status.toLowerCase() == 'completed')
            .where((project) =>
                allReviews.any((review) => review.projectId != project.id))
            .toList();
        print('Filtered Completed Projects: $filtered');
        setState(() {
          completedProjects = filtered;
        });
      }
    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(context),
              const SizedBox(height: AppConstants.largePadding),
              if (!isAdmin) ...[
                // Reviews Card
                _buildReviewsCard(context),
                const SizedBox(height: AppConstants.largePadding),
                // Categories Section
                _buildCategoriesSection(context),
                const SizedBox(height: AppConstants.largePadding),
                // Featured Products Section
                _buildFeaturedProductsSection(context),
              ] else ...[
                Text(
                  'User Reviews',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                //Create a list of reviews
                SizedBox(
                  height: 600,
                  child: usersReviews.isEmpty
                      ? Center(
                          child: Text(
                            'No reviews available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: usersReviews.length,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemBuilder: (context, index) {
                            final review = usersReviews[index];
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              margin: EdgeInsets.only(
                                bottom: 12,
                                left: 4,
                                right: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Theme.of(context)
                                        .colorScheme
                                        .surface
                                        .withOpacity(0.7),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                  backgroundImage: review.clientImageUrl !=
                                              null &&
                                          review.clientImageUrl.isNotEmpty
                                      ? MemoryImage(
                                          base64Decode(review.clientImageUrl))
                                      : null,
                                  child: (review.clientImageUrl == null ||
                                          review.clientImageUrl.isEmpty)
                                      ? Icon(Icons.person,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary)
                                      : null,
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      review.clientName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    _buildRatingStars(review.ratingStars),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    review.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                onTap: () {
                                  // Show full review details in a dialog or navigate to details
                                  _showReviewDetails(context, review);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
              const SizedBox(height: AppConstants.largePadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsCard(BuildContext context) {
    return Column(
      children: completedProjects.map((project) {
        return Container(
          width: double.infinity,
          margin:
              const EdgeInsets.symmetric(vertical: AppConstants.defaultPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                BorderRadius.circular(AppConstants.defaultBorderRadius),
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: AppConstants.defaultPadding),
                    Text(
                      'Project Completed!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  'Your "${project.name}" project has been finalized. We would love to hear your feedback!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
                const SizedBox(height: AppConstants.largePadding),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomButton(
                      text: 'Leave a Review',
                      onPressed: () {
                        // Navigate to review screen with project data
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReviewScreen(
                              projectName: project.name,
                              projectId: project.id,
                            ),
                          ),
                        );
                      },
                      backgroundColor: Colors.white,
                      textColor: Theme.of(context).colorScheme.secondary,
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  'Discover amazing interior design ideas',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.home_work_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final categories = [
      {'name': 'Kitchen', 'icon': Icons.kitchen},
      {'name': 'Bathroom', 'icon': Icons.bathtub},
      {'name': 'Living Room', 'icon': Icons.weekend},
      {'name': 'Bedroom', 'icon': Icons.bed},
      {'name': 'Office', 'icon': Icons.computer},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return Container(
                width: 80,
                margin:
                    const EdgeInsets.only(right: AppConstants.defaultPadding),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                            AppConstants.defaultBorderRadius),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        categories[index]['icon'] as IconData,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      categories[index]['name'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedProductsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Designs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Row(
                children: [
                  Text('View All'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16)
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return _buildProductCard(context, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, int index) {
    final designNames = [
      'Modern Kitchen',
      'Luxury Bathroom',
      'Cozy Living Room',
      'Elegant Bedroom',
      'Stylish Home Office',
    ];
    final designPrices = [2500.00, 1800.00, 3200.00, 2100.00, 1900.00];
    final designIcons = [
      Icons.kitchen,
      Icons.bathtub,
      Icons.weekend,
      Icons.bed,
      Icons.computer,
    ];

    return Card(
      margin: const EdgeInsets.only(right: AppConstants.defaultPadding),
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppConstants.defaultBorderRadius),
                    topRight: Radius.circular(AppConstants.defaultBorderRadius),
                  ),
                ),
                child: Center(
                  child: Icon(
                    designIcons[index],
                    size: AppConstants.largeIconSize,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    designNames[index],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    '\$${designPrices[index]}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  CustomButton(
                    text: 'View Design',
                    onPressed: () {},
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating ? Colors.amber : Colors.grey[400],
          size: 18,
        );
      }),
    );
  }

  void _showReviewDetails(BuildContext context, dynamic review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
              backgroundImage: review.clientImageUrl != null &&
                      review.clientImageUrl.isNotEmpty
                  ? MemoryImage(base64Decode(review.clientImageUrl))
                  : null,
              child: (review.clientImageUrl == null ||
                      review.clientImageUrl.isEmpty)
                  ? Icon(Icons.person,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.clientName),
                  SizedBox(height: 4),
                  _buildRatingStars(review.ratingStars),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            review.description,
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
