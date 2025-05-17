import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/utils/renovation_calculator.dart';
import 'home.dart';
import 'profile.dart';
import 'services.dart';
import 'client/client_projects_screen.dart';
import 'admin/admin_dashboard.dart';
import '../services/admin_service.dart';
import 'renovation_estimate.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  bool _isLoading = true;
  final AdminService _adminService = AdminService();

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
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
        });
      }
    }
  }

  Widget _getScreen(int index) {
    if (_isAdmin) {
      // Admin screens
      final adminScreens = [
        const HomeScreen(),
        const AdminDashboard(),
        const ProfileScreen(),
      ];
      return adminScreens[index];
    } else {
      // Client screens
      final clientScreens = [
        const HomeScreen(),
        const RenovationEstimateScreen(),
        const ClientProjectsScreen(),
        const ProfileScreen(),
      ];
      return clientScreens[index];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<BottomNavigationBarItem> navigationItems = _isAdmin
        ? <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
                icon: Icon(Icons.home), label: 'Home'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person), label: 'Profile')
          ]
        : <BottomNavigationBarItem>[
            const BottomNavigationBarItem(
                icon: Icon(Icons.home), label: 'Home'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.calculate), label: 'Calculator'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.folder), label: 'Projects'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person), label: 'Profile')
          ];

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _getScreen(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: navigationItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
