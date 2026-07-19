class ShiftRequestModel {
  final String id;
  final String employeeId;
  final String currentShift;
  final String requestedShift;
  final String reason;
  final String status; // PENDING, APPROVED, REJECTED
  final DateTime createdAt;
  final DateTime? decidedAt;
  final String? decidedBy;

  const ShiftRequestModel({
    required this.id,
    required this.employeeId,
    required this.currentShift,
    required this.requestedShift,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.decidedAt,
    this.decidedBy,
  });

  factory ShiftRequestModel.fromJson(Map<String, dynamic> json) {
    return ShiftRequestModel(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      currentShift: json['currentShift']?.toString() ?? 'None',
      requestedShift: json['requestedShift']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt']).toLocal()
          : DateTime.now(),
      decidedAt: json['decidedAt'] != null
          ? DateTime.parse(json['decidedAt']).toLocal()
          : null,
      decidedBy: json['decidedBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'currentShift': currentShift,
      'requestedShift': requestedShift,
      'reason': reason,
      'status': status,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'decidedAt': decidedAt?.toUtc().toIso8601String(),
      'decidedBy': decidedBy,
    };
  }

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }
}
