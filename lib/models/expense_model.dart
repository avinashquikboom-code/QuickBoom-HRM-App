enum ExpenseCategory { travel, food, accommodation, stationery, medical, other }

enum ExpenseStatus { pending, approved, rejected, reimbursed }

class ExpenseModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String department;
  final ExpenseCategory category;
  final double amount;
  final String description;
  final DateTime date;
  final ExpenseStatus status;
  final DateTime submittedOn;
  final String? reviewedBy;
  final String? reviewNote;
  final bool hasReceipt;

  const ExpenseModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.status,
    required this.submittedOn,
    this.reviewedBy,
    this.reviewNote,
    this.hasReceipt = false,
  });

  String get categoryLabel {
    switch (category) {
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.food:
        return 'Food & Meals';
      case ExpenseCategory.accommodation:
        return 'Accommodation';
      case ExpenseCategory.stationery:
        return 'Stationery';
      case ExpenseCategory.medical:
        return 'Medical';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String get statusLabel {
    switch (status) {
      case ExpenseStatus.pending:
        return 'Pending';
      case ExpenseStatus.approved:
        return 'Approved';
      case ExpenseStatus.rejected:
        return 'Rejected';
      case ExpenseStatus.reimbursed:
        return 'Reimbursed';
    }
  }

  int get daysAgo => DateTime.now().difference(submittedOn).inDays;

  ExpenseModel copyWith({
    ExpenseStatus? status,
    String? reviewedBy,
    String? reviewNote,
  }) {
    return ExpenseModel(
      id: id,
      employeeId: employeeId,
      employeeName: employeeName,
      department: department,
      category: category,
      amount: amount,
      description: description,
      date: date,
      status: status ?? this.status,
      submittedOn: submittedOn,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNote: reviewNote ?? this.reviewNote,
      hasReceipt: hasReceipt,
    );
  }
}
