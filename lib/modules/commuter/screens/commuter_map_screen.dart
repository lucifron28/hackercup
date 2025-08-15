import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CommuterMapScreen extends StatefulWidget {
  const CommuterMapScreen({super.key});

  @override
  State<CommuterMapScreen> createState() => _CommuterMapScreenState();
}

class _CommuterMapScreenState extends State<CommuterMapScreen> {
  final MapController _mapController = MapController();
  
  // Sample jeepney locations (Manila area)
  final List<Map<String, dynamic>> _jeepneyLocations = [
    {
      'id': 'jeep_001',
      'route': 'Divisoria - Fairview',
      'position': const LatLng(14.5995, 120.9842), // Manila
      'seats': 8,
      'eta': 5,
    },
    {
      'id': 'jeep_002',
      'route': 'Cubao - Antipolo',
      'position': const LatLng(14.6091, 121.0223), // Quezon City
      'seats': 3,
      'eta': 12,
    },
    {
      'id': 'jeep_003',
      'route': 'Quiapo - Sta. Mesa',
      'position': const LatLng(14.5932, 120.9822), // Quiapo
      'seats': 12,
      'eta': 8,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Jeepney Map'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              // Center map on user location
              _mapController.move(const LatLng(14.5995, 120.9842), 15.0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh jeepney locations
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Jeepney locations updated')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(14.5995, 120.9842), // Manila center
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jeepneytracker.app',
              ),
              MarkerLayer(
                markers: _jeepneyLocations.map((jeepney) {
                  return Marker(
                    point: jeepney['position'],
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        _showJeepneyInfo(jeepney);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getJeepneyColor(jeepney['seats']),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          
          // Legend
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Legend',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(Colors.green, 'Available (5+ seats)'),
                    _buildLegendItem(Colors.orange, 'Limited (1-4 seats)'),
                    _buildLegendItem(Colors.red, 'Full (0 seats)'),
                  ],
                ),
              ),
            ),
          ),
          
          // Offline Mode Info
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Map tiles are cached for offline use in dead zones',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showRouteFilter();
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.filter_list, color: Colors.white),
      ),
    );
  }

  Color _getJeepneyColor(int seats) {
    if (seats >= 5) return Colors.green;
    if (seats >= 1) return Colors.orange;
    return Colors.red;
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showJeepneyInfo(Map<String, dynamic> jeepney) {
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
                Icon(
                  Icons.directions_bus,
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    jeepney['route'],
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoCard(
                  'ETA',
                  '${jeepney['eta']} min',
                  Icons.timer,
                  Colors.blue,
                ),
                _buildInfoCard(
                  'Available Seats',
                  '${jeepney['seats']}',
                  Icons.airline_seat_recline_normal,
                  _getJeepneyColor(jeepney['seats']),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tracking ${jeepney['route']}'),
                      action: SnackBarAction(
                        label: 'Stop',
                        onPressed: () {},
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text('Track This Jeepney'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
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
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRouteFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Routes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Divisoria - Fairview'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Cubao - Antipolo'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Quiapo - Sta. Mesa'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
