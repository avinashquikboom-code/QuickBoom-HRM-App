import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';

class LocationTrackingService {
  static const String _bufferKey = 'buffered_location_pings';
  static StreamSubscription<Position>? _positionStreamSub;
  static List<dynamic> _offices = [];

  // Initialize and request permissions
  static Future<bool> initialize(BuildContext context) async {
    // 1. Show explanation dialog first before requesting "Always" permission
    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.teal),
            SizedBox(width: 8),
            Text('Location Permission', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'QuickBoom HRM requires background location access to verify geofence boundaries for automatic attendance marking and branch entry/exit alerts. Please choose "Allow all the time" in the system settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (proceed != true) return false;

    // 2. Request Location Permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return false;
    }

    // Request Always Permission specifically for background
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always) {
        // Some systems might not grant "Always" directly, but we proceed
      }
    }

    // 3. Pre-load office geofences
    await _loadOffices();
    return true;
  }

  static Future<void> _loadOffices() async {
    try {
      final response = await ApiService.get(AppUrl.geofenceOffices);
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _offices = data['geofences'] ?? [];
      }
    } catch (_) {}
  }

  // Start background location stream
  static Future<void> startTracking() async {
    if (_positionStreamSub != null) return; // already running

    await _loadOffices();

    // Configure foreground service notifications for Android background capability
    final locationSettings = AppleSettings(
      accuracy: LocationAccuracy.high,
      activityType: ActivityType.fitness,
      distanceFilter: 50,
      pauseLocationUpdatesAutomatically: false,
      showBackgroundLocationIndicator: true,
    );

    final androidSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
      forceLocationManager: false,
      intervalDuration: const Duration(minutes: 5),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "QuickBoom HRM tracks your location for geofencing compliance.",
        notificationTitle: "Background Tracking Active",
      ),
    );

    final settings = kIsWeb ? const LocationSettings() : (defaultTargetPlatform == TargetPlatform.android ? androidSettings : locationSettings);

    _positionStreamSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (Position position) {
        _onLocationUpdate(position);
      },
      onError: (err) {
        debugPrint('Location stream error: $err');
      },
    );
  }

  static void stopTracking() {
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
  }

  static Future<void> _onLocationUpdate(Position position) async {
    final String status = _calculateStatus(position.latitude, position.longitude);
    final DateTime time = position.timestamp;

    try {
      final response = await ApiService.post('/api/mobile/location/ping', {
        'lat': position.latitude,
        'lon': position.longitude,
        'status': status,
        'timestamp': time.toUtc().toIso8601String(),
      });
      final res = jsonDecode(response.body);
      if (res['success'] == true) {
        // Successful ping: check and sync any buffered offline pings
        await syncBufferedPings();
      } else {
        // API error: buffer locally
        await _bufferPing(position.latitude, position.longitude, status, time);
      }
    } catch (_) {
      // Network offline: buffer locally
      await _bufferPing(position.latitude, position.longitude, status, time);
    }
  }

  static String _calculateStatus(double lat, double lon) {
    if (_offices.isEmpty) return 'OUT_OF_BOUNDS';
    for (final office in _offices) {
      final oLat = (office['latitude'] ?? 0.0).toDouble();
      final oLon = (office['longitude'] ?? 0.0).toDouble();
      final radius = (office['maxPunchRadiusMeters'] ?? 50.0).toDouble();
      final dist = Geolocator.distanceBetween(lat, lon, oLat, oLon);
      if (dist <= radius) {
        return 'IN_BOUNDS';
      }
    }
    return 'OUT_OF_BOUNDS';
  }

  static Future<void> _bufferPing(double lat, double lon, String status, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_bufferKey) ?? [];
    final item = jsonEncode({
      'lat': lat,
      'lon': lon,
      'status': status,
      'timestamp': time.toUtc().toIso8601String(),
    });
    list.add(item);
    await prefs.setStringList(_bufferKey, list);
  }

  static Future<void> syncBufferedPings() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList(_bufferKey) ?? [];
    if (list.isEmpty) return;

    final List<String> remaining = [];
    for (final itemStr in list) {
      try {
        final data = jsonDecode(itemStr);
        final response = await ApiService.post('/api/mobile/location/ping', {
          'lat': data['lat'],
          'lon': data['lon'],
          'status': data['status'],
          'timestamp': data['timestamp'],
        });
        final res = jsonDecode(response.body);
        if (res['success'] != true) {
          remaining.add(itemStr);
        }
      } catch (_) {
        remaining.add(itemStr);
      }
    }
    await prefs.setStringList(_bufferKey, remaining);
  }
}

// Simple helper to detect kIsWeb or defaultTargetPlatform
const bool kIsWeb = identical(0, 0.0);
