import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_app_bar.dart';
import '../services/auth_service.dart';
import 'login.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('User data not found'));
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String firstName = userData['firstName'] ?? 'First Name';
        final String lastName = userData['lastName'] ?? 'Last Name';
        final String email = userData['email'] ?? 'Email';

        return Scaffold(
          appBar: const CustomAppBar(),
          body: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                const CircleAvatar(
                    radius: 50, child: Icon(Icons.person, size: 50)),
                const SizedBox(height: AppConstants.defaultPadding),
                Text('$firstName $lastName',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  email,
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
      },
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
        onPressed: () async {
          try {
            await AuthService().logout();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logged out successfully!')),
            );

            // Navigate back to the login screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.toString()}')),
            );
          }
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
