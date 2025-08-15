import 'package:geolocator/geolocator.dart';

enum TripStatus {
  idle,
  active,
  completed,
}

class TripModel {
  final String id;
  final String driverId;
  final DateTime startTime;
  final DateTime? endTime;
  final TripStatus status;
  final String route;
  final Position? startLocation;
  final Position? endLocation;
  final double totalDistance;

  const TripModel({
    required this.id,
    required this.driverId,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.route,
    this.startLocation,
    this.endLocation,
    this.totalDistance = 0.0,
  });

  TripModel copyWith({
    String? id,
    String? driverId,
    DateTime? startTime,
    DateTime? endTime,
    TripStatus? status,
    String? route,
    Position? startLocation,
    Position? endLocation,
    double? totalDistance,
  }) {
    return TripModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      route: route ?? this.route,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      totalDistance: totalDistance ?? this.totalDistance,
    );
  }

  Duration get tripDuration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  String get tripDurationFormatted {
    final duration = tripDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
