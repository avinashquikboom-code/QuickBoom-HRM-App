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
    if (d.isNegative) return '0s';
    if (d.inHours == 0) {
      if (d.inMinutes == 0) {
        return '${d.inSeconds}s';
      }
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
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
