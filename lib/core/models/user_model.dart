class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String userType;
  final bool? isAnonymous;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.userType,
    this.isAnonymous = false,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      userType: json['userType'] ?? 'commuter',
      isAnonymous: json['isAnonymous'] ?? false,
      createdAt: json['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt,
    };
  }

  bool get isDriver => userType == 'driver';
  bool get isCommuter => userType == 'commuter';

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? userType,
    bool? isAnonymous,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AppUser(id: $id, name: $name, email: $email, userType: $userType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
