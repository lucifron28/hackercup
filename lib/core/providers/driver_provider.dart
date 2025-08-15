import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/firebase_realtime_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';
import '../../../modules/driver/models/trip_model.dart';

enum DriverServiceState {
  idle,
  starting,
  running,
  stopping,
  error,
}

class DriverProvider extends ChangeNotifier {
  static final Logger _logger = Logger();
  
  // User data
  AppUser? _userData;
  AppUser? get userData => _userData;
  
  // Service state
  DriverServiceState _serviceState = DriverServiceState.idle;
  DriverServiceState get serviceState => _serviceState;
  bool get isServiceRunning => _serviceState == DriverServiceState.running;
  
  // Trip state
  bool _isOnTrip = false;
  bool _isAcceptingPassengers = true;
  TripModel? _currentTrip;
  String? _currentTripId;
  
  // Getters
  bool get isOnTrip => _isOnTrip;
  bool get isAcceptingPassengers => _isAcceptingPassengers;
  TripModel? get currentTrip => _currentTrip;
  String? get currentTripId => _currentTripId;
  
  // Distance tracking
  double _totalDistance = 0.0;
  double get totalDistance => _totalDistance;
  
  // Error handling
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Initialize driver service
  Future<void> initialize() async {
    try {
      _logger.i('🚗 Initializing driver service...');
      
      // Get current user data
      _userData = await AuthService.getCurrentUserData();
      
      if (_userData == null) {
        throw Exception('No authenticated user found');
      }
      
      _logger.i('✅ Driver service initialized for: ${_userData!.name}');
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize driver service: $e');
      _logger.e('❌ Failed to initialize driver service: $e');
      rethrow;
    }
  }

  /// Start driver service (location tracking)
  Future<void> startService() async {
    if (_serviceState == DriverServiceState.running) return;
    
    try {
      _serviceState = DriverServiceState.starting;
      notifyListeners();
      
      _logger.i('🚀 Starting driver service...');
      
      if (_userData?.id == null) {
        throw Exception('User ID is null');
      }

      // Check and request location permissions
      await _checkLocationPermissions();

      // Start Firebase real-time tracking
      await FirebaseRealtimeService.startDriverTracking(_userData!.id);
      
      _serviceState = DriverServiceState.running;
      _clearError();
      notifyListeners();
      
      _logger.i('✅ Driver service started successfully');
    } catch (e) {
      _serviceState = DriverServiceState.error;
      _setError('Failed to start driver service: $e');
      _logger.e('❌ Failed to start driver service: $e');
      rethrow;
    }
  }

  /// Stop driver service
  Future<void> stopService() async {
    if (_serviceState == DriverServiceState.idle) return;
    
    try {
      _serviceState = DriverServiceState.stopping;
      notifyListeners();
      
      _logger.i('🛑 Stopping driver service...');

      if (_userData?.id != null) {
        await FirebaseRealtimeService.stopDriverTracking(_userData!.id);
      }

      // End any active trip
      if (_isOnTrip) {
        await endTrip();
      }

      _serviceState = DriverServiceState.idle;
      _clearError();
      notifyListeners();
      
      _logger.i('✅ Driver service stopped');
    } catch (e) {
      _serviceState = DriverServiceState.error;
      _setError('Failed to stop driver service: $e');
      _logger.e('❌ Failed to stop driver service: $e');
      rethrow;
    }
  }

  /// Start trip
  Future<void> startTrip() async {
    if (_isOnTrip || _userData?.id == null) return;

    try {
      _logger.i('🛣️ Starting trip...');

      // Get current location
      final position = await _getCurrentLocation();
      if (position == null) {
        throw Exception('Cannot get current location');
      }

      // Start trip in Firebase
      final tripId = await FirebaseRealtimeService.startTrip(
        _userData!.id, 
        _userData!.email, // Using email as route for now
      );

      // Create local trip model
      _currentTrip = TripModel(
        id: tripId,
        driverId: _userData!.id,
        route: _userData!.email, // Using email as route for now
        startTime: DateTime.now(),
        startLocation: position,
        status: TripStatus.active,
      );

      _currentTripId = tripId;
      _isOnTrip = true;
      _isAcceptingPassengers = true;
      _totalDistance = 0.0;
      
      _clearError();
      notifyListeners();

      _logger.i('✅ Trip started successfully: $tripId');
    } catch (e) {
      _setError('Failed to start trip: $e');
      _logger.e('❌ Failed to start trip: $e');
      rethrow;
    }
  }

  /// End trip
  Future<void> endTrip() async {
    if (_currentTripId == null || _userData?.id == null) return;

    try {
      _logger.i('🏁 Ending trip...');

      // End trip in Firebase
      await FirebaseRealtimeService.endTrip(_currentTripId!, _userData!.id);

      // Update current trip
      if (_currentTrip != null) {
        _currentTrip = _currentTrip!.copyWith(
          status: TripStatus.completed,
          endTime: DateTime.now(),
          endLocation: await _getCurrentLocation(),
          totalDistance: _totalDistance,
        );
      }

      // Reset state
      _isOnTrip = false;
      _isAcceptingPassengers = false;
      _currentTripId = null;
      
      _clearError();
      notifyListeners();

      _logger.i('✅ Trip ended successfully');
    } catch (e) {
      _setError('Failed to end trip: $e');
      _logger.e('❌ Failed to end trip: $e');
      rethrow;
    }
  }

  /// Toggle availability status
  Future<void> toggleAvailability() async {
    if (_userData?.id == null) return;

    try {
      _logger.i('🔄 Toggling availability...');
      
      final newStatus = _isAcceptingPassengers ? 'full' : 'available';
      
      // Update status in Firebase
      await FirebaseRealtimeService.updateDriverStatus(_userData!.id, newStatus);
      
      // Update local state
      _isAcceptingPassengers = !_isAcceptingPassengers;
      _clearError();
      notifyListeners();

      _logger.i('✅ Availability toggled to: $newStatus');
    } catch (e) {
      _setError('Failed to toggle availability: $e');
      _logger.e('❌ Failed to toggle availability: $e');
      rethrow;
    }
  }

  /// Get current location
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

  /// Check location permissions
  Future<void> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
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

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    stopService();
    super.dispose();
  }
}
