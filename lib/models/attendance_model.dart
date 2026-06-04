enum AttendanceStatus { present, absent, halfDay, late, holiday, weekend }

class AttendanceModel {
  final String id;
  final String employeeId;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final AttendanceStatus status;
  final bool isOnBreak;
  final DateTime? breakStartTime;
  final Duration totalBreakDuration;
  final double? officeLat;
  final double? officeLon;

  const AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.isOnBreak = false,
    this.breakStartTime,
    this.totalBreakDuration = Duration.zero,
    this.officeLat,
    this.officeLon,
  });

  AttendanceModel copyWith({
    String? id,
    String? employeeId,
    DateTime? date,
    DateTime? checkIn,
    DateTime? checkOut,
    AttendanceStatus? status,
    bool? isOnBreak,
    DateTime? breakStartTime,
    Duration? totalBreakDuration,
    bool clearBreakStartTime = false,
    double? officeLat,
    double? officeLon,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      status: status ?? this.status,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      breakStartTime: clearBreakStartTime ? null : (breakStartTime ?? this.breakStartTime),
      totalBreakDuration: totalBreakDuration ?? this.totalBreakDuration,
      officeLat: officeLat ?? this.officeLat,
      officeLon: officeLon ?? this.officeLon,
    );
  }

  Duration? get workingDuration {
    if (checkIn == null) return null;
    final end = checkOut ?? DateTime.now();
    final gross = end.difference(checkIn!);
    final activeBreak = isOnBreak && breakStartTime != null
        ? DateTime.now().difference(breakStartTime!)
        : Duration.zero;
    final net = gross - totalBreakDuration - activeBreak;
    return net.isNegative ? Duration.zero : net;
  }

  String get breakDurationLabel {
    final activeBreak = isOnBreak && breakStartTime != null
        ? DateTime.now().difference(breakStartTime!)
        : Duration.zero;
    final total = totalBreakDuration + activeBreak;
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
    final wd = workingDuration;
    if (wd == null) return '--';
    if (wd == Duration.zero) return '0s';
    if (wd.inHours == 0) {
      if (wd.inMinutes == 0) {
        return '${wd.inSeconds}s';
      }
      return '${wd.inMinutes}m ${wd.inSeconds.remainder(60)}s';
    }
    return '${wd.inHours}h ${wd.inMinutes.remainder(60)}m';
  }

  String get checkInLabel {
    if (checkIn == null) return '--';
    final h = checkIn!.hour.toString().padLeft(2, '0');
    final m = checkIn!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get checkOutLabel {
    if (checkOut == null) return '--';
    final h = checkOut!.hour.toString().padLeft(2, '0');
    final m = checkOut!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get statusLabel {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.holiday:
        return 'Holiday';
      case AttendanceStatus.weekend:
        return 'Weekend';
    }
  }
}
