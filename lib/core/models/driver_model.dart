class DriverModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String licenseNumber;
  final String jeepneyPlateNumber;
  final String routeId;
  final bool isActive;
  final bool isOnline;
  final double rating;
  final int totalTrips;
  final DateTime joinedAt;
  final DateTime? lastSeen;
  final DriverLocation? currentLocation;
  final String? currentTripId;
  final int availableSeats;

  DriverModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.licenseNumber,
    required this.jeepneyPlateNumber,
    required this.routeId,
    this.isActive = true,
    this.isOnline = false,
    this.rating = 5.0,
    this.totalTrips = 0,
    required this.joinedAt,
    this.lastSeen,
    this.currentLocation,
    this.currentTripId,
    this.availableSeats = 14, // Standard jeepney capacity
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      jeepneyPlateNumber: json['jeepneyPlateNumber'] ?? '',
      routeId: json['routeId'] ?? '',
      isActive: json['isActive'] ?? true,
      isOnline: json['isOnline'] ?? false,
      rating: (json['rating'] ?? 5.0).toDouble(),
      totalTrips: json['totalTrips'] ?? 0,
      joinedAt: json['joinedAt']?.toDate() ?? DateTime.now(),
      lastSeen: json['lastSeen']?.toDate(),
      currentLocation: json['currentLocation'] != null 
          ? DriverLocation.fromJson(json['currentLocation'])
          : null,
      currentTripId: json['currentTripId'],
      availableSeats: json['availableSeats'] ?? 14,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'jeepneyPlateNumber': jeepneyPlateNumber,
      'routeId': routeId,
      'isActive': isActive,
      'isOnline': isOnline,
      'rating': rating,
      'totalTrips': totalTrips,
      'joinedAt': joinedAt,
      'lastSeen': lastSeen,
      'currentLocation': currentLocation?.toJson(),
      'currentTripId': currentTripId,
      'availableSeats': availableSeats,
    };
  }

  DriverModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? licenseNumber,
    String? jeepneyPlateNumber,
    String? routeId,
    bool? isActive,
    bool? isOnline,
    double? rating,
    int? totalTrips,
    DateTime? joinedAt,
    DateTime? lastSeen,
    DriverLocation? currentLocation,
    String? currentTripId,
    int? availableSeats,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      jeepneyPlateNumber: jeepneyPlateNumber ?? this.jeepneyPlateNumber,
      routeId: routeId ?? this.routeId,
      isActive: isActive ?? this.isActive,
      isOnline: isOnline ?? this.isOnline,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      joinedAt: joinedAt ?? this.joinedAt,
      lastSeen: lastSeen ?? this.lastSeen,
      currentLocation: currentLocation ?? this.currentLocation,
      currentTripId: currentTripId ?? this.currentTripId,
      availableSeats: availableSeats ?? this.availableSeats,
    );
  }

  @override
  String toString() {
    return 'DriverModel(id: $id, name: $name, isOnline: $isOnline)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class DriverLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  DriverLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.speed,
    this.heading,
    required this.timestamp,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      speed: json['speed']?.toDouble(),
      heading: json['heading']?.toDouble(),
      timestamp: json['timestamp']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() {
    return 'DriverLocation(lat: $latitude, lng: $longitude)';
  }
}
