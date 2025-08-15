import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/firebase_realtime_service.dart';

class FirebaseRealtimeProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _activeDrivers = [];
  Map<String, dynamic> _driverStats = {};
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _driversSubscription;

  // Getters
  List<Map<String, dynamic>> get activeDrivers => _activeDrivers;
  Map<String, dynamic> get driverStats => _driverStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalActiveDrivers => _activeDrivers.length;
  
  // Get drivers by route
  List<Map<String, dynamic>> getDriversByRoute(String routeId) {
    return _activeDrivers.where((driver) => 
      driver['routeId'] == routeId).toList();
  }

  // Get available drivers only
  List<Map<String, dynamic>> get availableDrivers {
    return _activeDrivers.where((driver) => 
      driver['isAcceptingPassengers'] == true).toList();
  }

  FirebaseRealtimeProvider() {
    startListening();
  }

  void startListening() {
    _setLoading(true);
    
    try {
      _driversSubscription = FirebaseRealtimeService.getActiveDriversStream().listen(
        (List<Map<String, dynamic>> drivers) {
          _activeDrivers = drivers;
          _updateStats();
          _setLoading(false);
          clearError();
          notifyListeners();
        },
        onError: (error) {
          _setError('Failed to load driver data: $error');
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError('Failed to start listening: $e');
      _setLoading(false);
    }
  }

  void _updateStats() {
    final routeStats = <String, int>{};
    int onlineCount = 0;
    int availableCount = 0;

    for (final driver in _activeDrivers) {
      // Route statistics
      final routeId = driver['routeId'] ?? 'Unknown';
      routeStats[routeId] = (routeStats[routeId] ?? 0) + 1;

      // Status statistics
      if (driver['isOnline'] == true) {
        onlineCount++;
        if (driver['isAcceptingPassengers'] == true) {
          availableCount++;
        }
      }
    }

    _driverStats = {
      'totalDrivers': _activeDrivers.length,
      'onlineCount': onlineCount,
      'availableCount': availableCount,
      'routeStats': routeStats,
      'lastUpdated': DateTime.now(),
    };
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Driver tracking methods
  Future<void> startDriverTracking(String driverId) async {
    try {
      await FirebaseRealtimeService.startDriverTracking(driverId);
    } catch (e) {
      _setError('Failed to start driver tracking: $e');
    }
  }

  Future<void> stopDriverTracking(String driverId) async {
    try {
      await FirebaseRealtimeService.stopDriverTracking(driverId);
    } catch (e) {
      _setError('Failed to stop driver tracking: $e');
    }
  }

  Future<void> updateDriverStatus(String driverId, String status) async {
    try {
      await FirebaseRealtimeService.updateDriverStatus(driverId, status);
    } catch (e) {
      _setError('Failed to update driver status: $e');
    }
  }

  // Trip management methods
  Future<String?> startTrip(String driverId, String routeId) async {
    try {
      return await FirebaseRealtimeService.startTrip(driverId, routeId);
    } catch (e) {
      _setError('Failed to start trip: $e');
      return null;
    }
  }

  Future<void> endTrip(String tripId, String driverId) async {
    try {
      await FirebaseRealtimeService.endTrip(tripId, driverId);
    } catch (e) {
      _setError('Failed to end trip: $e');
    }
  }

  // Search and filter methods
  List<Map<String, dynamic>> searchDrivers(String query) {
    final searchTerm = query.toLowerCase();
    return _activeDrivers.where((driver) {
      final driverName = (driver['driverName'] ?? '').toLowerCase();
      final routeId = (driver['routeId'] ?? '').toLowerCase();
      return driverName.contains(searchTerm) || routeId.contains(searchTerm);
    }).toList();
  }

  List<Map<String, dynamic>> getNearbyDrivers(
    double userLat, 
    double userLng, 
    {double radiusInKm = 5.0}
  ) {
    return _activeDrivers.where((driver) {
      final driverLat = driver['latitude'] as double?;
      final driverLng = driver['longitude'] as double?;
      
      if (driverLat == null || driverLng == null) return false;
      
      // Simple distance calculation (approximate)
      final latDiff = (userLat - driverLat).abs();
      final lngDiff = (userLng - driverLng).abs();
      final distance = (latDiff * latDiff + lngDiff * lngDiff);
      
      // Rough conversion to km (very approximate)
      return distance < (radiusInKm * 0.01); // Simplified for demo
    }).toList();
  }

  void refresh() {
    _driversSubscription?.cancel();
    startListening();
  }

  @override
  void dispose() {
    _driversSubscription?.cancel();
    super.dispose();
  }
}
