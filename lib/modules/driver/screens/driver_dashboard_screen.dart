import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/driver_provider.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize driver provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      driverProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DriverProvider, AuthProvider>(
      builder: (context, driverProvider, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Driver Dashboard'),
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/role-selection'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context, driverProvider, authProvider),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.deepOrange,
                          child: Text(
                            driverProvider.userData?.name.substring(0, 1).toUpperCase() ?? 'D',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${driverProvider.userData?.name ?? "Driver"}!',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                driverProvider.isServiceRunning ? 'Service Running' : 'Service Offline',
                                style: TextStyle(
                                  color: driverProvider.isServiceRunning ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Service Controls
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Controls',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Start/Stop Service Toggle
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                driverProvider.isServiceRunning ? 'Service Active' : 'Service Inactive',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            Switch(
                              value: driverProvider.isServiceRunning,
                              onChanged: (value) async {
                                try {
                                  if (value) {
                                    await driverProvider.startService();
                                  } else {
                                    await driverProvider.stopService();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Error display
                if (driverProvider.errorMessage != null)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              driverProvider.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => driverProvider.clearError(),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Navigation Button
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/driver'),
                    icon: const Icon(Icons.dashboard),
                    label: const Text('Go to Driver Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, DriverProvider driverProvider, AuthProvider authProvider) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to logout?'),
                Text('This will stop your driver service.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _logout(context, driverProvider, authProvider);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context, DriverProvider driverProvider, AuthProvider authProvider) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Signing out...'),
          ],
        ),
      ),
    );

    try {
      // Stop driver service first with timeout
      await driverProvider.stopService().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Driver service stop timed out');
        },
      );
      
      // Sign out with timeout
      await authProvider.signOut().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⚠️ Auth signout timed out, forcing logout');
        },
      );

      print('✅ Logout completed successfully');
      
      // Close loading indicator safely
      try {
        navigator.pop(); // Close loading dialog
      } catch (e) {
        print('⚠️ Could not close loading dialog: $e');
      }

      // Navigate to role selection
      try {
        context.go('/role-selection');
      } catch (e) {
        print('⚠️ Navigation error: $e');
      }
    } catch (e) {
      print('❌ Logout error: $e');
      
      // Close loading indicator safely
      try {
        navigator.pop(); // Close loading dialog
      } catch (e) {
        print('⚠️ Could not close loading dialog: $e');
      }
      
      // Force navigation even if logout partially failed
      try {
        context.go('/role-selection');
        
        // Show error but don't block navigation
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Logout completed with issues: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e) {
        print('⚠️ Navigation/SnackBar error: $e');
      }
    }
  }
}