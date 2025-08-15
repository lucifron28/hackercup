import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';

class NotificationService {
  static FirebaseMessaging? _firebaseMessaging;
  static final Logger _logger = Logger();

  static Future<void> initialize() async {
    try {
      _firebaseMessaging = FirebaseMessaging.instance;
      
      NotificationSettings settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i('User granted permission for notifications');
      } else {
        _logger.w('User declined or has not accepted notification permissions');
      }

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      String? token = await _firebaseMessaging!.getToken();
      _logger.i('FCM Token: $token');
      
      showNotification(
        title: '🚌 Jeepney Tracker Ready!',
        body: 'Real-time notifications active for SDG 11.2',
      );
      
    } catch (e) {
      _logger.e('Failed to initialize Firebase Messaging: $e');
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    _logger.i('Handling a background message: ${message.messageId}');
    _logger.i('Background message: ${message.notification?.title} - ${message.notification?.body}');
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('Got a message whilst in the foreground!');
    _logger.i('Message data: ${message.data}');

    if (message.notification != null) {
      _logger.i('Foreground notification: ${message.notification!.title} - ${message.notification!.body}');
      // In a production app, you would show a custom notification UI here
    }
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    _logger.i('A new onMessageOpenedApp event was published!');
    // Navigate to specific screen based on message data
    // This will be handled by the app router
  }

  static Future<String?> getFCMToken() async {
    if (_firebaseMessaging == null) return null;
    return await _firebaseMessaging!.getToken();
  }

  static Future<void> subscribeToTopic(String topic) async {
    if (_firebaseMessaging == null) return;
    await _firebaseMessaging!.subscribeToTopic(topic);
    _logger.i('Subscribed to topic: $topic');
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    if (_firebaseMessaging == null) return;
    await _firebaseMessaging!.unsubscribeFromTopic(topic);
    _logger.i('Unsubscribed from topic: $topic');
  }

  // Simplified notification method for demo purposes
  static void showNotification({
    required String title,
    required String body,
    String? payload,
  }) {
    _logger.i('📱 NOTIFICATION: $title - $body');
    // In a production app, this would trigger a local notification
    // For now, we just log it
    print('🔔 JEEPNEY TRACKER NOTIFICATION 🔔');
    print('Title: $title');
    print('Message: $body');
    if (payload != null) print('Payload: $payload');
  }

  // Demo methods for testing notifications
  static void sendJeepneyArrivalNotification(String route, int eta) {
    showNotification(
      title: '🚌 Jeepney Approaching!',
      body: '$route route jeepney arriving in $eta minutes',
      payload: 'route:$route,eta:$eta',
    );
  }

  static void sendEmergencyAlert(String driverName, String location) {
    showNotification(
      title: '🚨 Emergency Alert',
      body: 'Driver $driverName needs assistance at $location',
      payload: 'emergency:$location',
    );
  }

  static void sendRouteUpdate(String route, String status) {
    showNotification(
      title: '📍 Route Update',
      body: '$route route is now $status',
      payload: 'route_update:$route:$status',
    );
  }
}
