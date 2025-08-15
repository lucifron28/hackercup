import 'dart:async';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'location_service.dart';
import 'realtime_service.dart';
import 'notification_service.dart';

class DriverService {
  static final Logger _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static StreamSubscription<Position>? _locationSubscription;
  static Timer? _locationUpdateTimer;
  static String? _currentTripId;
  static bool _isOnTrip = false;
  static int _availableSeats = 14;

  /// Start driver service (GPS tracking + WebSocket connection)
  static Future<bool> startService() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        _logger.e('No authenticated user found');
        return false;
      }

      // Get driver data
      final driverData = await AuthService.getDriverData(user.uid);
      if (driverData == null) {
        _logger.e('Driver data not found');
        return false;
      }

      _logger.i('Starting driver service for: ${driverData.name}');

      // Initialize location service
      final locationInitialized = await LocationService.initialize();
      if (!locationInitialized) {
        _logger.e('Failed to initialize location service');
        return false;
      }

      // Start location tracking
      final trackingStarted = await LocationService.startLocationTracking();
      if (!trackingStarted) {
        _logger.e('Failed to start location tracking');
        return false;
      }

      // Connect to WebSocket
      await RealtimeService.connect(
        userId: user.uid,
        userType: 'driver',
      );

      // Update driver status to online
      await AuthService.updateDriverOnlineStatus(true);

      // Start listening to location updates
      _startLocationUpdates();

      _logger.i('Driver service started successfully');
      return true;

    } catch (e) {
      _logger.e('Failed to start driver service: $e');
      return false;
    }
  }

  /// Stop driver service
  static Future<void> stopService() async {
    try {
      _logger.i('Stopping driver service');

      // End current trip if active
      if (_isOnTrip && _currentTripId != null) {
        await endTrip();
      }

      // Stop location tracking
      await LocationService.stopLocationTracking();
      
      // Disconnect WebSocket
      await RealtimeService.disconnect();

      // Update driver status to offline
      await AuthService.updateDriverOnlineStatus(false);

      // Cancel subscriptions
      await _locationSubscription?.cancel();
      _locationUpdateTimer?.cancel();
      
      _locationSubscription = null;
      _locationUpdateTimer = null;

      _logger.i('Driver service stopped successfully');

    } catch (e) {
      _logger.e('Error stopping driver service: $e');
    }
  }

  /// Start a new trip
  static Future<String?> startTrip({
    required String routeId,
    int initialAvailableSeats = 14,
  }) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return null;

      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        _logger.e('Cannot start trip - location not available');
        return null;
      }

      // Generate trip ID
      final tripId = _generateTripId();
      
      // Create trip document in Firestore
      await _firestore.collection('trips').doc(tripId).set({
        'id': tripId,
        'driverId': user.uid,
        'routeId': routeId,
        'startTime': FieldValue.serverTimestamp(),
        'status': 'active',
        'availableSeats': initialAvailableSeats,
        'startLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'currentLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update driver's current trip
      await _firestore.collection('drivers').doc(user.uid).update({
        'currentTripId': tripId,
        'isOnTrip': true,
        'availableSeats': initialAvailableSeats,
        'currentLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });

      _currentTripId = tripId;
      _isOnTrip = true;
      _availableSeats = initialAvailableSeats;

      // Send trip start update via WebSocket
      await RealtimeService.sendTripUpdate(
        tripId: tripId,
        status: 'started',
        additionalData: {
          'routeId': routeId,
          'availableSeats': initialAvailableSeats,
          'startLocation': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
        },
      );

      // Send notification
      NotificationService.showNotification(
        title: '🚌 Trip Started',
        body: 'Your jeepney trip has started. Safe travels!',
      );

      _logger.i('Trip started: $tripId');
      return tripId;

    } catch (e) {
      _logger.e('Failed to start trip: $e');
      return null;
    }
  }

  /// End current trip
  static Future<bool> endTrip() async {
    try {
      if (!_isOnTrip || _currentTripId == null) {
        _logger.w('No active trip to end');
        return false;
      }

      final user = AuthService.currentUser;
      if (user == null) return false;

      final position = await LocationService.getCurrentPosition();

      // Update trip document
      await _firestore.collection('trips').doc(_currentTripId!).update({
        'endTime': FieldValue.serverTimestamp(),
        'status': 'completed',
        'endLocation': position != null ? {
          'latitude': position.latitude,
          'longitude': position.longitude,
        } : null,
      });

      // Update driver document
      await _firestore.collection('drivers').doc(user.uid).update({
        'currentTripId': null,
        'isOnTrip': false,
        'totalTrips': FieldValue.increment(1),
      });

      // Send trip end update via WebSocket
      await RealtimeService.sendTripUpdate(
        tripId: _currentTripId!,
        status: 'completed',
      );

      // Send notification
      NotificationService.showNotification(
        title: '🏁 Trip Completed',
        body: 'Your trip has been completed successfully!',
      );

      final completedTripId = _currentTripId;
      _currentTripId = null;
      _isOnTrip = false;
      _availableSeats = 14;

      _logger.i('Trip completed: $completedTripId');
      return true;

    } catch (e) {
      _logger.e('Failed to end trip: $e');
      return false;
    }
  }

  /// Update available seats
  static Future<void> updateAvailableSeats(int seats) async {
    try {
      if (!_isOnTrip || _currentTripId == null) return;

      _availableSeats = seats.clamp(0, 14);

      final user = AuthService.currentUser;
      if (user == null) return;

      // Update in Firestore
      await _firestore.collection('trips').doc(_currentTripId!).update({
        'availableSeats': _availableSeats,
      });

      await _firestore.collection('drivers').doc(user.uid).update({
        'availableSeats': _availableSeats,
      });

      _logger.i('Available seats updated: $_availableSeats');

    } catch (e) {
      _logger.e('Failed to update available seats: $e');
    }
  }

  /// Send emergency alert
  static Future<void> sendEmergencyAlert(String message) async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        _logger.e('Cannot send emergency alert - location not available');
        return;
      }

      await RealtimeService.sendEmergencyAlert(
        position: position,
        message: message,
        tripId: _currentTripId,
      );

      // Also store in Firestore for persistence
      final user = AuthService.currentUser;
      if (user != null) {
        await _firestore.collection('emergency_alerts').add({
          'driverId': user.uid,
          'tripId': _currentTripId,
          'message': message,
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'active',
        });
      }

      // Send push notification to nearby drivers and authorities
      NotificationService.sendEmergencyAlert(
        user?.displayName ?? 'Driver',
        LocationService.formatCoordinates(position),
      );

      _logger.i('Emergency alert sent: $message');

    } catch (e) {
      _logger.e('Failed to send emergency alert: $e');
    }
  }

  /// Get current trip info
  static Map<String, dynamic>? getCurrentTripInfo() {
    if (!_isOnTrip || _currentTripId == null) return null;

    return {
      'tripId': _currentTripId,
      'isOnTrip': _isOnTrip,
      'availableSeats': _availableSeats,
      'lastLocation': LocationService.lastKnownPosition != null
          ? LocationService.formatCoordinates(LocationService.lastKnownPosition!)
          : 'Unknown',
    };
  }

  /// Check if service is running
  static bool get isServiceRunning => 
      LocationService.isTracking && 
      RealtimeService.currentState == WebSocketState.connected;

  /// Start listening to location updates
  static void _startLocationUpdates() {
    _locationSubscription?.cancel();
    
    _locationSubscription = LocationService.locationStream.listen(
      (Position position) async {
        try {
          // Update driver location in Firestore
          final user = AuthService.currentUser;
          if (user != null) {
            await _firestore.collection('drivers').doc(user.uid).update({
              'currentLocation': {
                'latitude': position.latitude,
                'longitude': position.longitude,
                'accuracy': position.accuracy,
                'speed': position.speed,
                'heading': position.heading,
                'timestamp': FieldValue.serverTimestamp(),
              },
              'lastSeen': FieldValue.serverTimestamp(),
            });

            // If on trip, update trip location and send to WebSocket
            if (_isOnTrip && _currentTripId != null) {
              await _firestore.collection('trips').doc(_currentTripId!).update({
                'currentLocation': {
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                },
                'lastUpdate': FieldValue.serverTimestamp(),
              });

              // Send location update via WebSocket
              await RealtimeService.sendLocationUpdate(
                tripId: _currentTripId!,
                position: position,
                availableSeats: _availableSeats,
              );
            }
          }

        } catch (e) {
          _logger.e('Error updating location: $e');
        }
      },
      onError: (error) {
        _logger.e('Location stream error: $error');
      },
    );
  }

  /// Generate unique trip ID
  static String _generateTripId() {
    final userId = AuthService.currentUser?.uid ?? 'unknown';
    final userIdShort = userId.length >= 8 ? userId.substring(0, 8) : userId;
    return 'trip_${DateTime.now().millisecondsSinceEpoch}_$userIdShort';
  }

  /// Get driver statistics
  static Future<Map<String, dynamic>> getDriverStats() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return {};

      final driverDoc = await _firestore.collection('drivers').doc(user.uid).get();
      if (!driverDoc.exists) return {};

      final data = driverDoc.data()!;
      
      // Get trips count for today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final todayTrips = await _firestore
          .collection('trips')
          .where('driverId', isEqualTo: user.uid)
          .where('startTime', isGreaterThanOrEqualTo: startOfDay)
          .get();

      return {
        'totalTrips': data['totalTrips'] ?? 0,
        'rating': data['rating'] ?? 5.0,
        'todayTrips': todayTrips.docs.length,
        'isOnline': data['isOnline'] ?? false,
        'isOnTrip': data['isOnTrip'] ?? false,
        'availableSeats': data['availableSeats'] ?? 14,
      };

    } catch (e) {
      _logger.e('Error getting driver stats: $e');
      return {};
    }
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await stopService();
  }
}
