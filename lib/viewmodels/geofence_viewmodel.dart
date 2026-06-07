import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_url.dart';

// ─── Geofence State ──────────────────────────────────────────────────────

class GeofenceState {
  final bool isWithinGeofence;
  final double? distance;
  final String? nearestOffice;
  final int? maxRadius;
  final List<OfficeGeofence> offices;
  final List<OfficeGeofence> nearbyOffices;
  final Position? currentPosition;
  final double? officeLatitude;
  final double? officeLongitude;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const GeofenceState({
    this.isWithinGeofence = false,
    this.distance,
    this.nearestOffice,
    this.maxRadius,
    this.offices = const [],
    this.nearbyOffices = const [],
    this.currentPosition,
    this.officeLatitude,
    this.officeLongitude,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  GeofenceState copyWith({
    bool? isWithinGeofence,
    double? distance,
    String? nearestOffice,
    int? maxRadius,
    List<OfficeGeofence>? offices,
    List<OfficeGeofence>? nearbyOffices,
    Position? currentPosition,
    double? officeLatitude,
    double? officeLongitude,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return GeofenceState(
      isWithinGeofence: isWithinGeofence ?? this.isWithinGeofence,
      distance: distance ?? this.distance,
      nearestOffice: nearestOffice ?? this.nearestOffice,
      maxRadius: maxRadius ?? this.maxRadius,
      offices: offices ?? this.offices,
      nearbyOffices: nearbyOffices ?? this.nearbyOffices,
      currentPosition: currentPosition ?? this.currentPosition,
      officeLatitude: officeLatitude ?? this.officeLatitude,
      officeLongitude: officeLongitude ?? this.officeLongitude,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  String get geofenceStatus {
    if (isWithinGeofence) return 'WITHIN_GEOFENCE';
    if (distance != null && maxRadius != null) {
      if (distance! > maxRadius! * 2) {
        return 'FAR_FROM_OFFICE';
      } else {
        return 'OUTSIDE_GEOFENCE';
      }
    }
    return 'UNKNOWN';
  }
}

// ─── Office Geofence Model ──────────────────────────────────────────────────────

class OfficeGeofence {
  final int id;
  final String name;
  final String? code;
  final String address;
  final double latitude;
  final double longitude;
  final int idealRadiusMeters;
  final int maxPunchRadiusMeters;
  final bool isActive;

  const OfficeGeofence({
    required this.id,
    required this.name,
    this.code,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.idealRadiusMeters,
    required this.maxPunchRadiusMeters,
    required this.isActive,
  });

  factory OfficeGeofence.fromJson(Map<String, dynamic> json) {
    return OfficeGeofence(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'],
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      idealRadiusMeters: json['idealRadiusMeters'] ?? 25,
      maxPunchRadiusMeters: json['maxPunchRadiusMeters'] ?? 50,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'idealRadiusMeters': idealRadiusMeters,
      'maxPunchRadiusMeters': maxPunchRadiusMeters,
      'isActive': isActive,
    };
  }
}

// ─── Geofence ViewModel ──────────────────────────────────────────────────────

class GeofenceViewModel extends StateNotifier<GeofenceState> {
  GeofenceViewModel() : super(const GeofenceState());

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

  // Check geofence status
  Future<bool> checkGeofenceStatus({double? latitude, double? longitude}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      Position? position;
      if (latitude != null && longitude != null) {
        position = Position(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      } else {
        position = await getCurrentLocation();
        if (position == null) {
          state = state.copyWith(isLoading: false);
          return false;
        }
      }

      final response = await ApiService.post(AppUrl.geofenceCheck, {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final result = data['result'];
        final coordinates = result['coordinates'];
        final officeLat = coordinates != null ? coordinates['officeLat']?.toDouble() : null;
        final officeLon = coordinates != null ? coordinates['officeLon']?.toDouble() : null;
        state = state.copyWith(
          isWithinGeofence: result['isWithinGeofence'] ?? false,
          distance: result['distance']?.toDouble(),
          nearestOffice: result['officeName'],
          maxRadius: result['maxRadius'],
          officeLatitude: officeLat,
          officeLongitude: officeLon,
          currentPosition: position,
          isLoading: false,
          successMessage: 'Geofence check completed.',
        );
        return result['isWithinGeofence'] ?? false;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['message'] ?? 'Failed to check geofence.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to check geofence: $e',
      );
      return false;
    }
  }

  // Get all office geofences
  Future<void> getAllOfficeGeofences() async {
    state = state.copyWith(isLoading: true);

    try {
      final response = await ApiService.get(AppUrl.geofenceOffices);
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        final List<OfficeGeofence> offices = (data['geofences'] as List)
            .map((office) => OfficeGeofence.fromJson(office))
            .toList();
        
        state = state.copyWith(
          offices: offices,
          isLoading: false,
          successMessage: 'Office geofences loaded successfully.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['message'] ?? 'Failed to get office geofences.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to get office geofences: $e',
      );
    }
  }

  // Get geofence status from API
  Future<void> getGeofenceStatus({double? latitude, double? longitude}) async {
    state = state.copyWith(isLoading: true);

    try {
      Position? position;
      if (latitude != null && longitude != null) {
        position = Position(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      } else {
        position = await getCurrentLocation();
        if (position == null) {
          state = state.copyWith(isLoading: false);
          return;
        }
      }

      final response = await ApiService.get(
        '${AppUrl.geofenceStatus}?latitude=${position.latitude}&longitude=${position.longitude}'
      );
      
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final result = data['result'];
        state = state.copyWith(
          isWithinGeofence: data['status'] == 'WITHIN_GEOFENCE',
          distance: result['distance']?.toDouble(),
          nearestOffice: result['officeName'],
          maxRadius: result['maxRadius'],
          currentPosition: position,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['message'] ?? 'Failed to get geofence status.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to get geofence status: $e',
      );
    }
  }

  // Get nearby offices
  Future<void> getNearbyOffices({double? latitude, double? longitude, int radius = 5000}) async {
    state = state.copyWith(isLoading: true);

    try {
      Position? position;
      if (latitude != null && longitude != null) {
        position = Position(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      } else {
        position = await getCurrentLocation();
        if (position == null) {
          state = state.copyWith(isLoading: false);
          return;
        }
      }

      final response = await ApiService.get(
        '${AppUrl.geofenceNearby}?latitude=${position.latitude}&longitude=${position.longitude}&radius=$radius'
      );
      
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final List<OfficeGeofence> nearbyOffices = (data['nearbyOffices'] as List)
            .map((office) => OfficeGeofence.fromJson(office))
            .toList();
        
        state = state.copyWith(
          nearbyOffices: nearbyOffices,
          currentPosition: position,
          isLoading: false,
          successMessage: 'Nearby offices loaded successfully.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['message'] ?? 'Failed to get nearby offices.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to get nearby offices: $e',
      );
    }
  }

  // Calculate distance to office
  double calculateDistanceToOffice(OfficeGeofence office) {
    if (state.currentPosition == null) return 0.0;
    
    const double earthRadius = 6371000; // Earth's radius in meters
    final double dLat = (office.latitude - state.currentPosition!.latitude) * (math.pi / 180);
    final double dLon = (office.longitude - state.currentPosition!.longitude) * (math.pi / 180);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(state.currentPosition!.latitude * (math.pi / 180)) *
        math.cos(office.latitude * (math.pi / 180)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  // Clear messages
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  // Refresh all data
  Future<void> refreshAllData() async {
    await Future.wait([
      getAllOfficeGeofences(),
      getGeofenceStatus(),
      getNearbyOffices(),
    ]);
  }
}

// Provider
final geofenceViewModelProvider = StateNotifierProvider<GeofenceViewModel, GeofenceState>((ref) {
  return GeofenceViewModel();
});
