import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_url.dart';

// ─── Live Tracking State ──────────────────────────────────────────────────────

class LiveTrackingState {
  final bool isTracking;
  final String? activeSessionId;
  final String? trackingPurpose;
  final DateTime? sessionStartTime;
  final List<LocationPoint> locationHistory;
  final Position? currentPosition;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const LiveTrackingState({
    this.isTracking = false,
    this.activeSessionId,
    this.trackingPurpose,
    this.sessionStartTime,
    this.locationHistory = const [],
    this.currentPosition,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  LiveTrackingState copyWith({
    bool? isTracking,
    String? activeSessionId,
    String? trackingPurpose,
    DateTime? sessionStartTime,
    List<LocationPoint>? locationHistory,
    Position? currentPosition,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return LiveTrackingState(
      isTracking: isTracking ?? this.isTracking,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      trackingPurpose: trackingPurpose ?? this.trackingPurpose,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      locationHistory: locationHistory ?? this.locationHistory,
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  Duration get sessionDuration {
    if (sessionStartTime == null) return Duration.zero;
    return DateTime.now().difference(sessionStartTime!);
  }

  double get totalDistance {
    if (locationHistory.length < 2) return 0.0;
    
    double total = 0.0;
    for (int i = 1; i < locationHistory.length; i++) {
      total += _calculateDistance(
        locationHistory[i - 1].latitude,
        locationHistory[i - 1].longitude,
        locationHistory[i].latitude,
        locationHistory[i].longitude,
      );
    }
    return total;
  }

  // Helper method to calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double dLat = (lat2 - lat1) * (math.pi / 180);
    final double dLon = (lon2 - lon1) * (math.pi / 180);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }
}

// ─── Location Point Model ──────────────────────────────────────────────────────

class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final double? altitude;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.speed,
    this.heading,
    this.altitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'altitude': altitude,
    };
  }
}

// ─── Live Tracking ViewModel ────────────────────────────────────────────────────

class LiveTrackingViewModel extends StateNotifier<LiveTrackingState> {
  LiveTrackingViewModel() : super(const LiveTrackingState());

  // Calculate distance between two points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double dLat = (lat2 - lat1) * (math.pi / 180);
    final double dLon = (lon2 - lon1) * (math.pi / 180);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) * math.cos(lat2 * (math.pi / 180)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(errorMessage: 'Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(errorMessage: 'Location permissions are denied.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(errorMessage: 'Location permissions are permanently denied.');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      state = state.copyWith(currentPosition: position);
      return position;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to get location: $e');
      return null;
    }
  }

  // Start tracking session
  Future<bool> startTrackingSession({
    required String purpose,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Get current location
      final position = await getCurrentLocation();
      if (position == null) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      // Start tracking session
      final response = await ApiService.post(AppUrl.trackingStart, {
        'purpose': purpose,
        'notes': notes,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'altitude': position.altitude,
      });

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final session = data['session'];
        state = state.copyWith(
          isTracking: true,
          activeSessionId: session['id'].toString(),
          trackingPurpose: purpose,
          sessionStartTime: DateTime.now(),
          isLoading: false,
          successMessage: 'Tracking session started successfully.',
        );

        // Start location updates
        _startLocationUpdates();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['message'] ?? 'Failed to start tracking.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to start tracking: $e',
      );
      return false;
    }
  }

  // Stop tracking session
  Future<bool> stopTrackingSession() async {
    if (state.activeSessionId == null) {
      state = state.copyWith(errorMessage: 'No active tracking session.');
      return false;
    }

    state = state.copyWith(isLoading: true);

    try {
      final response = await ApiService.post(AppUrl.trackingStop, {
        'sessionId': state.activeSessionId,
      });

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        state = state.copyWith(
          isTracking: false,
          activeSessionId: null,
          trackingPurpose: null,
          sessionStartTime: null,
          isLoading: false,
          successMessage: 'Tracking session stopped successfully.',
        );

        // Stop location updates
        _stopLocationUpdates();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['message'] ?? 'Failed to stop tracking.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to stop tracking: $e',
      );
      return false;
    }
  }

  // Update location
  Future<void> updateLocation() async {
    if (!state.isTracking || state.activeSessionId == null) return;

    try {
      final position = await getCurrentLocation();
      if (position == null) return;

      final locationPoint = LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        speed: position.speed,
        heading: position.heading,
        altitude: position.altitude,
      );

      // Add to location history
      final updatedHistory = [...state.locationHistory, locationPoint];
      state = state.copyWith(locationHistory: updatedHistory);

      // Send location to server
      await ApiService.post(AppUrl.trackingUpdateLocation, {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'altitude': position.altitude,
      });
    } catch (e) {
      debugPrint('Failed to update location: $e');
    }
  }

  // Get active sessions
  Future<void> getActiveSessions() async {
    try {
      final response = await ApiService.get(AppUrl.trackingSessions);
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        // Handle active sessions data
        debugPrint('Active sessions: ${data['sessions']}');
      }
    } catch (e) {
      debugPrint('Failed to get active sessions: $e');
    }
  }

  // Get location history
  Future<void> getLocationHistory({String? sessionId, int limit = 100}) async {
    try {
      String url = AppUrl.trackingHistory;
      if (sessionId != null) {
        url += '?sessionId=$sessionId&limit=$limit';
      } else {
        url += '?limit=$limit';
      }

      final response = await ApiService.get(url);
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        // Handle location history data
        debugPrint('Location history: ${data['history']}');
      }
    } catch (e) {
      debugPrint('Failed to get location history: $e');
    }
  }

  // Get live locations (HR/Admin only)
  Future<void> getLiveLocations() async {
    try {
      final response = await ApiService.get(AppUrl.trackingLive);
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        // Handle live locations data
        debugPrint('Live locations: ${data['locations']}');
      }
    } catch (e) {
      debugPrint('Failed to get live locations: $e');
    }
  }

  // Clear messages
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  // Location update timer
  Timer? _locationTimer;

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      updateLocation();
    });
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }
}

// Provider
final liveTrackingViewModelProvider = StateNotifierProvider<LiveTrackingViewModel, LiveTrackingState>((ref) {
  return LiveTrackingViewModel();
});
