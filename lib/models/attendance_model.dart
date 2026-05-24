enum AttendanceStatus { present, absent, halfDay, late, holiday, weekend }

class AttendanceModel {
  final String id;
  final String employeeId;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final AttendanceStatus status;
  final bool isFingerprintCheckIn;
  final bool isFingerprintCheckOut;
  final bool isOnBreak;
  final DateTime? breakStartTime;
  final Duration totalBreakDuration;

  const AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.isFingerprintCheckIn = false,
    this.isFingerprintCheckOut = false,
    this.isOnBreak = false,
    this.breakStartTime,
    this.totalBreakDuration = Duration.zero,
  });

  AttendanceModel copyWith({
    String? id,
    String? employeeId,
    DateTime? date,
    DateTime? checkIn,
    DateTime? checkOut,
    AttendanceStatus? status,
    bool? isFingerprintCheckIn,
    bool? isFingerprintCheckOut,
    bool? isOnBreak,
    DateTime? breakStartTime,
    Duration? totalBreakDuration,
    bool clearBreakStartTime = false,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      status: status ?? this.status,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      isFingerprintCheckIn: isFingerprintCheckIn ?? this.isFingerprintCheckIn,
      isFingerprintCheckOut: isFingerprintCheckOut ?? this.isFingerprintCheckOut,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      breakStartTime: clearBreakStartTime ? null : (breakStartTime ?? this.breakStartTime),
      totalBreakDuration: totalBreakDuration ?? this.totalBreakDuration,
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
    if (total == Duration.zero) return '0m';
    if (total.inHours == 0) return '${total.inMinutes}m';
    return '${total.inHours}h ${total.inMinutes.remainder(60)}m';
  }

  String get workingHoursLabel {
    final wd = workingDuration;
    if (wd == null) return '--';
    if (wd.inHours == 0) return '${wd.inMinutes}m';
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
