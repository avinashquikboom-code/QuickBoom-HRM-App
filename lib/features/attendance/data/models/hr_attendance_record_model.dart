class HrAttendanceRecord {
  final String id;
  final String date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status;
  final String employeeId;
  final String employeeCode;
  final String employeeName;
  final String designation;
  final String? department;
  final String? officeName;
  final String? shiftName;
  final bool isOnBreak;
  final DateTime? breakStartTime;
  final int totalBreakSeconds;
  final int lateByMinutes;
  final int earlyExitMinutes;
  final String? notes;

  HrAttendanceRecord({
    required this.id,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.designation,
    this.department,
    this.officeName,
    this.shiftName,
    required this.isOnBreak,
    this.breakStartTime,
    required this.totalBreakSeconds,
    this.lateByMinutes = 0,
    this.earlyExitMinutes = 0,
    this.notes,
  });

  factory HrAttendanceRecord.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'] ?? {};
    final office = json['office'] ?? {};
    final dept = json['department'] ?? emp['department'] ?? {};
    final shift = json['shift'] ?? {};

    return HrAttendanceRecord(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      checkIn: json['checkIn'] != null ? DateTime.tryParse(json['checkIn'].toString())?.toLocal() : null,
      checkOut: json['checkOut'] != null ? DateTime.tryParse(json['checkOut'].toString())?.toLocal() : null,
      status: json['status']?.toString() ?? 'PRESENT',
      employeeId: emp['id']?.toString() ?? '',
      employeeCode: emp['employeeCode']?.toString() ?? emp['employeeId']?.toString() ?? '',
      employeeName: '${emp['firstName'] ?? ''} ${emp['lastName'] ?? ''}'.trim(),
      designation: emp['designation']?.toString() ?? 'Employee',
      department: dept['name']?.toString() ?? dept.toString(),
      officeName: office['name']?.toString(),
      shiftName: shift['name']?.toString() ?? json['shiftName']?.toString(),
      isOnBreak: json['isOnBreak'] as bool? ?? false,
      breakStartTime: json['breakStartTime'] != null ? DateTime.tryParse(json['breakStartTime'].toString())?.toLocal() : null,
      totalBreakSeconds: json['totalBreakSeconds'] as int? ?? (json['totalBreakDuration'] as int? ?? 0),
      lateByMinutes: json['lateByMinutes'] as int? ?? 0,
      earlyExitMinutes: json['earlyExitMinutes'] as int? ?? 0,
      notes: json['notes']?.toString() ?? json['remarks']?.toString(),
    );
  }

  String get initials {
    final parts = employeeName.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (employeeName.isNotEmpty) {
      return employeeName.length >= 2
          ? employeeName.substring(0, 2).toUpperCase()
          : employeeName.toUpperCase();
    }
    return 'EE';
  }

  // Get status tag label
  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return 'Present';
      case 'ABSENT':
        return 'Absent';
      case 'LATE':
        return 'Late';
      case 'HALF_DAY':
        return 'Half Day';
      case 'LEAVE':
        return 'Leave';
      case 'HOLIDAY':
        return 'Holiday';
      case 'WEEKEND':
      case 'WEEK_OFF':
        return 'Week Off';
      case 'REMOTE':
        return 'Remote';
      default:
        return status;
    }
  }

  // Dynamic calculations for ticked duration display
  String get breakDurationLabel {
    final activeBreak = isOnBreak && breakStartTime != null
        ? DateTime.now().difference(breakStartTime!)
        : Duration.zero;
    final total = Duration(seconds: totalBreakSeconds) + activeBreak;
    if (total == Duration.zero) return '0s';
    if (total.inHours == 0) {
      if (total.inMinutes == 0) {
        return '${total.inSeconds}s';
      }
      return '${total.inMinutes}m ${total.inSeconds.remainder(60)}s';
    }
    return '${total.inHours}h ${total.inMinutes.remainder(60)}m';
  }

  String get workingHoursLabel {
    if (checkIn == null) return '--';
    final end = checkOut ?? DateTime.now();
    final gross = end.difference(checkIn!);
    final activeBreak = isOnBreak && breakStartTime != null
        ? DateTime.now().difference(breakStartTime!)
        : Duration.zero;
    final net = gross - Duration(seconds: totalBreakSeconds) - activeBreak;
    final finalDuration = net.isNegative ? Duration.zero : net;

    if (finalDuration == Duration.zero) return '0s';
    if (finalDuration.inHours == 0) {
      if (finalDuration.inMinutes == 0) {
        return '${finalDuration.inSeconds}s';
      }
      return '${finalDuration.inMinutes}m ${finalDuration.inSeconds.remainder(60)}s';
    }
    return '${finalDuration.inHours}h ${finalDuration.inMinutes.remainder(60)}m';
  }

  HrAttendanceRecord copyWith({
    String? id,
    String? date,
    DateTime? checkIn,
    DateTime? checkOut,
    String? status,
    String? employeeId,
    String? employeeCode,
    String? employeeName,
    String? designation,
    String? department,
    String? officeName,
    String? shiftName,
    bool? isOnBreak,
    DateTime? breakStartTime,
    int? totalBreakSeconds,
    int? lateByMinutes,
    int? earlyExitMinutes,
    String? notes,
  }) {
    return HrAttendanceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      status: status ?? this.status,
      employeeId: employeeId ?? this.employeeId,
      employeeCode: employeeCode ?? this.employeeCode,
      employeeName: employeeName ?? this.employeeName,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      officeName: officeName ?? this.officeName,
      shiftName: shiftName ?? this.shiftName,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      totalBreakSeconds: totalBreakSeconds ?? this.totalBreakSeconds,
      lateByMinutes: lateByMinutes ?? this.lateByMinutes,
      earlyExitMinutes: earlyExitMinutes ?? this.earlyExitMinutes,
      notes: notes ?? this.notes,
    );
  }
}
