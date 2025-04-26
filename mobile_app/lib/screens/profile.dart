import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            // Profile Header
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: AppConstants.defaultPadding),
            Text('User Name', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'user@example.com',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppConstants.largePadding),

            // Main Options
            Expanded(
              child: Column(
                children: [
                  // Personal Details
                  _buildOptionCard(
                    context,
                    Icons.person_outline,
                    'Personal Details',
                    () {},
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // Past Orders
                  _buildOptionCard(
                    context,
                    Icons.shopping_bag_outlined,
                    'Past Orders',
                    () {},
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // Settings
                  _buildOptionCard(
                    context,
                    Icons.settings_outlined,
                    'Settings',
                    () {},
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),

                  // Logout
                  _buildLogoutButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Add logout logic here
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
          ),
        ),
        child: const Text('Logout'),
      ),
    );
  }
}
