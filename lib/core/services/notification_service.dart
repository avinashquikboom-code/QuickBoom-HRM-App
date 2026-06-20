import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../constants/app_url.dart';
import 'websocket_service.dart';

/// Global notification service for handling push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final WebSocketService _webSocketService = WebSocketService();

  // Notification stream controllers
  static final StreamController<Map<String, dynamic>>
  _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;

  // WebSocket notification subscription
  StreamSubscription<Map<String, dynamic>>? _webSocketSubscription;

  /// Initialize Firebase Messaging and local notifications
  Future<void> initialize() async {
    try {
      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token but don't save to backend yet (will be saved after login / session restore)
      await _getFCMToken(saveToBackend: false);

      // Set up message handlers
      _setupMessageHandlers();

      // Connect to WebSocket for real-time notifications
      await _connectWebSocket();

      debugPrint('✅ Notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize notification service: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notification permissions granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('⚠️ Provisional notification permissions granted');
    } else {
      debugPrint('❌ Notification permissions denied');
    }
  }

  /// Initialize local notifications for foreground messages
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channels
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final channels = [
      AndroidNotificationChannel(
        'leave_notifications',
        'Leave Notifications',
        description: 'Notifications for leave request updates',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'attendance_notifications',
        'Attendance Notifications',
        description: 'Notifications for attendance updates',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'task_notifications',
        'Task Notifications',
        description: 'Notifications for task assignments and updates',
        importance: Importance.low,
      ),
      AndroidNotificationChannel(
        'general_notifications',
        'General Notifications',
        description: 'General system notifications',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  /// Get and save FCM token
  Future<void> _getFCMToken({bool saveToBackend = true}) async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: $token');

      if (token != null) {
        // Save to SharedPreferences
        await StorageService.saveFCMToken(token);
        if (saveToBackend) {
          // Save to backend
          await _saveFCMToken(token);
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
    }
  }

  /// Save FCM token to backend
  Future<void> _saveFCMToken(String token) async {
    try {
      // Check if user is authenticated before saving to backend
      final authToken = await ApiService.getToken();
      if (authToken == null || authToken.isEmpty) {
        debugPrint(
          '⚠️ No auth token available, skipping FCM token save to backend',
        );
        return;
      }

      await ApiService.post(AppUrl.saveFCMToken, {
        'fcmToken': token,
        'platform': Platform.operatingSystem,
      });
      debugPrint('✅ FCM token saved to backend');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token to backend: $e');
    }
  }

  /// Connect to WebSocket for real-time notifications
  Future<void> _connectWebSocket() async {
    try {
      await _webSocketService.connect();

      // Listen for WebSocket notifications
      _webSocketSubscription = _webSocketService.notifications.listen(
        (notificationData) {
          debugPrint('🔔 WebSocket notification received: $notificationData');

          // Show local notification for WebSocket messages
          _showLocalNotification(
            title: notificationData['title'] ?? 'New Notification',
            body: notificationData['message'] ?? notificationData['body'] ?? '',
            data: notificationData,
            channelId: _getNotificationChannel(
              notificationData['type'] ?? 'general',
            ),
          );

          // Add to notification stream for real-time UI updates
          _notificationStreamController.add({
            'type': notificationData['type'] ?? 'general',
            'title': notificationData['title'] ?? 'New Notification',
            'body':
                notificationData['message'] ?? notificationData['body'] ?? '',
            'data': notificationData,
            'source': 'websocket',
          });
        },
        onError: (error) {
          debugPrint('❌ WebSocket notification error: $error');
        },
      );

      debugPrint('✅ WebSocket notifications connected');
    } catch (e) {
      debugPrint('❌ Failed to connect WebSocket notifications: $e');
    }
  }

  /// Set up message handlers for foreground, background, and terminated states
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle messages when app is opened from terminated state
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle FCM token refreshes dynamically
    _firebaseMessaging.onTokenRefresh.listen((token) async {
      debugPrint('🔑 FCM Token Refreshed: $token');
      await StorageService.saveFCMToken(token);
      await _saveFCMToken(token);
    });
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message received: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    // Show local notification for foreground messages
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        data: data,
        channelId: _getNotificationChannel(data['type'] ?? 'general'),
      );
    }

    // Add to notification stream for real-time UI updates
    _notificationStreamController.add({
      'type': data['type'] ?? 'general',
      'title': notification?.title ?? 'New Notification',
      'body': notification?.body ?? '',
      'data': data,
    });
  }

  /// Handle messages when app is opened from background
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('📱 Message opened app: ${message.messageId}');
    _navigateToNotificationScreen(message.data);
  }

  /// Handle background messages (static method required by Firebase)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('📱 Background message received: ${message.messageId}');
    // Handle background message logic here if needed
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String channelId,
  }) async {
    try {
      final channelName = _getChannelName(channelId);
      final channelDescription = _getChannelDescription(channelId);

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: details,
        payload: data.toString(),
      );
    } catch (e) {
      debugPrint('❌ Failed to show local notification: $e');
    }
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'leave_notifications':
        return 'Leave Notifications';
      case 'attendance_notifications':
        return 'Attendance Notifications';
      case 'task_notifications':
        return 'Task Notifications';
      default:
        return 'General Notifications';
    }
  }

  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'leave_notifications':
        return 'Notifications for leave request updates';
      case 'attendance_notifications':
        return 'Notifications for attendance updates';
      case 'task_notifications':
        return 'Notifications for task assignments and updates';
      default:
        return 'General system notifications';
    }
  }

  /// Get notification channel based on message type
  String _getNotificationChannel(String type) {
    switch (type.toLowerCase()) {
      case 'leave_approved':
      case 'leave_rejected':
      case 'leave_request_processed':
        return 'leave_notifications';
      case 'attendance':
        return 'attendance_notifications';
      case 'task':
        return 'task_notifications';
      default:
        return 'general_notifications';
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final data = Map<String, dynamic>.fromEntries(
          // Parse the payload string back to Map
          response.payload!.split(',').map((e) {
            final parts = e.split(':');
            return MapEntry(parts[0].trim(), parts[1].trim());
          }),
        );
        _navigateToNotificationScreen(data);
      } catch (e) {
        debugPrint('❌ Failed to parse notification payload: $e');
      }
    }
  }

  /// Navigate to appropriate screen based on notification data
  void _navigateToNotificationScreen(Map<String, dynamic> data) {
    final type = data['type']?.toString().toLowerCase();

    switch (type) {
      case 'leave_approved':
      case 'leave_rejected':
        // Navigate to leave status screen
        debugPrint('🔗 Navigating to leave status screen');

        break;
      case 'attendance':
        // Navigate to attendance screen
        debugPrint('🔗 Navigating to attendance screen');

        break;
      case 'task':
        // Navigate to tasks screen
        debugPrint('🔗 Navigating to tasks screen');

        break;
      default:
        // Navigate to notifications list
        debugPrint('🔗 Navigating to notifications list');

        break;
    }
  }

  /// Refresh FCM token (call this after login or session restore)
  Future<void> refreshToken() async {
    await _getFCMToken(saveToBackend: true);
  }

  /// Print current FCM token to terminal
  Future<void> printFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: $token');
    } catch (e) {
      debugPrint('❌ Failed to get FCM token: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Test local notification (for debugging)
  Future<void> showTestNotification() async {
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test local notification',
      data: {'type': 'test'},
      channelId: 'general_notifications',
    );
    debugPrint('✅ Test notification triggered');
  }

  /// Dispose resources
  void dispose() {
    _webSocketSubscription?.cancel();
    _webSocketService.dispose();
    _notificationStreamController.close();
  }
}
