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

  const AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.isFingerprintCheckIn = false,
    this.isFingerprintCheckOut = false,
  });

  Duration? get workingDuration {
    if (checkIn == null || checkOut == null) return null;
    return checkOut!.difference(checkIn!);
  }

  String get workingHoursLabel {
    final wd = workingDuration;
    if (wd == null) return '--';
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
