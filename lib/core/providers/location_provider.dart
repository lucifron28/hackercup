import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

enum LocationState {
  initial,
  loading,
  enabled,
  disabled,
  permissionDenied,
  error,
}

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  LocationState _locationState = LocationState.initial;
  String? _errorMessage;
  bool _isTracking = false;

  // Getters
  Position? get currentPosition => _currentPosition;
  LocationState get locationState => _locationState;
  String? get errorMessage => _errorMessage;
  bool get isTracking => _isTracking;
  bool get hasLocation => _currentPosition != null;
  bool get isLocationEnabled => _locationState == LocationState.enabled;

  LocationProvider() {
    _initializeLocationService();
  }

  Future<void> _initializeLocationService() async {
    _setLocationState(LocationState.loading);
    
    try {
      final initialized = await LocationService.initialize();
      if (initialized) {
        _setLocationState(LocationState.enabled);
        await getCurrentLocation();
      } else {
        _setLocationState(LocationState.disabled);
      }
    } catch (e) {
      _setError('Failed to initialize location service: $e');
    }
  }

  void _setLocationState(LocationState state) {
    _locationState = state;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _locationState = LocationState.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> getCurrentLocation() async {
    try {
      _setLocationState(LocationState.loading);
      clearError();

      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        _currentPosition = position;
        _setLocationState(LocationState.enabled);
        return true;
      } else {
        _setError('Failed to get current location');
        return false;
      }
    } catch (e) {
      _setError('Location error: $e');
      return false;
    }
  }

  Future<bool> startLocationTracking({
    int distanceFilter = 10,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      clearError();
      
      final started = await LocationService.startLocationTracking(
        distanceFilter: distanceFilter,
        accuracy: accuracy,
      );

      if (started) {
        _isTracking = true;
        _setLocationState(LocationState.enabled);
        
        // Listen to location updates
        LocationService.locationStream.listen(
          (Position position) {
            _currentPosition = position;
            notifyListeners();
          },
          onError: (error) {
            _setError('Location tracking error: $error');
            _isTracking = false;
          },
        );
        
        return true;
      } else {
        _setError('Failed to start location tracking');
        return false;
      }
    } catch (e) {
      _setError('Location tracking error: $e');
      return false;
    }
  }

  Future<void> stopLocationTracking() async {
    try {
      await LocationService.stopLocationTracking();
      _isTracking = false;
      notifyListeners();
    } catch (e) {
      _setError('Failed to stop location tracking: $e');
    }
  }

  double? distanceTo(double targetLatitude, double targetLongitude) {
    if (_currentPosition == null) return null;
    
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetLatitude,
      targetLongitude,
    );
  }

  String formatCurrentLocation() {
    if (_currentPosition == null) return 'Location unknown';
    
    return LocationService.formatCoordinates(_currentPosition!);
  }

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}
