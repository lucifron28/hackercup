// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 's.dart';

// ignore_for_file: type=lint

/// The translations for Tagalog (`tl`).
class STl extends S {
  STl([String locale = 'tl']) : super(locale);

  @override
  String get appTitle => 'Jeepney Tracker';

  @override
  String get login => 'Mag-login';

  @override
  String get logout => 'Mag-logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get register => 'Mag-rehistro';

  @override
  String get forgotPassword => 'Nakalimutan ang password?';

  @override
  String get driverApp => 'Driver App';

  @override
  String get commuterApp => 'Commuter App';

  @override
  String get lguDispatcher => 'LGU Dispatcher';

  @override
  String get startTrip => 'Simulan ang Biyahe';

  @override
  String get endTrip => 'Tapusin ang Biyahe';

  @override
  String get availableSeats => 'Available na Upuan';

  @override
  String get route => 'Ruta';

  @override
  String get earnings => 'Kita';

  @override
  String get totalEarnings => 'Kabuuang Kita';

  @override
  String get dailyEarnings => 'Araw-araw na Kita';

  @override
  String get adRevenue => 'Kita mula sa Ads';

  @override
  String get nearbyJeepneys => 'Malapit na Jeepney';

  @override
  String get routeList => 'Mga Ruta';

  @override
  String get liveMap => 'Live na Mapa';

  @override
  String get eta => 'ETA';

  @override
  String get minutes => 'min';

  @override
  String get arrivalTime => 'Oras ng Pagdating';

  @override
  String get gpsEnabled => 'GPS Enabled';

  @override
  String get gpsDisabled => 'GPS Disabled';

  @override
  String get connectingToServer => 'Kumukonekta sa server...';

  @override
  String get serverConnected => 'Nakakonekta';

  @override
  String get serverDisconnected => 'Hindi nakakonekta';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String smsKeyword(Object route) {
    return 'SMS: JEEP $route';
  }

  @override
  String smsInstructions(Object route) {
    return 'Mag-send ng SMS \'JEEP $route\' para makuha ang susunod na 3 ETA';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Wika';

  @override
  String get notifications => 'Notifications';

  @override
  String get mapStyle => 'Estilo ng Mapa';

  @override
  String get error => 'Error';

  @override
  String get noInternetConnection => 'Walang internet connection';

  @override
  String get locationPermissionDenied => 'Hindi pinahintulutan ang location';

  @override
  String get enableLocationServices => 'Pakibukas ang location services';

  @override
  String get sdgTitle => 'SDG 11.2 - Sustainable Transport';

  @override
  String get sdgDescription =>
      'Pagsusulong ng abot-kayang at accessible na transportasyon para sa lahat';
}
