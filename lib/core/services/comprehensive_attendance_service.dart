import 'dart:convert';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';

class ComprehensiveAttendanceService {
  /// Get comprehensive attendance report for a month
  /// Includes half-day/full-day classification, break details, and location tracking
  static Future<Map<String, dynamic>> getComprehensiveReport({
    required int month,
    required int year,
  }) async {
    final uri = Uri.parse(AppUrl.attendanceComprehensiveReport).replace(
      queryParameters: {
        'month': month.toString(),
        'year': year.toString(),
      },
    );
    final response = await ApiService.get(uri.toString().replaceFirst(AppUrl.baseUrl, ''));
    final data = jsonDecode(response.body);
    return data['data'];
  }
}

class ComprehensiveReportSummary {
  final int totalDays;
  final int fullDays;
  final int halfDays;
  final int absentDays;
  final int lateDays;
  final int presentDays;
  final double totalWorkHours;
  final double totalBreakTime;
  final int locationTrackingDays;
  final double locationTrackingPercentage;

  ComprehensiveReportSummary({
    required this.totalDays,
    required this.fullDays,
    required this.halfDays,
    required this.absentDays,
    required this.lateDays,
    required this.presentDays,
    required this.totalWorkHours,
    required this.totalBreakTime,
    required this.locationTrackingDays,
    required this.locationTrackingPercentage,
  });

  factory ComprehensiveReportSummary.fromJson(Map<String, dynamic> json) =>
      ComprehensiveReportSummary(
        totalDays: json['totalDays'] ?? 0,
        fullDays: json['fullDays'] ?? 0,
        halfDays: json['halfDays'] ?? 0,
        absentDays: json['absentDays'] ?? 0,
        lateDays: json['lateDays'] ?? 0,
        presentDays: json['presentDays'] ?? 0,
        totalWorkHours: (json['totalWorkHours'] ?? 0.0).toDouble(),
        totalBreakTime: (json['totalBreakTime'] ?? 0.0).toDouble(),
        locationTrackingDays: json['locationTrackingDays'] ?? 0,
        locationTrackingPercentage: (json['locationTrackingPercentage'] ?? 0.0).toDouble(),
      );
}

class AttendanceRecord {
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final String attendanceType;
  final double workHours;
  final int breakMinutes;
  final bool hasLocation;
  final Map<String, dynamic>? location;

  AttendanceRecord({
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    required this.attendanceType,
    required this.workHours,
    required this.breakMinutes,
    required this.hasLocation,
    this.location,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
        date: json['date'] ?? '',
        checkIn: json['checkIn'],
        checkOut: json['checkOut'],
        status: json['status'] ?? '',
        attendanceType: json['attendanceType'] ?? '',
        workHours: (json['workHours'] ?? 0.0).toDouble(),
        breakMinutes: json['breakMinutes'] ?? 0,
        hasLocation: json['hasLocation'] ?? false,
        location: json['location'],
      );
}

class LocationTracking {
  final String date;
  final double latitude;
  final double longitude;
  final String officeName;
  final int officeRadius;
  final String locationStatus;

  LocationTracking({
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.officeName,
    required this.officeRadius,
    required this.locationStatus,
  });

  factory LocationTracking.fromJson(Map<String, dynamic> json) => LocationTracking(
        date: json['date'] ?? '',
        latitude: (json['latitude'] ?? 0.0).toDouble(),
        longitude: (json['longitude'] ?? 0.0).toDouble(),
        officeName: json['officeName'] ?? '',
        officeRadius: json['officeRadius'] ?? 0,
        locationStatus: json['locationStatus'] ?? '',
      );
}

class BreakDetail {
  final String date;
  final String? breakStartTime;
  final int breakMinutes;
  final String breakType;

  BreakDetail({
    required this.date,
    this.breakStartTime,
    required this.breakMinutes,
    required this.breakType,
  });

  factory BreakDetail.fromJson(Map<String, dynamic> json) => BreakDetail(
        date: json['date'] ?? '',
        breakStartTime: json['breakStartTime'],
        breakMinutes: json['breakMinutes'] ?? 0,
        breakType: json['breakType'] ?? '',
      );
}
