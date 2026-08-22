class BreakModel {
  final String id;
  final String employeeId;
  final String type; // LUNCH, TEA, PERSONAL, MEETING
  final DateTime startAt;
  final DateTime? endAt;
  final String date;

  const BreakModel({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.startAt,
    this.endAt,
    required this.date,
  });

  factory BreakModel.fromJson(Map<String, dynamic> json) {
    return BreakModel(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'PERSONAL',
      startAt: json['startAt'] != null
          ? DateTime.parse(json['startAt']).toLocal()
          : DateTime.now(),
      endAt: json['endAt'] != null
          ? DateTime.parse(json['endAt']).toLocal()
          : null,
      date: json['date']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'type': type,
      'startAt': startAt.toUtc().toIso8601String(),
      'endAt': endAt?.toUtc().toIso8601String(),
      'date': date,
    };
  }

  Duration get duration {
    final end = endAt ?? DateTime.now();
    return end.difference(startAt);
  }

  String get durationLabel {
    final d = duration;
    if (d.isNegative) return '0 sec';
    final totalSeconds = d.inSeconds;
    if (totalSeconds < 60) {
      return '$totalSeconds sec';
    } else if (totalSeconds < 3600) {
      final mins = totalSeconds ~/ 60;
      final remainderSecs = totalSeconds % 60;
      return '${mins}m ${remainderSecs}s';
    } else {
      final hours = totalSeconds ~/ 3600;
      final mins = (totalSeconds % 3600) ~/ 60;
      final remainderSecs = totalSeconds % 60;
      return '${hours}h ${mins}m ${remainderSecs}s';
    }
  }

  String get typeLabel {
    switch (type.toUpperCase()) {
      case 'LUNCH':
        return 'Lunch Break';
      case 'TEA':
        return 'Tea Break';
      case 'PERSONAL':
        return 'Personal Break';
      case 'MEETING':
        return 'Meeting Break';
      default:
        return '$type Break';
    }
  }
}
