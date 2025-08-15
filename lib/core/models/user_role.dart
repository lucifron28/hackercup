enum UserRole {
  driver,
  commuter,
  lgu,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.driver:
        return 'Driver';
      case UserRole.commuter:
        return 'Commuter';
      case UserRole.lgu:
        return 'LGU Dispatcher';
    }
  }
  
  String get description {
    switch (this) {
      case UserRole.driver:
        return 'For jeepney drivers to track routes and manage trips';
      case UserRole.commuter:
        return 'For passengers to find and track jeepneys';
      case UserRole.lgu:
        return 'For LGU dispatchers to monitor fleet operations';
    }
  }
}
