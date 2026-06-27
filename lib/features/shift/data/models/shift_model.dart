class ShiftModel {
  final String id;
  final String name;
  final String startTime; // "09:00"
  final String endTime; // "18:00"
  final List<String> workingDays; // ["Mon", "Tue", "Wed", "Thu", "Fri"]
  final int graceMinutes;
  final int breakMinutes;
  final String color; // hex color

  const ShiftModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.workingDays,
    this.graceMinutes = 15,
    this.breakMinutes = 60,
    this.color = '#3BA38B',
  });

  String get timingLabel => '$startTime - $endTime';

  String get daysLabel => workingDays.join(', ');

  int get totalHours {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    return (end - start - breakMinutes) ~/ 60;
  }

  int _parseTime(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class EmployeeShiftAssignment {
  final String employeeId;
  final String employeeName;
  final String department;
  final ShiftModel shift;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;

  const EmployeeShiftAssignment({
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.shift,
    required this.effectiveFrom,
    this.effectiveTo,
  });

  bool get isActive =>
      effectiveTo == null || effectiveTo!.isAfter(DateTime.now());
}
