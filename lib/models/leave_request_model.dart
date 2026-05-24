enum LeaveType { casual, sick, earned, maternity, paternity, unpaid }

enum LeaveStatus { pending, approved, rejected, cancelled }

class LeaveRequestModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String department;
  final LeaveType type;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final LeaveStatus status;
  final DateTime appliedOn;
  final String? reviewedBy;
  final String? reviewNote;

  const LeaveRequestModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    required this.appliedOn,
    this.reviewedBy,
    this.reviewNote,
  });

  int get daysCount {
    int count = 0;
    DateTime current = fromDate;
    while (!current.isAfter(toDate)) {
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    return count == 0 ? 1 : count;
  }

  String get typeLabel {
    switch (type) {
      case LeaveType.casual:
        return 'Casual Leave';
      case LeaveType.sick:
        return 'Sick Leave';
      case LeaveType.earned:
        return 'Earned Leave';
      case LeaveType.maternity:
        return 'Maternity Leave';
      case LeaveType.paternity:
        return 'Paternity Leave';
      case LeaveType.unpaid:
        return 'Unpaid Leave';
    }
  }

  String get statusLabel {
    switch (status) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.cancelled:
        return 'Cancelled';
    }
  }

  LeaveRequestModel copyWith({
    LeaveStatus? status,
    String? reviewedBy,
    String? reviewNote,
  }) {
    return LeaveRequestModel(
      id: id,
      employeeId: employeeId,
      employeeName: employeeName,
      department: department,
      type: type,
      fromDate: fromDate,
      toDate: toDate,
      reason: reason,
      status: status ?? this.status,
      appliedOn: appliedOn,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNote: reviewNote ?? this.reviewNote,
    );
  }
}
