import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';

enum WebSocketState {
  connecting,
  connected,
  disconnected,
  error,
}

class RealtimeService {
  static final Logger _logger = Logger();
  static WebSocketChannel? _channel;
  static Timer? _heartbeatTimer;
  static Timer? _reconnectTimer;
  
  static final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<WebSocketState> _stateController = 
      StreamController<WebSocketState>.broadcast();
  
  static WebSocketState _currentState = WebSocketState.disconnected;
  static String? _driverId;
  static String? _userType;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // Streams for external access
  static Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  static Stream<WebSocketState> get stateStream => _stateController.stream;
  static WebSocketState get currentState => _currentState;

  /// Connect to WebSocket server
  static Future<void> connect({
    required String userId,
    required String userType,
    String? baseUrl,
  }) async {
    _driverId = userId;
    _userType = userType;
    
    // Use hardcoded localhost URL for development
    final wsUrl = baseUrl ?? 'ws://localhost:8000/ws/vehicles?connection_type=$userType&driver_id=$userId';
    
    try {
      _updateState(WebSocketState.connecting);
      _logger.i('Connecting to WebSocket: $wsUrl');
      
      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'Connection': 'Upgrade',
          'Upgrade': 'websocket',
        },
      );

      // Listen to incoming messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
      );

      _updateState(WebSocketState.connected);
      _startHeartbeat();
      _reconnectAttempts = 0;
      
      _logger.i('WebSocket connected successfully');
      
      // Send initial connection message
      await _sendMessage({
        'type': 'connection',
        'userId': userId,
        'userType': userType,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      _logger.e('WebSocket connection error: $e');
      _updateState(WebSocketState.error);
      _scheduleReconnect();
    }
  }

  /// Send location update (for drivers)
  static Future<void> sendLocationUpdate({
    required String tripId,
    required Position position,
    required int availableSeats,
  }) async {
    if (_currentState != WebSocketState.connected) {
      _logger.w('Cannot send location update - WebSocket not connected');
      return;
    }

    try {
      await _sendMessage({
        'type': 'location_update',
        'trip_id': tripId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'available_seats': availableSeats,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      _logger.i('Location update sent: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      _logger.e('Failed to send location update: $e');
    }
  }

  /// Send trip status update
  static Future<void> sendTripUpdate({
    required String tripId,
    required String status, // 'started', 'paused', 'completed'
    Map<String, dynamic>? additionalData,
  }) async {
    if (_currentState != WebSocketState.connected) {
      _logger.w('Cannot send trip update - WebSocket not connected');
      return;
    }

    try {
      final message = {
        'type': 'trip_update',
        'trip_id': tripId,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
        ...?additionalData,
      };

      await _sendMessage(message);
      _logger.i('Trip update sent: $status for trip $tripId');
    } catch (e) {
      _logger.e('Failed to send trip update: $e');
    }
  }

  /// Send emergency alert
  static Future<void> sendEmergencyAlert({
    required Position position,
    required String message,
    String? tripId,
  }) async {
    if (_currentState != WebSocketState.connected) {
      _logger.w('Cannot send emergency alert - WebSocket not connected');
      return;
    }

    try {
      await _sendMessage({
        'type': 'emergency_alert',
        'driver_id': _driverId,
        'trip_id': tripId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      _logger.i('Emergency alert sent');
    } catch (e) {
      _logger.e('Failed to send emergency alert: $e');
    }
  }

  /// Subscribe to route updates (for commuters)
  static Future<void> subscribeToRoute(String routeId) async {
    if (_currentState != WebSocketState.connected) {
      _logger.w('Cannot subscribe to route - WebSocket not connected');
      return;
    }

    try {
      await _sendMessage({
        'type': 'subscribe_route',
        'route_id': routeId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      _logger.i('Subscribed to route: $routeId');
    } catch (e) {
      _logger.e('Failed to subscribe to route: $e');
    }
  }

  /// Unsubscribe from route updates
  static Future<void> unsubscribeFromRoute(String routeId) async {
    if (_currentState != WebSocketState.connected) {
      return;
    }

    try {
      await _sendMessage({
        'type': 'unsubscribe_route',
        'route_id': routeId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      _logger.i('Unsubscribed from route: $routeId');
    } catch (e) {
      _logger.e('Failed to unsubscribe from route: $e');
    }
  }

  /// Disconnect from WebSocket
  static Future<void> disconnect() async {
    try {
      _heartbeatTimer?.cancel();
      _reconnectTimer?.cancel();
      
      if (_currentState == WebSocketState.connected) {
        await _sendMessage({
          'type': 'disconnect',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
      
      await _channel?.sink.close(WebSocketStatus.normalClosure);
      _channel = null;
      
      _updateState(WebSocketState.disconnected);
      _logger.i('WebSocket disconnected');
    } catch (e) {
      _logger.e('Error during WebSocket disconnect: $e');
    }
  }

  /// Send message through WebSocket
  static Future<void> _sendMessage(Map<String, dynamic> message) async {
    if (_channel == null || _currentState != WebSocketState.connected) {
      throw Exception('WebSocket not connected');
    }

    try {
      final jsonMessage = json.encode(message);
      _channel!.sink.add(jsonMessage);
    } catch (e) {
      _logger.e('Failed to send WebSocket message: $e');
      rethrow;
    }
  }

  /// Handle incoming messages
  static void _onMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = json.decode(message);
      _messageController.add(data);
      
      // Handle specific message types
      switch (data['type']) {
        case 'location_update':
          _logger.i('Received location update: ${data['data']}');
          break;
        case 'trip_update':
          _logger.i('Received trip update: ${data['status']}');
          break;
        case 'emergency_alert':
          _logger.w('Received emergency alert: ${data['message']}');
          break;
        case 'heartbeat_response':
          // Server acknowledged heartbeat
          break;
        default:
          _logger.i('Received message: ${data['type']}');
      }
    } catch (e) {
      _logger.e('Error parsing WebSocket message: $e');
    }
  }

  /// Handle WebSocket errors
  static void _onError(error) {
    _logger.e('WebSocket error: $error');
    _updateState(WebSocketState.error);
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  static void _onDisconnected() {
    _logger.w('WebSocket disconnected');
    _updateState(WebSocketState.disconnected);
    _scheduleReconnect();
  }

  /// Update WebSocket state
  static void _updateState(WebSocketState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
      _logger.i('WebSocket state changed to: $newState');
    }
  }

  /// Start heartbeat to keep connection alive
  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) async {
      try {
        await _sendMessage({
          'type': 'heartbeat',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        _logger.e('Heartbeat failed: $e');
        timer.cancel();
      }
    });
  }

  /// Schedule reconnection attempt
  static void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.e('Max reconnection attempts reached');
      return;
    }

    _heartbeatTimer?.cancel();
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () async {
      if (_driverId != null && _userType != null) {
        _reconnectAttempts++;
        _logger.i('Attempting to reconnect... (attempt $_reconnectAttempts)');
        await connect(
          userId: _driverId!,
          userType: _userType!,
        );
      }
    });
  }

  /// Dispose all resources
  static Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    await _messageController.close();
    await _stateController.close();
    await disconnect();
  }

  /// Get connection info
  static Map<String, dynamic> getConnectionInfo() {
    return {
      'state': _currentState.toString(),
      'userId': _driverId,
      'userType': _userType,
      'reconnectAttempts': _reconnectAttempts,
    };
  }
}
