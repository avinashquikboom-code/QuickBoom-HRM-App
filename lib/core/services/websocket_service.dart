import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/services/storage_service.dart';

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
  final StreamController<Map<String, dynamic>> _commissionUpdateController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _permissionUpdateController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get leaveBalanceUpdates => _leaveBalanceController.stream;
  Stream<Map<String, dynamic>> get notifications => _notificationController.stream;
  Stream<Map<String, dynamic>> get leaveUpdates => _leaveUpdateController.stream;
  Stream<Map<String, dynamic>> get commissionUpdates => _commissionUpdateController.stream;
  Stream<Map<String, dynamic>> get permissionUpdates => _permissionUpdateController.stream;

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

      // Listen for commission updates
      _socket!.on('commissionUpdate', (data) {
        if (kDebugMode) print('Received commission update: $data');
        _commissionUpdateController.add(Map<String, dynamic>.from(data));
      });

      // Listen for permission updates
      _socket!.on('permissionUpdate', (data) {
        if (kDebugMode) print('Received permission update: $data');
        _permissionUpdateController.add(Map<String, dynamic>.from(data));
      });

      _socket!.on('permissions_updated', (data) {
        if (kDebugMode) print('Received permissions_updated: $data');
        _permissionUpdateController.add(Map<String, dynamic>.from(data));
      });

      // Handle errors
      _socket!.on('error', (error) {
        if (kDebugMode) print('WebSocket error: $error');
      });

    } catch (e) {
      if (kDebugMode) print('Error initializing WebSocket: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    if (kDebugMode) print('WebSocket disconnected and disposed');
  }

  Future<String?> _getAuthToken() async {
    try {
      final token = await StorageService.getToken();
      return token;
    } catch (e) {
      if (kDebugMode) print('Error getting auth token for WebSocket: $e');
      return null;
    }
  }

  void dispose() {
    disconnect();
    _leaveBalanceController.close();
    _notificationController.close();
    _leaveUpdateController.close();
    _commissionUpdateController.close();
    _permissionUpdateController.close();
  }
}
