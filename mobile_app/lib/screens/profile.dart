import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_app_bar.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import 'auth/login.dart';
import 'dart:typed_data';
import '../services/user_service.dart';
import '../models/user.dart';
import 'personal_details.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AdminService _adminService = AdminService();
  final UserService _userService = UserService();
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _isAdmin = false;
  bool _isLoadingAdmin = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await _adminService.isCurrentUserAdmin();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoadingAdmin = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isLoadingAdmin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      // Handle case where user is null (not logged in)
      return Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: FutureBuilder<UserData?>(
          future: _userService.getUserData(_user!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                _isLoadingAdmin) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text('Error loading user data: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('User data not found'));
            }

            final userData = snapshot.data!;

            Uint8List? imageBytes = userData.profileImageBytes;
            String firstName = userData.firstName ?? 'First Name';
            String lastName = userData.lastName ?? 'Last Name';
            String email = userData.email ?? 'Email';
            String phoneNumber = userData.phoneNumber ?? 'Phone Number';

            return Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      imageBytes != null ? MemoryImage(imageBytes) : null,
                  child: imageBytes == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  '$firstName $lastName',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppConstants.smallPadding),
                if (_isAdmin)
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: AppConstants.largePadding),
                Expanded(
                  child: Column(
                    children: [
                      _buildOptionCard(
                        context,
                        Icons.person_outline,
                        'Personal Details',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PersonalDetailsScreen(
                                uid: _user.uid,
                                firstName: firstName,
                                lastName: lastName,
                                email: email,
                                phoneNumber: phoneNumber,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                      _buildLogoutButton(context),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
