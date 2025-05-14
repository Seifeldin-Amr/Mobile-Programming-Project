import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_app_bar.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import 'auth/login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _adminService = AdminService();
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await _adminService.isCurrentUserAdmin();
      print('Admin status check in Profile Screen: $isAdmin'); // Debug print
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking admin status: $e'); // Debug print
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
      }
    }
  }

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
        final bool isAdminInFirestore = userData['isAdmin'] == true;

        if (isAdminInFirestore != _isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _isAdmin = isAdminInFirestore;
            });
          });
        }

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
                _isAdmin
                    ? Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: AppConstants.smallPadding),
                            Text(
                              'Admin',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
                const SizedBox(height: AppConstants.largePadding),
                Expanded(
                  child: Column(
                    children: [
                      _buildOptionCard(
                        context,
                        Icons.person_outline,
                        'Personal Details',
                        () {},
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      _buildOptionCard(
                        context,
                        Icons.shopping_bag_outlined,
                        'Past Orders',
                        () {},
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      _buildOptionCard(
                        context,
                        Icons.settings_outlined,
                        'Settings',
                        () {},
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
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
    VoidCallback onTap, {
    Color? color,
  }) {
    return Card(
      child: ListTile(
        leading:
            Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
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
