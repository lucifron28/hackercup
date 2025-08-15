import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/auth/screens/login_screen.dart';
import '../../modules/auth/screens/role_selection_screen.dart';
import '../../modules/driver/screens/driver_home_screen.dart';
import '../../modules/driver/screens/driver_trip_screen.dart';
import '../../modules/driver/screens/driver_earnings_screen.dart';
import '../../modules/commuter/screens/commuter_home_screen.dart';
import '../../modules/commuter/screens/commuter_map_screen.dart';
import '../../modules/commuter/screens/route_list_screen.dart';
import '../../modules/lgu/screens/lgu_dashboard_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/role-selection',
    routes: [
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
      
      // Driver routes
      GoRoute(
        path: '/driver',
        name: 'driver-home',
        builder: (context, state) => const DriverHomeScreen(),
        routes: [
          GoRoute(
            path: '/trip',
            name: 'driver-trip',
            builder: (context, state) => const DriverTripScreen(),
          ),
          GoRoute(
            path: '/earnings',
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
            path: '/map',
            name: 'commuter-map',
            builder: (context, state) => const CommuterMapScreen(),
          ),
          GoRoute(
            path: '/routes',
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
    errorBuilder: (context, state) => Scaffold(
      body: Center(
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
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/role-selection'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Navigation helpers
class AppRouter {
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
