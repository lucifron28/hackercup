import 'package:flutter/material.dart';

import '../../../core/services/firebase_realtime_service.dart';
import '../../../core/utils/route_utils.dart';

class RouteListScreen extends StatefulWidget {
  const RouteListScreen({super.key});

  @override
  State<RouteListScreen> createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  List<Map<String, dynamic>> _routes = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  void _loadRoutes() {
    FirebaseRealtimeService.getActiveDriversStream().listen((drivers) {
      // Group drivers by route
      Map<String, List<Map<String, dynamic>>> routeGroups = {};
      
      for (var driver in drivers) {
        String routeId = driver['routeId'] ?? '';
        String routeName = RouteUtils.getRouteName(routeId);
        
        if (!routeGroups.containsKey(routeName)) {
          routeGroups[routeName] = [];
        }
        routeGroups[routeName]!.add(driver);
      }
      
      // Convert to route list
      List<Map<String, dynamic>> routes = [];
      List<Color> colors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.red,
        Colors.teal,
        Colors.indigo,
        Colors.pink,
      ];
      
      int colorIndex = 0;
      routeGroups.forEach((routeName, routeDrivers) {
        routes.add({
          'name': routeName,
          'fare': 12.00, // Default fare - could be configured per route
          'distance': '25.0 km', // Default distance - could be calculated
          'duration': '40-50 min', // Default duration - could be calculated
          'activeJeepneys': routeDrivers.length,
          'color': colors[colorIndex % colors.length],
        });
        colorIndex++;
      });
      
      setState(() {
        _routes = routes;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredRoutes = _routes.where((route) {
      return route['name'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jeepney Routes'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search routes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          
          // Route Stats Card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Total Routes',
                    '${_routes.length}',
                    Icons.route,
                    Colors.blue,
                  ),
                  _buildStatItem(
                    'Active Jeepneys',
                    '${_routes.fold<int>(0, (sum, route) => sum + route['activeJeepneys'] as int)}',
                    Icons.directions_bus,
                    Colors.green,
                  ),
                  _buildStatItem(
                    'Avg Fare',
                    '₱${(_routes.fold<double>(0, (sum, route) => sum + route['fare']) / _routes.length).toStringAsFixed(0)}',
                    Icons.monetization_on,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Routes List
          Expanded(
            child: filteredRoutes.isEmpty 
                ? _buildNoRoutesView()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredRoutes.length,
                    itemBuilder: (context, index) {
                      final route = filteredRoutes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showRouteDetails(route),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: route['color'],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            route['name'],
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₱${route['fare'].toStringAsFixed(2)} • ${route['distance']} • ${route['duration']}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: route['color'].withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${route['activeJeepneys']} active',
                                        style: TextStyle(
                                          color: route['color'],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Quick Actions
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _trackRoute(route),
                                        icon: const Icon(Icons.location_on, size: 16),
                                        label: const Text('Track', style: TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRoutesView() {
    // Check if it's because of search filter or actually no routes
    final isSearching = _searchQuery.isNotEmpty;
    final hasRoutes = _routes.isNotEmpty;
    
    if (isSearching && hasRoutes) {
      // No results for search query
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No Routes Found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No routes match "$_searchQuery".\nTry a different search term.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear Search'),
              ),
            ],
          ),
        ),
      );
    } else {
      // No active routes at all
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.route_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Active Routes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'There are currently no jeepneys operating on any routes. Please check back later.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _loadRoutes();
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Alternative Options',
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Check back during peak hours (6-9 AM, 5-8 PM)\n'
                        '• Contact local transport office for route updates',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showRouteDetails(Map<String, dynamic> route) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 50,
                  decoration: BoxDecoration(
                    color: route['color'],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    route['name'],
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard('Fare', '₱${route['fare'].toStringAsFixed(2)}', Icons.monetization_on),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard('Distance', route['distance'], Icons.straighten),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard('Duration', route['duration'], Icons.timer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailCard('Active', '${route['activeJeepneys']} jeepneys', Icons.directions_bus),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _trackRoute(route);
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Track on Map'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _trackRoute(Map<String, dynamic> route) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Now tracking ${route['name']}'),
        action: SnackBarAction(
          label: 'View Map',
          onPressed: () {
            // Navigate to map view
          },
        ),
      ),
    );
  }

}
