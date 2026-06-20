import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'api_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  socket_io.Socket? _socket;
  bool _isConnected = false;
  final StreamController<Map<String, dynamic>> _leaveBalanceController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _leaveUpdateController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get leaveBalanceUpdates => _leaveBalanceController.stream;
  Stream<Map<String, dynamic>> get notifications => _notificationController.stream;
  Stream<Map<String, dynamic>> get leaveUpdates => _leaveUpdateController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected && _socket != null) {
      if (kDebugMode) print('WebSocket already connected');
      return;
    }

    try {
      // Get the base URL from API service
      final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
      
      // Get auth token
      final token = await _getAuthToken();
      
      if (token == null) {
        if (kDebugMode) print('No auth token available for WebSocket connection');
        return;
      }

      // Configure socket options
      final options = socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build();

      _socket = socket_io.io(baseUrl, options);

      _socket!.onConnect((_) {
        _isConnected = true;
        if (kDebugMode) print('WebSocket connected successfully');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        if (kDebugMode) print('WebSocket disconnected');
      });

      _socket!.onConnectError((error) {
        _isConnected = false;
        if (kDebugMode) print('WebSocket connection error: $error');
      });

      // Listen for leave balance updates
      _socket!.on('leaveBalanceUpdate', (data) {
        if (kDebugMode) print('Received leave balance update: $data');
        _leaveBalanceController.add(Map<String, dynamic>.from(data));
      });

      // Listen for notifications
      _socket!.on('newNotification', (data) {
        if (kDebugMode) print('Received notification: $data');
        _notificationController.add(Map<String, dynamic>.from(data));
      });

      // Listen for leave updates
      _socket!.on('leaveUpdate', (data) {
        if (kDebugMode) print('Received leave update: $data');
        _leaveUpdateController.add(Map<String, dynamic>.from(data));
      });

      // Handle errors
      _socket!.on('error', (error) {
        if (kDebugMode) print('WebSocket error: $error');
      });

    } catch (e) {
      if (kDebugMode) print('Failed to connect WebSocket: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
    _isConnected = false;
  }

  void requestRealTimeData(String type) {
    if (_socket != null && _isConnected) {
      _socket!.emit('requestRealTimeData', {'type': type});
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      // This should match your token storage implementation
      // You may need to adjust this based on your actual token storage
      final prefs = await ApiService.getStorage();
      return prefs.getString('auth_token');
    } catch (e) {
      if (kDebugMode) print('Failed to get auth token: $e');
      return null;
    }
  }

  void dispose() {
    _leaveBalanceController.close();
    _notificationController.close();
    _leaveUpdateController.close();
    disconnect();
  }
}
