import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quickboom_hrm/config/api_config.dart';
import 'package:quickboom_hrm/utils/storage_helper.dart';

class DistanceTrackingService {
  static const String _baseUrl = ApiConfig.baseUrl;
  
  /// Get current distance from office
  static Future<Map<String, dynamic>> getCurrentDistance({
    required double latitude,
    required double longitude,
  }) async {
    final token = await StorageHelper.getToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/api/mobile/distance/current')
          .replace(queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      }),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(response.body);
    return {
      'success': true,
      'data': data['data'],
    };
  }

  /// Get distance tracking history
  static Future<Map<String, dynamic>> getDistanceHistory({
    String? startDate,
    String? endDate,
    int limit = 50,
  }) async {
    final token = await StorageHelper.getToken();

    final queryParams = <String, String>{
      'limit': limit.toString(),
    };

    if (startDate != null) {
      queryParams['startDate'] = startDate;
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate;
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/api/mobile/distance/history')
          .replace(queryParameters: queryParams),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(response.body);
    return {
      'success': true,
      'data': data['data'],
    };
  }

  /// Get office information for distance tracking
  static Future<Map<String, dynamic>> getOfficeInfo() async {
    final token = await StorageHelper.getToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/api/mobile/distance/office-info'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(response.body);
    return {
      'success': true,
      'data': data['data']['office'],
    };
  }
}

/// Distance tracking data models
class DistanceData {
  final double distance;
  final String officeName;
  final String officeAddress;
  final bool isWithinRadius;
  final int officeRadius;
  final Coordinates current;
  final Coordinates office;
  final String message;

  DistanceData({
    required this.distance,
    required this.officeName,
    required this.officeAddress,
    required this.isWithinRadius,
    required this.officeRadius,
    required this.current,
    required this.office,
    required this.message,
  });

  factory DistanceData.fromJson(Map<String, dynamic> json) {
    return DistanceData(
      distance: (json['distance'] ?? 0.0).toDouble(),
      officeName: json['officeName'] ?? '',
      officeAddress: json['officeAddress'] ?? '',
      isWithinRadius: json['isWithinRadius'] ?? false,
      officeRadius: json['officeRadius'] ?? 0,
      current: Coordinates.fromJson(json['coordinates']['current']),
      office: Coordinates.fromJson(json['coordinates']['office']),
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'officeName': officeName,
      'officeAddress': officeAddress,
      'isWithinRadius': isWithinRadius,
      'officeRadius': officeRadius,
      'current': current.toJson(),
      'office': office.toJson(),
      'message': message,
    };
  }
}

class DistanceHistoryRecord {
  final String date;
  final String? checkIn;
  final String? checkOut;
  final double distance;
  final bool isWithinRadius;
  final String locationStatus;
  final String status;

  DistanceHistoryRecord({
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.distance,
    required this.isWithinRadius,
    required this.locationStatus,
    required this.status,
  });

  factory DistanceHistoryRecord.fromJson(Map<String, dynamic> json) {
    return DistanceHistoryRecord(
      date: json['date'] ?? '',
      checkIn: json['checkIn'],
      checkOut: json['checkOut'],
      distance: (json['distance'] ?? 0.0).toDouble(),
      isWithinRadius: json['isWithinRadius'] ?? false,
      locationStatus: json['locationStatus'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class DistanceHistorySummary {
  final int totalRecords;
  final double averageDistance;
  final double withinRadiusPercentage;
  final double farthestDistance;
  final double closestDistance;
  final String officeName;
  final int officeRadius;

  DistanceHistorySummary({
    required this.totalRecords,
    required this.averageDistance,
    required this.withinRadiusPercentage,
    required this.farthestDistance,
    required this.closestDistance,
    required this.officeName,
    required this.officeRadius,
  });

  factory DistanceHistorySummary.fromJson(Map<String, dynamic> json) {
    return DistanceHistorySummary(
      totalRecords: json['totalRecords'] ?? 0,
      averageDistance: (json['averageDistance'] ?? 0.0).toDouble(),
      withinRadiusPercentage: (json['withinRadiusPercentage'] ?? 0.0).toDouble(),
      farthestDistance: (json['farthestDistance'] ?? 0.0).toDouble(),
      closestDistance: (json['closestDistance'] ?? 0.0).toDouble(),
      officeName: json['officeName'] ?? '',
      officeRadius: json['officeRadius'] ?? 0,
    );
  }
}

class OfficeInfo {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int radius;
  final String timezone;
  final Map<String, dynamic>? workingHours;

  OfficeInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.timezone,
    this.workingHours,
  });

  factory OfficeInfo.fromJson(Map<String, dynamic> json) {
    return OfficeInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      radius: json['radius'] ?? 0,
      timezone: json['timezone'] ?? '',
      workingHours: json['workingHours'],
    );
  }
}

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({
    required this.latitude,
    required this.longitude,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
