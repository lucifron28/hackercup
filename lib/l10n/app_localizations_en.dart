// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Jeepney Tracker';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get register => 'Register';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get driverApp => 'Driver App';

  @override
  String get commuterApp => 'Commuter App';

  @override
  String get startTrip => 'Start Trip';

  @override
  String get endTrip => 'End Trip';

  @override
  String get availableSeats => 'Available Seats';

  @override
  String get route => 'Route';

  @override
  String get earnings => 'Earnings';

  @override
  String get totalEarnings => 'Total Earnings';

  @override
  String get dailyEarnings => 'Daily Earnings';

  @override
  String get adRevenue => 'Ad Revenue';

  @override
  String get nearbyJeepneys => 'Nearby Jeepneys';

  @override
  String get routeList => 'Routes';

  @override
  String get liveMap => 'Live Map';

  @override
  String get eta => 'ETA';

  @override
  String get minutes => 'min';

  @override
  String get arrivalTime => 'Arrival Time';

  @override
  String get gpsEnabled => 'GPS Enabled';

  @override
  String get gpsDisabled => 'GPS Disabled';

  @override
  String get connectingToServer => 'Connecting to server...';

  @override
  String get serverConnected => 'Connected';

  @override
  String get serverDisconnected => 'Disconnected';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String smsKeyword(Object route) {
    return 'SMS: JEEP $route';
  }

  @override
  String smsInstructions(Object route) {
    return 'Send SMS \'JEEP $route\' to get next 3 ETAs';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get mapStyle => 'Map Style';

  @override
  String get error => 'Error';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get enableLocationServices => 'Please enable location services';

  @override
  String get sdgTitle => 'SDG 11.2 - Sustainable Transport';

  @override
  String get sdgDescription => 'Advancing affordable and accessible transport for all';
}
