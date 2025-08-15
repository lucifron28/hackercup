import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/firebase_realtime_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';
import '../models/trip_model.dart';

class DriverService extends ChangeNotifier {
  static final Logger _logger = Logger();
  
  AppUser? _userData;
  AppUser? get userData => _userData;
  
  bool _isOnTrip = false;
  bool _isAcceptingPassengers = true;
  bool _isServiceRunning = false;
  TripModel? _currentTrip;
  String? _currentTripId;
  
  bool get isOnTrip => _isOnTrip;
  bool get isAcceptingPassengers => _isAcceptingPassengers;
  bool get isServiceRunning => _isServiceRunning;
  TripModel? get currentTrip => _currentTrip;
  
  double _totalDistance = 0.0;
  double get totalDistance => _totalDistance;

  Future<void> initialize() async {
    try {
      _logger.i('🚗 Initializing driver service...');
      
      _userData = await AuthService.getCurrentUserData();
      
      if (_userData == null) {
        throw Exception('No authenticated user found');
      }
      
      _logger.i('✅ Driver service initialized for: ${_userData!.name}');
      notifyListeners();
    } catch (e) {
      _logger.e('❌ Failed to initialize driver service: $e');
      rethrow;
    }
  }

  Future<void> startService() async {
    try {
      _logger.i('🚀 Starting driver service...');
      
      if (_userData?.id == null) {
        throw Exception('User ID is null');
      }

      await _checkLocationPermissions();

      await FirebaseRealtimeService.startDriverTracking(_userData!.id);
      
      _isServiceRunning = true;
      notifyListeners();
      
      _logger.i('✅ Driver service started successfully');
    } catch (e) {
      _logger.e('❌ Failed to start driver service: $e');
      rethrow;
    }
  }

  Future<void> _checkLocationPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }
  }

  Future<void> startTrip() async {
    if (_userData?.id == null) return;

    try {
      _logger.i('🛣️ Starting trip...');

      _currentTripId = await FirebaseRealtimeService.startTrip(
        _userData!.id, 
        'route_divisoria_fairview'
      );

      _currentTrip = TripModel(
        id: _currentTripId!,
        driverId: _userData!.id,
        startTime: DateTime.now(),
        status: TripStatus.active,
        route: 'Divisoria - Fairview',
        startLocation: await _getCurrentLocation(),
      );

      _isOnTrip = true;
      _isAcceptingPassengers = true;
      _totalDistance = 0.0;
      
      notifyListeners();

      _logger.i('✅ Trip started: $_currentTripId');
    } catch (e) {
      _logger.e('❌ Failed to start trip: $e');
      rethrow;
    }
  }

  Future<void> endTrip() async {
    if (_currentTripId == null || _userData?.id == null) return;

    try {
      _logger.i('🏁 Ending trip...');

      await FirebaseRealtimeService.endTrip(_currentTripId!, _userData!.id);

      if (_currentTrip != null) {
        _currentTrip = _currentTrip!.copyWith(
          status: TripStatus.completed,
          endTime: DateTime.now(),
          endLocation: await _getCurrentLocation(),
          totalDistance: _totalDistance,
        );
      }

      _isOnTrip = false;
      _isAcceptingPassengers = false;
      _currentTripId = null;
      
      notifyListeners();

      _logger.i('✅ Trip ended successfully');
    } catch (e) {
      _logger.e('❌ Failed to end trip: $e');
      rethrow;
    }
  }

  Future<void> toggleAvailability() async {
    if (_userData?.id == null) return;

    try {
      _logger.i('🔄 Toggling availability...');

      final newStatus = _isAcceptingPassengers ? 'full' : 'available';
      
      await FirebaseRealtimeService.updateDriverStatus(_userData!.id, newStatus);
      
      _isAcceptingPassengers = !_isAcceptingPassengers;
      notifyListeners();

      _logger.i('✅ Availability toggled to: $newStatus');
    } catch (e) {
      _logger.e('❌ Failed to toggle availability: $e');
      rethrow;
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      _logger.e('❌ Failed to get current location: $e');
      return null;
    }
  }

  Future<void> stopService() async {
    if (_userData?.id == null) return;

    try {
      _logger.i('🛑 Stopping driver service...');

      if (_isOnTrip && _currentTripId != null) {
        await endTrip();
      }

      await FirebaseRealtimeService.stopDriverTracking(_userData!.id);
      
      _isServiceRunning = false;
      notifyListeners();

      _logger.i('✅ Driver service stopped');
    } catch (e) {
      _logger.e('❌ Failed to stop service: $e');
    }
  }

  void updateTotalDistance(double newDistance) {
    _totalDistance += newDistance;
    notifyListeners();
  }

  @override
  void dispose() {
    stopService();
    super.dispose();
  }
}
