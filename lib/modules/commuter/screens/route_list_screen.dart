import 'package:flutter/material.dart';
import '../../../core/services/firebase_realtime_service.dart';

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
        String routeId = driver['routeId'] ?? 'Unknown Route';
        if (!routeGroups.containsKey(routeId)) {
          routeGroups[routeId] = [];
        }
        routeGroups[routeId]!.add(driver);
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
      routeGroups.forEach((routeId, routeDrivers) {
        routes.add({
          'name': routeId,
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
            child: ListView.builder(
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
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _sendSMSQuery(route),
                                  icon: const Icon(Icons.sms, size: 16),
                                  label: const Text('SMS', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
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
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _trackRoute(route);
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Track on Map'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendSMSQuery(route);
                    },
                    icon: const Icon(Icons.sms),
                    label: const Text('SMS Query'),
                  ),
                ),
              ],
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

  void _sendSMSQuery(Map<String, dynamic> route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SMS Query'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send this SMS to get next 3 ETAs:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                'JEEP ${route['name']}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'SMS rates may apply. Works offline.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, this would open the SMS app
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening SMS app...')),
              );
            },
            child: const Text('Send SMS'),
          ),
        ],
      ),
    );
  }
}
