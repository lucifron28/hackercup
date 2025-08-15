import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'auth_service.dart';

class FirebaseRealtimeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Logger _logger = Logger();
  static StreamSubscription<Position>? _locationSubscription;
  static Timer? _heartbeatTimer;

  /// Start real-time location tracking for driver
  static Future<void> startDriverTracking(String driverId) async {
    try {
      _logger.i('🚗 Starting real-time tracking for driver: $driverId');

      // Verify user is authenticated
      final currentUser = await AuthService.getCurrentUserData();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('🔐 DRIVER: Authenticated as ${currentUser.email} (${currentUser.id})');

      // Create or update driver's live location document
      await _firestore.collection('live_locations').doc(driverId).set({
        'driverId': driverId,
        'driverName': currentUser.name,
        'driverEmail': currentUser.email,
        'isOnline': true,
        'lastUpdated': FieldValue.serverTimestamp(),
        'status': 'available', // available, full, offline
        'deviceInfo': 'mobile', // Add device identifier
      }, SetOptions(merge: true));

      print('✅ DRIVER: Created live_locations document for $driverId');

      // Start location updates every 5 seconds
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        print('📍 DRIVER: New position - Lat: ${position.latitude}, Lng: ${position.longitude}');
        _updateDriverLocation(driverId, position);
      });

      // Start heartbeat to keep connection alive
      _startHeartbeat(driverId);

      _logger.i('✅ Real-time tracking started for driver: $driverId');
    } catch (e) {
      _logger.e('❌ Failed to start tracking: $e');
      print('❌ DRIVER: Failed to start tracking: $e');
      rethrow;
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
      print('🔄 STATUS: Updating driver $driverId status to: $status');
      
      final isAccepting = status == 'available';
      
      final updateData = {
        'status': status, // available, full, offline
        'isAcceptingPassengers': isAccepting,
        'lastUpdated': FieldValue.serverTimestamp(),
        'statusUpdateTime': DateTime.now().millisecondsSinceEpoch,
      };

      print('📦 STATUS: Update data: $updateData');
      
      await _firestore.collection('live_locations').doc(driverId).update(updateData);

      print('✅ STATUS: Driver status successfully updated to: $status');
      _logger.i('✅ Driver status updated to: $status');
    } catch (e) {
      print('❌ STATUS: Failed to update status: $e');
      _logger.e('❌ Failed to update status: $e');
      rethrow; // Re-throw to let calling code handle the error
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
      print('🏁 TRIP: Starting to end trip: $tripId');
      
      // Get the active trip data
      final tripDoc = await _firestore.collection('active_trips').doc(tripId).get();
      if (!tripDoc.exists) {
        print('❌ TRIP: Active trip not found: $tripId');
        throw Exception('Trip not found');
      }

      final tripData = tripDoc.data()!;
      print('📄 TRIP: Retrieved trip data for: $tripId');

      // Update trip with completion info
      final completedTripData = {
        ...tripData,
        'status': 'completed',
        'endTime': FieldValue.serverTimestamp(),
        'completedAt': DateTime.now().toIso8601String(),
      };

      // Move to trip_history
      await _firestore.collection('trip_history').doc(tripId).set(completedTripData);
      print('✅ TRIP: Moved trip to history: $tripId');

      // Remove from active_trips
      await _firestore.collection('active_trips').doc(tripId).delete();
      print('✅ TRIP: Removed from active trips: $tripId');

      // IMPORTANT: Set driver to OFFLINE after ending trip
      await _firestore.collection('live_locations').doc(driverId).update({
        'isOnline': false,
        'status': 'offline',
        'isAcceptingPassengers': false,
        'lastUpdated': FieldValue.serverTimestamp(),
        'tripEndTime': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ TRIP: Driver set to OFFLINE - no longer tracking location');

      // Stop heartbeat timer
      _heartbeatTimer?.cancel();
      print('✅ TRIP: Heartbeat timer stopped');

      _logger.i('✅ Trip ended successfully: $tripId');
    } catch (e) {
      print('❌ TRIP: Failed to end trip $tripId: $e');
      _logger.e('❌ Failed to end trip: $e');
      rethrow;
    }
  }

  /// Get real-time locations of all active drivers
  static Stream<List<Map<String, dynamic>>> getActiveDriversStream() {
    print('📡 QUERY: Starting active drivers stream (public access)...');
    
    return _firestore
        .collection('live_locations')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      print('📡 QUERY: Received ${snapshot.docs.length} documents');
      
      final drivers = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        print('📄 DOC: ${doc.id} - Online: ${data['isOnline']}, Lat: ${data['latitude']}, Lng: ${data['longitude']}');
        return data;
      }).toList();
      
      print('📦 QUERY: Returning ${drivers.length} active drivers');
      return drivers;
    }).handleError((error) {
      print('❌ QUERY: Stream error: $error');
      _logger.e('Stream error: $error');
      throw error;
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
