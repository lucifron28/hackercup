import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'dart:async';

class FirebaseRealtimeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Logger _logger = Logger();
  static StreamSubscription<Position>? _locationSubscription;
  static Timer? _heartbeatTimer;

  /// Start real-time location tracking for driver
  static Future<void> startDriverTracking(String driverId) async {
    try {
      _logger.i('🚗 Starting real-time tracking for driver: $driverId');

      // Create or update driver's live location document
      await _firestore.collection('live_locations').doc(driverId).set({
        'driverId': driverId,
        'isOnline': true,
        'lastUpdated': FieldValue.serverTimestamp(),
        'status': 'available', // available, full, offline
      }, SetOptions(merge: true));

      // Start location updates every 5 seconds
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        _updateDriverLocation(driverId, position);
      });

      // Start heartbeat to keep connection alive
      _startHeartbeat(driverId);

      _logger.i('✅ Real-time tracking started for driver: $driverId');
    } catch (e) {
      _logger.e('❌ Failed to start tracking: $e');
    }
  }

  /// Update driver location in Firestore
  static Future<void> _updateDriverLocation(String driverId, Position position) async {
    try {
      await _firestore.collection('live_locations').doc(driverId).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'heading': position.heading,
        'speed': position.speed,
        'accuracy': position.accuracy,
        'lastUpdated': FieldValue.serverTimestamp(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      _logger.d('📍 Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      _logger.e('❌ Failed to update location: $e');
    }
  }

  /// Update driver status (available/full)
  static Future<void> updateDriverStatus(String driverId, String status) async {
    try {
      final isAccepting = status == 'available';
      
      await _firestore.collection('live_locations').doc(driverId).update({
        'status': status, // available, full, offline
        'isAcceptingPassengers': isAccepting,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _logger.i('✅ Driver status updated to: $status');
    } catch (e) {
      _logger.e('❌ Failed to update status: $e');
    }
  }

  /// Start trip tracking
  static Future<String> startTrip(String driverId, String routeId) async {
    try {
      final tripRef = _firestore.collection('active_trips').doc();
      
      await tripRef.set({
        'tripId': tripRef.id,
        'driverId': driverId,
        'routeId': routeId,
        'status': 'active',
        'startTime': FieldValue.serverTimestamp(),
        'startLocation': null, // Will be updated with first location
        'passengers': 0,
        'isAcceptingPassengers': true,
      });

      // Update driver status and add route information to live_locations
      await _firestore.collection('live_locations').doc(driverId).update({
        'routeId': routeId,
        'tripId': tripRef.id,
        'isAcceptingPassengers': true,
      });
      
      await updateDriverStatus(driverId, 'available');

      _logger.i('🛣️ Trip started: ${tripRef.id}');
      return tripRef.id;
    } catch (e) {
      _logger.e('❌ Failed to start trip: $e');
      rethrow;
    }
  }

  /// End trip tracking
  static Future<void> endTrip(String tripId, String driverId) async {
    try {
      await _firestore.collection('active_trips').doc(tripId).update({
        'status': 'completed',
        'endTime': FieldValue.serverTimestamp(),
      });

      // Update driver status to offline
      await updateDriverStatus(driverId, 'offline');

      _logger.i('✅ Trip ended: $tripId');
    } catch (e) {
      _logger.e('❌ Failed to end trip: $e');
    }
  }

  /// Get real-time locations of all active drivers
  static Stream<List<Map<String, dynamic>>> getActiveDriversStream() {
    return _firestore
        .collection('live_locations')
        .where('isOnline', isEqualTo: true)
        .where('lastUpdated', isGreaterThan: 
          Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: 5))))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Start heartbeat to keep connection alive
  static void _startHeartbeat(String driverId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(minutes: 2), (timer) async {
      try {
        await _firestore.collection('live_locations').doc(driverId).update({
          'heartbeat': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        _logger.w('Heartbeat failed: $e');
      }
    });
  }

  /// Stop real-time tracking
  static Future<void> stopDriverTracking(String driverId) async {
    try {
      // Cancel location subscription
      _locationSubscription?.cancel();
      _locationSubscription = null;

      // Cancel heartbeat
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;

      // Update driver status to offline
      await _firestore.collection('live_locations').doc(driverId).update({
        'isOnline': false,
        'status': 'offline',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _logger.i('🛑 Real-time tracking stopped for driver: $driverId');
    } catch (e) {
      _logger.e('❌ Failed to stop tracking: $e');
    }
  }
}
