import 'dart:convert';
import 'api_service.dart';
import '../constants/app_url.dart';

class DistanceService {
  /// Get current distance from office (pass lat/lon as query params)
  static Future<Map<String, dynamic>> getCurrentDistance({
    required double latitude,
    required double longitude,
  }) async {
    final path = '${AppUrl.distanceCurrent}?latitude=$latitude&longitude=$longitude';
    final response = await ApiService.get(path);
    final data = jsonDecode(response.body);
    return data['data'];
  }

  /// Get distance tracking history
  static Future<Map<String, dynamic>> getDistanceHistory({
    String? startDate,
    String? endDate,
    int limit = 50,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (startDate != null) query['startDate'] = startDate;
    if (endDate != null) query['endDate'] = endDate;
    final uri = Uri.parse(AppUrl.distanceHistory).replace(queryParameters: query);
    final response = await ApiService.get(uri.toString().replaceFirst(AppUrl.baseUrl, ''));
    final data = jsonDecode(response.body);
    return data['data'];
  }

  /// Get office info
  static Future<Map<String, dynamic>> getOfficeInfo() async {
    final response = await ApiService.get(AppUrl.distanceOfficeInfo);
    final data = jsonDecode(response.body);
    return data['data']['office'];
  }
}

class DistanceData {
  final double distance;
  final String officeName;
  final String officeAddress;
  final bool isWithinRadius;
  final int officeRadius;
  final Map<String, dynamic> current;
  final Map<String, dynamic> office;
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

  factory DistanceData.fromJson(Map<String, dynamic> json) => DistanceData(
        distance: (json['distance'] ?? 0.0).toDouble(),
        officeName: json['officeName'] ?? '',
        officeAddress: json['officeAddress'] ?? '',
        isWithinRadius: json['isWithinRadius'] ?? false,
        officeRadius: json['officeRadius'] ?? 0,
        current: json['coordinates']?['current'] ?? {},
        office: json['coordinates']?['office'] ?? {},
        message: json['message'] ?? '',
      );
}

class OfficeInfo {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int radius;
  final double? idealRadius;

  OfficeInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.idealRadius,
  });

  factory OfficeInfo.fromJson(Map<String, dynamic> json) => OfficeInfo(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        latitude: (json['latitude'] ?? 0.0).toDouble(),
        longitude: (json['longitude'] ?? 0.0).toDouble(),
        radius: json['radius'] ?? 0,
        idealRadius: (json['idealRadius'] as num?)?.toDouble(),
      );
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

  factory DistanceHistoryRecord.fromJson(Map<String, dynamic> json) =>
      DistanceHistoryRecord(
        date: json['date'] ?? '',
        checkIn: json['checkIn'],
        checkOut: json['checkOut'],
        distance: (json['distance'] ?? 0.0).toDouble(),
        isWithinRadius: json['isWithinRadius'] ?? false,
        locationStatus: json['locationStatus'] ?? '',
        status: json['status'] ?? '',
      );
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

  factory DistanceHistorySummary.fromJson(Map<String, dynamic> json) =>
      DistanceHistorySummary(
        totalRecords: json['totalRecords'] ?? 0,
        averageDistance: (json['averageDistance'] ?? 0.0).toDouble(),
        withinRadiusPercentage: (json['withinRadiusPercentage'] ?? 0.0).toDouble(),
        farthestDistance: (json['farthestDistance'] ?? 0.0).toDouble(),
        closestDistance: (json['closestDistance'] ?? 0.0).toDouble(),
        officeName: json['officeName'] ?? '',
        officeRadius: json['officeRadius'] ?? 0,
      );
}
