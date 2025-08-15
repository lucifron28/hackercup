import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/driver_provider.dart';
import '../../../core/providers/auth_provider.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      driverProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, driverProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Driver Dashboard'),
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _showNavigationDrawer(context, driverProvider),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showLogoutDialog(context, driverProvider),
              ),
            ],
          ),
          body: _buildBody(context, driverProvider),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DriverProvider driverProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Switch(
                        value: driverProvider.isServiceRunning,
                        onChanged: (value) async {
                          if (value) {
                            await driverProvider.startService();
                          } else {
                            await driverProvider.stopService();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        driverProvider.isServiceRunning 
                            ? Icons.radio_button_checked 
                            : Icons.radio_button_unchecked,
                        color: driverProvider.isServiceRunning ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        driverProvider.isServiceRunning ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: driverProvider.isServiceRunning ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Show error if any
                  if (driverProvider.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              driverProvider.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => driverProvider.clearError(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Trip Management Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip Management',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  if (!driverProvider.isOnTrip) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: driverProvider.isServiceRunning 
                            ? () => _startTrip(driverProvider) 
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Trip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _endTrip(driverProvider),
                        icon: const Icon(Icons.stop),
                        label: const Text('End Trip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Trip info
                    if (driverProvider.currentTrip != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Trip Duration: ${driverProvider.currentTrip!.tripDurationFormatted}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.route, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Route: ${driverProvider.currentTrip!.route}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Toggle Availability
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            print('┌─────────────────────────────────────────────────');
                            print('│ 🔄 UI: AVAILABILITY BUTTON PRESSED!');
                            print('│ Current status: ${driverProvider.isAcceptingPassengers}');
                            print('└─────────────────────────────────────────────────');
                            await driverProvider.toggleAvailability();
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(driverProvider.isAcceptingPassengers 
                                      ? 'Now accepting passengers' 
                                      : 'Stopped accepting passengers'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            print('❌ UI: Toggle availability failed: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update status: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(driverProvider.isAcceptingPassengers 
                            ? Icons.pause 
                            : Icons.play_arrow),
                        label: Text(driverProvider.isAcceptingPassengers 
                            ? 'Stop Accepting Passengers' 
                            : 'Start Accepting Passengers'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: driverProvider.isAcceptingPassengers 
                              ? Colors.orange 
                              : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick Actions
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  'View Earnings',
                  Icons.monetization_on,
                  Colors.green,
                  () => context.go('/driver/earnings'),
                ),
                _buildActionCard(
                  context,
                  'Trip History',
                  Icons.history,
                  Colors.blue,
                  () {
                    // Navigate to trip history
                  },
                ),
                _buildActionCard(
                  context,
                  'Route Info',
                  Icons.route,
                  Colors.orange,
                  () {
                    // Navigate to route info
                  },
                ),
                _buildActionCard(
                  context,
                  'Emergency',
                  Icons.emergency,
                  Colors.red,
                  () {
                    // Emergency function
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startTrip(DriverProvider driverProvider) async {
    try {
      await driverProvider.startTrip();
      context.push('/driver/trip');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _endTrip(DriverProvider driverProvider) async {
    try {
      await driverProvider.endTrip();
      // Trip ended - availability will be handled by provider
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showNavigationDrawer(BuildContext context, DriverProvider driverProvider) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Role Selection'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/role-selection');
                },
              ),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Driver Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/driver-dashboard');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context, driverProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, DriverProvider driverProvider) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
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
                await _logout(context, driverProvider);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context, DriverProvider driverProvider) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Show loading indicator
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
      
      // Sign out from auth provider with timeout
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
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

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
