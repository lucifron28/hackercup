import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/firebase_realtime_service.dart';
import '../../../core/utils/route_utils.dart';

class CommuterMapScreen extends StatefulWidget {
  const CommuterMapScreen({super.key});

  @override
  State<CommuterMapScreen> createState() => _CommuterMapScreenState();
}

class _CommuterMapScreenState extends State<CommuterMapScreen> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _jeepneyLocations = [];
  Position? _userLocation;
  StreamSubscription<List<Map<String, dynamic>>>? _driversSubscription;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    // _loadActiveDrivers(); // Commented out for demo - using mock data instead
    _addMockData(); // Add demo data for demonstration
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = position;
      });
      
      // Center map on user location
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  void _loadActiveDrivers() {
    // Cancel previous subscription if it exists
    _driversSubscription?.cancel();
    
    _driversSubscription = FirebaseRealtimeService.getActiveDriversStream().listen(
      (drivers) {
        if (!mounted) return; // Prevent setState on disposed widget
        
        print('🗺️ MAP: Received ${drivers.length} drivers');
        setState(() {
          _jeepneyLocations = drivers.map((driver) {
            String routeId = driver['routeId'] ?? '';
            bool isAccepting = driver['isAcceptingPassengers'] == true;
            String status = driver['status'] ?? 'unknown';
            print('🚗 Driver: ${driver['id']}, Route: $routeId, Lat: ${driver['latitude']}, Lng: ${driver['longitude']}, Status: $status, isAccepting: $isAccepting');
            return {
              'id': driver['id'],
              'route': RouteUtils.getRouteName(routeId),
              'position': LatLng(
                driver['latitude'] ?? 14.5995,
                driver['longitude'] ?? 120.9842,
              ),
              'status': isAccepting ? 'Available' : 'Full',
              'rawStatus': status, // Keep raw status for debugging
              'eta': _calculateETA(driver),
              'driverName': driver['driverName'] ?? 'Unknown Driver',
            };
          }).toList();
        });
      },
      onError: (error) {
        print('❌ MAP: Error loading drivers: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading jeepneys: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  int _calculateETA(Map<String, dynamic> driver) {
    if (_userLocation == null) return 0;
    
    double distanceInMeters = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      driver['latitude'] ?? 14.5995,
      driver['longitude'] ?? 120.9842,
    );
    
    // Rough ETA calculation: distance in km / average speed (20 km/h in traffic)
    double distanceInKm = distanceInMeters / 1000;
    int etaInMinutes = (distanceInKm / 20 * 60).round();
    
    return etaInMinutes.clamp(1, 60); // Between 1 and 60 minutes
  }

  void _addMockData() {
    // Add mock jeepney data for demonstration
    setState(() {
      _jeepneyLocations = [
        {
          'id': 'demo_jeepney_1',
          'route': 'Divisoria - Fairview',
          'position': const LatLng(14.6042, 120.9822), // Divisoria area
          'status': 'Available',
          'rawStatus': 'available',
          'eta': 5,
          'driverName': 'Mang Juan Cruz',
        },
        {
          'id': 'demo_jeepney_2', 
          'route': 'Cubao - Antipolo',
          'position': const LatLng(14.6191, 121.0570), // Cubao area
          'status': 'Full',
          'rawStatus': 'full',
          'eta': 12,
          'driverName': 'Kuya Pedro Santos',
        },
        {
          'id': 'demo_jeepney_3',
          'route': 'Quiapo - Sta. Mesa',
          'position': const LatLng(14.5995, 120.9842), // Central Manila
          'status': 'Available', 
          'rawStatus': 'available',
          'eta': 8,
          'driverName': 'Ate Maria Reyes',
        },
        {
          'id': 'demo_jeepney_4',
          'route': 'Marikina - Ortigas',
          'position': const LatLng(14.6507, 121.1029), // Marikina area
          'status': 'Available',
          'rawStatus': 'available', 
          'eta': 15,
          'driverName': 'Kuya Roberto Garcia',
        },
        {
          'id': 'demo_jeepney_5',
          'route': 'Alabang - Makati',
          'position': const LatLng(14.4290, 121.0359), // Alabang area
          'status': 'Full',
          'rawStatus': 'full',
          'eta': 20,
          'driverName': 'Mang Tony Dela Cruz',
        },
        {
          'id': 'demo_jeepney_6',
          'route': 'Pasay - Taguig',
          'position': const LatLng(14.5547, 121.0244), // Pasay area
          'status': 'Available',
          'rawStatus': 'available',
          'eta': 7,
          'driverName': 'Kuya Jose Ramos',
        },
      ];
    });
    print('🎭 DEMO: Added ${_jeepneyLocations.length} mock jeepneys for demonstration');
  }

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
            onPressed: () async {
              // Center map on user location
              if (_userLocation != null) {
                _mapController.move(
                  LatLng(_userLocation!.latitude, _userLocation!.longitude),
                  15.0,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Centered on your location'),
                    duration: Duration(seconds: 1),
                  ),
                );
              } else {
                // Try to get location again
                await _getUserLocation();
                if (_userLocation != null) {
                  _mapController.move(
                    LatLng(_userLocation!.latitude, _userLocation!.longitude),
                    15.0,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Centered on your location'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to get your location. Please check permissions.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh jeepney locations
              // _loadActiveDrivers(); // Commented out for demo
              _addMockData(); // Use mock data instead
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
                markers: [
                  // User location marker
                  if (_userLocation != null)
                    Marker(
                      point: LatLng(_userLocation!.latitude, _userLocation!.longitude),
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ),
                  // Jeepney markers
                  ..._jeepneyLocations.map((jeepney) {
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
                            color: _getJeepneyColor(jeepney['status']),
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
                ],
              ),
            ],
          ),
          
          // No Jeepneys Overlay
          if (_jeepneyLocations.isEmpty)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(32),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.directions_bus_filled_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Active Jeepneys',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'There are currently no jeepneys operating in this area. Try refreshing or check back later.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  // _loadActiveDrivers(); // Commented out for demo
                                  _addMockData(); // Use mock data instead
                                  setState(() {});
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Refresh'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back, size: 16),
                                label: const Text('Go Back'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
                    _buildLegendItem(Colors.blue, 'Your Location'),
                    _buildLegendItem(Colors.green, 'Available'),
                    _buildLegendItem(Colors.red, 'Full'),
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

  Color _getJeepneyColor(String status) {
    if (status == 'Available') return Colors.green;
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
                    'Status',
                    jeepney['status'],
                    Icons.info,
                    _getJeepneyColor(jeepney['status']),
                  ),
                ],
              ),            const SizedBox(height: 16),
            
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
    // Get unique routes from active drivers
    Set<String> uniqueRoutes = _jeepneyLocations
        .map((jeepney) => jeepney['route'] as String)
        .toSet();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Routes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: uniqueRoutes.isEmpty
              ? [
                  const SizedBox(height: 20),
                  Icon(Icons.filter_list_off, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No active routes to filter',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ]
              : uniqueRoutes
                  .map((route) => CheckboxListTile(
                        title: Text(route),
                        value: true,
                        onChanged: (value) {},
                      ))
                  .toList(),
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

  @override
  void dispose() {
    _driversSubscription?.cancel(); // Cancel stream subscription
    super.dispose();
  }
}
