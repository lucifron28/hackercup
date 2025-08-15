import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../modules/auth/screens/login_screen.dart';
import '../../modules/auth/screens/role_selection_screen.dart';
import '../../modules/auth/screens/driver_login_screen.dart';
import '../../modules/auth/screens/driver_register_screen.dart';
import '../../modules/driver/screens/driver_home_screen.dart';
import '../../modules/driver/screens/driver_dashboard_screen.dart';
import '../../modules/driver/screens/driver_trip_screen.dart';
import '../../modules/driver/screens/driver_earnings_screen.dart';
import '../../modules/commuter/screens/commuter_home_screen.dart';
import '../../modules/commuter/screens/commuter_map_screen.dart';
import '../../modules/commuter/screens/route_list_screen.dart';
import '../../modules/lgu/screens/lgu_dashboard_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/role-selection',
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/role-selection'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'The page you are looking for does not exist.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/role-selection'),
                    icon: const Icon(Icons.home),
                    label: const Text('Go to Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/role-selection');
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    routes: [
      // Main/Home route that redirects to role selection
      GoRoute(
        path: '/',
        redirect: (context, state) => '/role-selection',
      ),
      GoRoute(
        path: '/home',
        redirect: (context, state) => '/role-selection',
      ),
      GoRoute(
        path: '/main',
        redirect: (context, state) => '/role-selection',
      ),
      
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      
      // Driver Auth routes
      GoRoute(
        path: '/driver-login',
        name: 'driver-login',
        builder: (context, state) => const DriverLoginScreen(),
      ),
      GoRoute(
        path: '/driver-register',
        name: 'driver-register', 
        builder: (context, state) => const DriverRegisterScreen(),
      ),
      GoRoute(
        path: '/driver-dashboard',
        name: 'driver-dashboard',
        builder: (context, state) => const DriverDashboardScreen(),
      ),
      
      // Driver routes
      GoRoute(
        path: '/driver',
        name: 'driver-home',
        builder: (context, state) => const DriverHomeScreen(),
        routes: [
          GoRoute(
            path: 'trip',
            name: 'driver-trip',
            builder: (context, state) => const DriverTripScreen(),
          ),
          GoRoute(
            path: 'earnings',
            name: 'driver-earnings',
            builder: (context, state) => const DriverEarningsScreen(),
          ),
        ],
      ),
      
      // Commuter routes
      GoRoute(
        path: '/commuter',
        name: 'commuter-home',
        builder: (context, state) => const CommuterHomeScreen(),
        routes: [
          GoRoute(
            path: 'map',
            name: 'commuter-map',
            builder: (context, state) => const CommuterMapScreen(),
          ),
          GoRoute(
            path: 'routes',
            name: 'route-list',
            builder: (context, state) => const RouteListScreen(),
          ),
        ],
      ),
      
      // LGU routes
      GoRoute(
        path: '/lgu',
        name: 'lgu-dashboard',
        builder: (context, state) => const LguDashboardScreen(),
      ),
    ],
  );

  // Navigation helpers
  static void goToDriverLogin(BuildContext context) {
    context.go('/driver-login');
  }
  
  static void goToDriverRegister(BuildContext context) {
    context.go('/driver-register');
  }
  
  static void goToDriverDashboard(BuildContext context) {
    context.go('/driver-dashboard');
  }
  
  static void goToDriverApp(BuildContext context) {
    context.go('/driver');
  }
  
  static void goToCommuterApp(BuildContext context) {
    context.go('/commuter');
  }
  
  static void goToLguApp(BuildContext context) {
    context.go('/lgu');
  }
  
  static void goToLogin(BuildContext context) {
    context.go('/login');
  }
  
  static void goToRoleSelection(BuildContext context) {
    context.go('/role-selection');
  }
}
