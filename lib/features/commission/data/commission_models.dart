// Commission Data Models for Employee Mobile App

class CommissionWallet {
  final double totalCommissionBalance;
  final double currentMonthCommission;
  final double lastMonthCommission;
  final double lifetimeCommission;
  final double pendingCommission;
  final double paidCommission;
  final List<CommissionTransaction> recentTransactions;
  final MonthlyCommissionSummary monthlySummary;
  final CommissionStatistics statistics;

  CommissionWallet({
    required this.totalCommissionBalance,
    required this.currentMonthCommission,
    required this.lastMonthCommission,
    required this.lifetimeCommission,
    required this.pendingCommission,
    required this.paidCommission,
    required this.recentTransactions,
    required this.monthlySummary,
    required this.statistics,
  });

  factory CommissionWallet.fromJson(Map<String, dynamic> json) {
    return CommissionWallet(
      totalCommissionBalance: (json['totalCommissionBalance'] as num?)?.toDouble() ?? 0.0,
      currentMonthCommission: (json['currentMonthCommission'] as num?)?.toDouble() ?? 0.0,
      lastMonthCommission: (json['lastMonthCommission'] as num?)?.toDouble() ?? 0.0,
      lifetimeCommission: (json['lifetimeCommission'] as num?)?.toDouble() ?? 0.0,
      pendingCommission: (json['pendingCommission'] as num?)?.toDouble() ?? 0.0,
      paidCommission: (json['paidCommission'] as num?)?.toDouble() ?? 0.0,
      recentTransactions: (json['recentTransactions'] as List?)
              ?.map((e) => CommissionTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      monthlySummary: MonthlyCommissionSummary.fromJson(
          json['monthlySummary'] as Map<String, dynamic>? ?? {}),
      statistics: CommissionStatistics.fromJson(
          json['statistics'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCommissionBalance': totalCommissionBalance,
      'currentMonthCommission': currentMonthCommission,
      'lastMonthCommission': lastMonthCommission,
      'lifetimeCommission': lifetimeCommission,
      'pendingCommission': pendingCommission,
      'paidCommission': paidCommission,
      'recentTransactions': recentTransactions.map((e) => e.toJson()).toList(),
      'monthlySummary': monthlySummary.toJson(),
      'statistics': statistics.toJson(),
    };
  }
}

class CommissionTransaction {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final double billAmount;
  final double commissionPercentage;
  final double commissionEarned;
  final DateTime generatedDate;
  final DateTime? paymentDate;
  final String status; // Pending, Paid
  final String? remarks;

  CommissionTransaction({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.billAmount,
    required this.commissionPercentage,
    required this.commissionEarned,
    required this.generatedDate,
    this.paymentDate,
    required this.status,
    this.remarks,
  });

  factory CommissionTransaction.fromJson(Map<String, dynamic> json) {
    return CommissionTransaction(
      id: json['id'] as String? ?? '',
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      billAmount: (json['billAmount'] as num?)?.toDouble() ?? 0.0,
      commissionPercentage: (json['commissionPercentage'] as num?)?.toDouble() ?? 0.0,
      commissionEarned: (json['commissionEarned'] as num?)?.toDouble() ?? 0.0,
      generatedDate: DateTime.parse(json['generatedDate'] as String? ?? DateTime.now().toIso8601String()),
      paymentDate: json['paymentDate'] != null ? DateTime.parse(json['paymentDate'] as String) : null,
      status: json['status'] as String? ?? 'Pending',
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'billAmount': billAmount,
      'commissionPercentage': commissionPercentage,
      'commissionEarned': commissionEarned,
      'generatedDate': generatedDate.toIso8601String(),
      'paymentDate': paymentDate?.toIso8601String(),
      'status': status,
      'remarks': remarks,
    };
  }
}

class MonthlyCommissionSummary {
  final String month;
  final String year;
  final double totalBills;
  final double totalSalesAmount;
  final double totalCommissionEarned;
  final double paidCommission;
  final double pendingCommission;

  MonthlyCommissionSummary({
    required this.month,
    required this.year,
    required this.totalBills,
    required this.totalSalesAmount,
    required this.totalCommissionEarned,
    required this.paidCommission,
    required this.pendingCommission,
  });

  factory MonthlyCommissionSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyCommissionSummary(
      month: json['month'] as String? ?? '',
      year: json['year'] as String? ?? '',
      totalBills: (json['totalBills'] as num?)?.toDouble() ?? 0.0,
      totalSalesAmount: (json['totalSalesAmount'] as num?)?.toDouble() ?? 0.0,
      totalCommissionEarned: (json['totalCommissionEarned'] as num?)?.toDouble() ?? 0.0,
      paidCommission: (json['paidCommission'] as num?)?.toDouble() ?? 0.0,
      pendingCommission: (json['pendingCommission'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'year': year,
      'totalBills': totalBills,
      'totalSalesAmount': totalSalesAmount,
      'totalCommissionEarned': totalCommissionEarned,
      'paidCommission': paidCommission,
      'pendingCommission': pendingCommission,
    };
  }
}

class CommissionStatistics {
  final int totalBillsGenerated;
  final double totalSalesAmount;
  final double totalCommissionEarned;
  final double paidCommission;
  final double pendingCommission;
  final double averageCommissionPerBill;
  final int totalCustomers;

  CommissionStatistics({
    required this.totalBillsGenerated,
    required this.totalSalesAmount,
    required this.totalCommissionEarned,
    required this.paidCommission,
    required this.pendingCommission,
    required this.averageCommissionPerBill,
    required this.totalCustomers,
  });

  factory CommissionStatistics.fromJson(Map<String, dynamic> json) {
    return CommissionStatistics(
      totalBillsGenerated: json['totalBillsGenerated'] as int? ?? 0,
      totalSalesAmount: (json['totalSalesAmount'] as num?)?.toDouble() ?? 0.0,
      totalCommissionEarned: (json['totalCommissionEarned'] as num?)?.toDouble() ?? 0.0,
      paidCommission: (json['paidCommission'] as num?)?.toDouble() ?? 0.0,
      pendingCommission: (json['pendingCommission'] as num?)?.toDouble() ?? 0.0,
      averageCommissionPerBill: (json['averageCommissionPerBill'] as num?)?.toDouble() ?? 0.0,
      totalCustomers: json['totalCustomers'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBillsGenerated': totalBillsGenerated,
      'totalSalesAmount': totalSalesAmount,
      'totalCommissionEarned': totalCommissionEarned,
      'paidCommission': paidCommission,
      'pendingCommission': pendingCommission,
      'averageCommissionPerBill': averageCommissionPerBill,
      'totalCustomers': totalCustomers,
    };
  }
}

class CommissionHistory {
  final List<CommissionTransaction> transactions;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  CommissionHistory({
    required this.transactions,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  factory CommissionHistory.fromJson(Map<String, dynamic> json) {
    return CommissionHistory(
      transactions: (json['transactions'] as List?)
              ?.map((e) => CommissionTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactions': transactions.map((e) => e.toJson()).toList(),
      'totalCount': totalCount,
      'currentPage': currentPage,
      'totalPages': totalPages,
    };
  }
}

class CommissionDetails {
  final String employeeName;
  final String employeeId;
  final String designation;
  final CommissionStatistics performanceSummary;
  final List<MonthlyCommissionBreakdown> monthlyBreakdown;
  final List<TopPerformingBill> topPerformingBills;

  CommissionDetails({
    required this.employeeName,
    required this.employeeId,
    required this.designation,
    required this.performanceSummary,
    required this.monthlyBreakdown,
    required this.topPerformingBills,
  });

  factory CommissionDetails.fromJson(Map<String, dynamic> json) {
    return CommissionDetails(
      employeeName: json['employeeName'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      performanceSummary: CommissionStatistics.fromJson(
          json['performanceSummary'] as Map<String, dynamic>? ?? {}),
      monthlyBreakdown: (json['monthlyBreakdown'] as List?)
              ?.map((e) => MonthlyCommissionBreakdown.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topPerformingBills: (json['topPerformingBills'] as List?)
              ?.map((e) => TopPerformingBill.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeName': employeeName,
      'employeeId': employeeId,
      'designation': designation,
      'performanceSummary': performanceSummary.toJson(),
      'monthlyBreakdown': monthlyBreakdown.map((e) => e.toJson()).toList(),
      'topPerformingBills': topPerformingBills.map((e) => e.toJson()).toList(),
    };
  }
}

class MonthlyCommissionBreakdown {
  final String month;
  final String year;
  final double commissionEarned;
  final double salesAmount;
  final int billCount;

  MonthlyCommissionBreakdown({
    required this.month,
    required this.year,
    required this.commissionEarned,
    required this.salesAmount,
    required this.billCount,
  });

  factory MonthlyCommissionBreakdown.fromJson(Map<String, dynamic> json) {
    return MonthlyCommissionBreakdown(
      month: json['month'] as String? ?? '',
      year: json['year'] as String? ?? '',
      commissionEarned: (json['commissionEarned'] as num?)?.toDouble() ?? 0.0,
      salesAmount: (json['salesAmount'] as num?)?.toDouble() ?? 0.0,
      billCount: json['billCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'year': year,
      'commissionEarned': commissionEarned,
      'salesAmount': salesAmount,
      'billCount': billCount,
    };
  }
}

class TopPerformingBill {
  final String invoiceNumber;
  final String customerName;
  final double billAmount;
  final double commissionEarned;
  final DateTime date;

  TopPerformingBill({
    required this.invoiceNumber,
    required this.customerName,
    required this.billAmount,
    required this.commissionEarned,
    required this.date,
  });

  factory TopPerformingBill.fromJson(Map<String, dynamic> json) {
    return TopPerformingBill(
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      billAmount: (json['billAmount'] as num?)?.toDouble() ?? 0.0,
      commissionEarned: (json['commissionEarned'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(json['date'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'billAmount': billAmount,
      'commissionEarned': commissionEarned,
      'date': date.toIso8601String(),
    };
  }
}

class CommissionDashboardWidget {
  final double todayCommission;
  final double currentMonthCommission;
  final double pendingCommission;
  final double lifetimeCommission;

  CommissionDashboardWidget({
    required this.todayCommission,
    required this.currentMonthCommission,
    required this.pendingCommission,
    required this.lifetimeCommission,
  });

  factory CommissionDashboardWidget.fromJson(Map<String, dynamic> json) {
    return CommissionDashboardWidget(
      todayCommission: (json['todayCommission'] as num?)?.toDouble() ?? 0.0,
      currentMonthCommission: (json['currentMonthCommission'] as num?)?.toDouble() ?? 0.0,
      pendingCommission: (json['pendingCommission'] as num?)?.toDouble() ?? 0.0,
      lifetimeCommission: (json['lifetimeCommission'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todayCommission': todayCommission,
      'currentMonthCommission': currentMonthCommission,
      'pendingCommission': pendingCommission,
      'lifetimeCommission': lifetimeCommission,
    };
  }
}

class SalarySlipCommission {
  final int totalBillsGenerated;
  final double totalSalesAmount;
  final double commissionPercentage;
  final double totalCommissionEarned;
  final double paidCommission;
  final double pendingCommission;

  SalarySlipCommission({
    required this.totalBillsGenerated,
    required this.totalSalesAmount,
    required this.commissionPercentage,
    required this.totalCommissionEarned,
    required this.paidCommission,
    required this.pendingCommission,
  });

  factory SalarySlipCommission.fromJson(Map<String, dynamic> json) {
    return SalarySlipCommission(
      totalBillsGenerated: json['totalBillsGenerated'] as int? ?? 0,
      totalSalesAmount: (json['totalSalesAmount'] as num?)?.toDouble() ?? 0.0,
      commissionPercentage: (json['commissionPercentage'] as num?)?.toDouble() ?? 0.0,
      totalCommissionEarned: (json['totalCommissionEarned'] as num?)?.toDouble() ?? 0.0,
      paidCommission: (json['paidCommission'] as num?)?.toDouble() ?? 0.0,
      pendingCommission: (json['pendingCommission'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBillsGenerated': totalBillsGenerated,
      'totalSalesAmount': totalSalesAmount,
      'commissionPercentage': commissionPercentage,
      'totalCommissionEarned': totalCommissionEarned,
      'paidCommission': paidCommission,
      'pendingCommission': pendingCommission,
    };
  }
}
