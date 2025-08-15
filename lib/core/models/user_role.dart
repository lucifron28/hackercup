enum UserRole {
  driver,
  commuter,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.driver:
        return 'Driver';
      case UserRole.commuter:
        return 'Commuter';
    }
  }
  
  String get description {
    switch (this) {
      case UserRole.driver:
        return 'For jeepney drivers to track routes and manage trips';
      case UserRole.commuter:
        return 'For passengers to find and track jeepneys';
    }
  }
}
