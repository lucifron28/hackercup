import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthenticationStatus();
    });
  }

  void _checkAuthenticationStatus() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    print('🔍 ROLE SELECTION - Authentication Status:');
    print('  - isAuthenticated: ${authProvider.isAuthenticated}');
    print('  - currentUser: ${authProvider.currentUser?.uid ?? 'null'}');
    print('  - userData: ${authProvider.userData?.toString() ?? 'null'}');
    print('  - authState: ${authProvider.authState}');
    
    if (authProvider.isAuthenticated && authProvider.userData != null) {
      print('✅ User is logged in as ${authProvider.userData!.userType}');
    } else {
      print('❌ User is not authenticated or userData is null');
    }
  }

  void _handleDriverTap() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Debug authentication state
    print('🔍 DEBUG - Authentication check:');
    print('  - isAuthenticated: ${authProvider.isAuthenticated}');
    print('  - currentUser: ${authProvider.currentUser?.uid ?? 'null'}');
    print('  - userData: ${authProvider.userData?.toString() ?? 'null'}');
    print('  - userType: ${authProvider.userData?.userType ?? 'null'}');
    
    // More robust authentication check
    if (authProvider.isAuthenticated && 
        authProvider.currentUser != null && 
        authProvider.userData != null && 
        authProvider.userData!.userType == 'driver') {
      print('✅ Authenticated driver detected, going to driver dashboard');
      context.go('/driver');
    } else {
      print('❌ Not authenticated as driver, redirecting to login');
      // Clear any cached auth state to ensure fresh login
      if (authProvider.isAuthenticated) {
        authProvider.signOut();
      }
      context.go('/driver-login');
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade800,
                  Colors.blue.shade600,
                  Colors.blue.shade400,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Debug info and logout section
                    if (authProvider.isAuthenticated) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '🔍 DEBUG: Currently logged in as:',
                              style: TextStyle(
                                color: Colors.white.withAlpha(179),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${authProvider.userData?.name ?? 'Unknown'} (${authProvider.userData?.userType ?? 'Unknown'})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await authProvider.signOut();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Logged out successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.logout, size: 16),
                              label: const Text('Logout'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(120, 36),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Logo and welcome text
                    Container(
                      margin: const EdgeInsets.only(bottom: 60),
                      child: Column(
                        children: [
                          // App logo/icon
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(38),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.directions_bus_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          const Text(
                            'Welcome to JeepGo',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          Text(
                            'Choose your role to get started',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withAlpha(128),
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    // Role cards
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Commuter card
                          _buildRoleCard(
                            title: 'Commuter',
                            subtitle: 'Find rides and track your journey',
                            icon: Icons.person,
                            color: Colors.green,
                            onTap: () => context.go('/commuter'),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Driver card
                          _buildRoleCard(
                            title: 'Driver',
                            subtitle: 'Provide rides and manage your route',
                            icon: Icons.drive_eta,
                            color: Colors.orange,
                            onTap: () => _handleDriverTap(),
                          ),
                        ],
                      ),
                    ),
                    
                    // Footer
                    Container(
                      margin: const EdgeInsets.only(top: 40),
                      child: Text(
                        '© 2025 JeepGo Transport System',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withAlpha(153),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withAlpha(50),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}