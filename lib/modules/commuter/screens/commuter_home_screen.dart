import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/firebase_realtime_service.dart';
import '../../../core/utils/route_utils.dart';

class CommuterHomeScreen extends StatefulWidget {
  const CommuterHomeScreen({super.key});

  @override
  State<CommuterHomeScreen> createState() => _CommuterHomeScreenState();
}

class _CommuterHomeScreenState extends State<CommuterHomeScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _nearbyJeepneys = [];
  Position? _userLocation;
  StreamSubscription<List<Map<String, dynamic>>>? _driversSubscription;

    @override
  void initState() {
    super.initState();
    _addMockData(); // Add demo data immediately for demonstration
    _getUserLocation(); // Try to get location in background
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
      
      // Mock data already loaded in initState, no need to reload
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  void _loadNearbyJeepneys() {
    // Cancel previous subscription if it exists
    _driversSubscription?.cancel();
    
    _driversSubscription = FirebaseRealtimeService.getActiveDriversStream().listen((drivers) {
      if (!mounted) return; // Prevent setState on disposed widget
      
      List<Map<String, dynamic>> nearbyDrivers = [];
      
      for (var driver in drivers) {
        double distance = 0.0;
        int eta = 5;
        
        if (_userLocation != null) {
          double distanceInMeters = Geolocator.distanceBetween(
            _userLocation!.latitude,
            _userLocation!.longitude,
            driver['latitude'] ?? 14.5995,
            driver['longitude'] ?? 120.9842,
          );
          
          distance = distanceInMeters / 1000; // Convert to km
          eta = (distance / 20 * 60).round().clamp(1, 60); // ETA in minutes
        }
        
        nearbyDrivers.add({
          'route': RouteUtils.getRouteName(driver['routeId'] ?? ''),
          'eta': eta,
          'status': driver['isAcceptingPassengers'] == true ? 'Available' : 'Full',
          'distance': '${distance.toStringAsFixed(1)} km',
          'driverName': driver['driverName'] ?? 'Unknown Driver',
        });
      }
      
      // Sort by distance and take nearest 5
      nearbyDrivers.sort((a, b) {
        double distA = double.parse(a['distance'].toString().split(' ')[0]);
        double distB = double.parse(b['distance'].toString().split(' ')[0]);
        return distA.compareTo(distB);
      });
      
      if (mounted) { // Check if widget is still mounted before calling setState
        setState(() {
          _nearbyJeepneys = nearbyDrivers.take(5).toList();
        });
      }
    });
  }

  void _addMockData() {
    // Add mock jeepney data for demonstration
    setState(() {
      _nearbyJeepneys = [
        {
          'id': 'demo_jeepney_1',
          'route': 'Divisoria - Fairview',
          'distance': '0.8 km',
          'eta': 5,
          'status': 'Available',
          'driverName': 'Mang Juan Cruz',
        },
        {
          'id': 'demo_jeepney_2',
          'route': 'Cubao - Antipolo', 
          'distance': '1.2 km',
          'eta': 12,
          'status': 'Full',
          'driverName': 'Kuya Pedro Santos',
        },
        {
          'id': 'demo_jeepney_3',
          'route': 'Quiapo - Sta. Mesa',
          'distance': '1.5 km',
          'eta': 8,
          'status': 'Available',
          'driverName': 'Ate Maria Reyes',
        },
        {
          'id': 'demo_jeepney_4',
          'route': 'Marikina - Ortigas',
          'distance': '2.1 km', 
          'eta': 15,
          'status': 'Available',
          'driverName': 'Kuya Roberto Garcia',
        },
        {
          'id': 'demo_jeepney_5',
          'route': 'Alabang - Makati',
          'distance': '3.4 km',
          'eta': 20,
          'status': 'Full',
          'driverName': 'Mang Tony Dela Cruz',
        },
      ];
    });
    print('🎭 DEMO: Added ${_nearbyJeepneys.length} mock nearby jeepneys for demonstration');
  }

  @override
  void dispose() {
    _driversSubscription?.cancel(); // Cancel stream subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jeepney Tracker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/role-selection'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Show notifications
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeTab(),
                _buildMapTab(),
                _buildRoutesTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Live Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Routes',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          Text(
            'Nearby Jeepneys',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Expanded(
            child: _nearbyJeepneys.isEmpty 
                ? _buildNoJeepneysView()
                : ListView.builder(
                    itemCount: _nearbyJeepneys.length,
                    itemBuilder: (context, index) {
                      final jeepney = _nearbyJeepneys[index];
                      
                      // Debug: Print jeepney data to check for null values
                      print('🔍 JEEPNEY $index: ${jeepney.toString()}');
                      
                      // Ensure all required fields have non-null values
                      final route = jeepney['route']?.toString() ?? 'Unknown Route';
                      final distance = jeepney['distance']?.toString() ?? '0 km';
                      final eta = jeepney['eta']?.toString() ?? '0';
                      final status = jeepney['status']?.toString() ?? 'Available';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.directions_bus,
                                  color: Theme.of(context).primaryColor,
                                  size: 32,
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      route,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$distance away',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '$eta min',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: status == 'Available' ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  Widget _buildNoJeepneysView() {
    return Center(
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
              Icons.directions_bus_filled_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Jeepneys Available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are currently no active jeepneys in your area.',
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
                  _getUserLocation();
                  // _loadNearbyJeepneys(); // Commented out for demo
                  _addMockData(); // Use mock data instead
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.push('/commuter/map'),
                icon: const Icon(Icons.map, size: 16),
                label: const Text('View Map'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Live Map View',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Real-time jeepney locations will be displayed here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/commuter/map'),
            child: const Text('Open Full Map'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Route Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Browse all available jeepney routes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/commuter/routes'),
            child: const Text('View All Routes'),
          ),
        ],
      ),
    );
  }
}
