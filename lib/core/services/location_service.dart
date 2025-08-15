import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'dart:async';

class LocationService {
  static final Logger _logger = Logger();
  static StreamSubscription<Position>? _positionStream;
  static Position? _lastKnownPosition;
  static final StreamController<Position> _locationController = 
      StreamController<Position>.broadcast();

  // Stream for location updates
  static Stream<Position> get locationStream => _locationController.stream;

  // Get current location
  static Position? get lastKnownPosition => _lastKnownPosition;

  /// Initialize location service
  static Future<bool> initialize() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Location services are disabled');
        return false;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _logger.w('Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.e('Location permissions are permanently denied');
        return false;
      }

      _logger.i('Location service initialized successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to initialize location service: $e');
      return false;
    }
  }

  /// Get current position once
  static Future<Position?> getCurrentPosition() async {
    try {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when moved 10 meters
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      _lastKnownPosition = position;
      _logger.i('Current position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      _logger.e('Failed to get current position: $e');
      return null;
    }
  }

  /// Start tracking location for drivers
  static Future<bool> startLocationTracking({
    int distanceFilter = 10, // meters
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      if (!await initialize()) {
        return false;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _lastKnownPosition = position;
          _locationController.add(position);
          _logger.i('Location update: ${position.latitude}, ${position.longitude}');
        },
        onError: (error) {
          _logger.e('Location stream error: $error');
        },
      );

      _logger.i('Location tracking started');
      return true;
    } catch (e) {
      _logger.e('Failed to start location tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  static Future<void> stopLocationTracking() async {
    try {
      await _positionStream?.cancel();
      _positionStream = null;
      _logger.i('Location tracking stopped');
    } catch (e) {
      _logger.e('Error stopping location tracking: $e');
    }
  }

  /// Calculate distance between two points
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Calculate ETA based on distance and current speed
  static int calculateETA({
    required double distanceInMeters,
    double? currentSpeedMps, // meters per second
    double averageSpeedKph = 20.0, // default jeepney speed in Manila
  }) {
    double speedMps = currentSpeedMps ?? (averageSpeedKph * 1000 / 3600);
    if (speedMps <= 0) speedMps = averageSpeedKph * 1000 / 3600;
    
    double etaSeconds = distanceInMeters / speedMps;
    return (etaSeconds / 60).ceil(); // Return in minutes
  }

  /// Check if location permissions are granted
  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// Request location permissions
  static Future<bool> requestLocationPermission() async {
    try {
      PermissionStatus status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      _logger.e('Error requesting location permission: $e');
      return false;
    }
  }

  /// Open app settings for manual permission grant
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Get location accuracy text
  static String getAccuracyText(double accuracy) {
    if (accuracy < 5) return 'High';
    if (accuracy < 10) return 'Good';
    if (accuracy < 20) return 'Medium';
    return 'Low';
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await stopLocationTracking();
    await _locationController.close();
  }

  /// Check if currently tracking location
  static bool get isTracking => _positionStream != null;

  /// Format coordinates for display
  static String formatCoordinates(Position position) {
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  /// Convert speed from m/s to km/h
  static double convertSpeedToKmh(double speedMps) {
    return speedMps * 3.6;
  }

  /// Check if position is within Philippines bounds (rough check)
  static bool isInPhilippines(Position position) {
    // Philippines approximate bounds
    const double minLat = 4.0;
    const double maxLat = 21.0;
    const double minLng = 116.0;
    const double maxLng = 127.0;

    return position.latitude >= minLat &&
           position.latitude <= maxLat &&
           position.longitude >= minLng &&
           position.longitude <= maxLng;
  }
}
