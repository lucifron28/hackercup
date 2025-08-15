class RouteUtils {
  // Map of route IDs to display names
  static const Map<String, String> _routeNames = {
    'route_divisoria_fairview': 'Divisoria - Fairview',
    'route_cubao_antipolo': 'Cubao - Antipolo',
    'route_quiapo_sta_mesa': 'Quiapo - Sta. Mesa',
    'route_alabang_ayala': 'Alabang - Ayala',
    'route_sm_north_trinoma': 'SM North - Trinoma',
    'route_eastwood_ortigas': 'Eastwood - Ortigas',
    'route_bgc_makati': 'BGC - Makati',
    'route_marikina_pasig': 'Marikina - Pasig',
    'route_quezon_ave_edsa': 'Quezon Ave - EDSA',
    'route_commonwealth_fairview': 'Commonwealth - Fairview',
  };

  /// Convert route ID to display name
  static String getRouteName(String? routeId) {
    if (routeId == null || routeId.isEmpty) {
      return 'Unknown Route';
    }
    
    // Return mapped name or the original routeId if not found
    return _routeNames[routeId] ?? routeId;
  }

  /// Get all available routes
  static List<Map<String, String>> getAllRoutes() {
    return _routeNames.entries
        .map((entry) => {
              'id': entry.key,
              'name': entry.value,
            })
        .toList();
  }

  /// Check if route ID exists
  static bool isValidRoute(String routeId) {
    return _routeNames.containsKey(routeId);
  }

  /// Get route ID from display name
  static String? getRouteId(String displayName) {
    for (var entry in _routeNames.entries) {
      if (entry.value == displayName) {
        return entry.key;
      }
    }
    return null;
  }
}
