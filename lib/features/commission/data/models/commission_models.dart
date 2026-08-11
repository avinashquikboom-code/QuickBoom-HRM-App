class CommissionSummary {
  final double totalSales;
  final double totalCommissionEarned;
  final double pendingCommission;
  final double approvedCommission;
  final double paidCommission;
  final double commissionRate;
  final int transactionCount;
  final DateRange period;
  // Multi-period breakdown
  final DailyCommission today;
  final WeeklyCommission thisWeek;
  final WeeklyCommission lastWeek;
  final MonthlyCommission thisMonth;
  final MonthlyCommission lastMonth;
  final LifetimeCommission lifetime;
  final LatestSale? latestSale;

  CommissionSummary({
    required this.totalSales,
    required this.totalCommissionEarned,
    required this.pendingCommission,
    required this.approvedCommission,
    required this.paidCommission,
    required this.commissionRate,
    required this.transactionCount,
    required this.period,
    required this.today,
    required this.thisWeek,
    required this.lastWeek,
    required this.thisMonth,
    required this.lastMonth,
    required this.lifetime,
    this.latestSale,
  });

  factory CommissionSummary.fromJson(Map<String, dynamic> json) {
    return CommissionSummary(
      totalSales: (json['totalSales'] ?? 0).toDouble(),
      totalCommissionEarned: (json['totalCommissionEarned'] ?? json['totalCommission'] ?? json['lifetimeCommission'] ?? 0).toDouble(),
      pendingCommission: (json['pendingCommission'] ?? 0).toDouble(),
      approvedCommission: (json['approvedCommission'] ?? 0).toDouble(),
      paidCommission: (json['paidCommission'] ?? 0).toDouble(),
      commissionRate: (json['commissionRate'] ?? 0).toDouble(),
      transactionCount: json['transactionCount'] ?? 0,
      period: DateRange.fromJson(json['period'] ?? {}),
      today:     DailyCommission.fromJson(json['today'] ?? {}),
      thisWeek:  WeeklyCommission.fromJson(json['thisWeek'] ?? {}),
      lastWeek:  WeeklyCommission.fromJson(json['lastWeek'] ?? {}),
      thisMonth: MonthlyCommission.fromJson(json['thisMonth'] ?? json['monthlySummary'] ?? {}),
      lastMonth: MonthlyCommission.fromJson(json['lastMonth'] ?? {}),
      lifetime:  LifetimeCommission.fromJson(json['lifetime'] ?? {}),
      latestSale: json['latestSale'] != null ? LatestSale.fromJson(json['latestSale']) : null,
    );
  }
}

class LatestSale {
  final String billId;
  final String date;
  final String displayDate;
  final String displayTime;
  final double netAmount;
  final double commission;
  final double commissionRate;

  LatestSale({
    required this.billId,
    required this.date,
    required this.displayDate,
    required this.displayTime,
    required this.netAmount,
    required this.commission,
    required this.commissionRate,
  });

  factory LatestSale.fromJson(Map<String, dynamic> json) {
    return LatestSale(
      billId: json['billId'] ?? '',
      date: json['date'] ?? '',
      displayDate: json['displayDate'] ?? '',
      displayTime: json['displayTime'] ?? '',
      netAmount: (json['netAmount'] ?? 0).toDouble(),
      commission: (json['commission'] ?? 0).toDouble(),
      commissionRate: (json['commissionRate'] ?? 0).toDouble(),
    );
  }
}

/// Today's commission — resets at 00:00 IST daily
class DailyCommission {
  final String date;
  final double totalSales;
  final double totalCommission;
  final int billCount;
  final String label;

  DailyCommission({
    required this.date,
    required this.totalSales,
    required this.totalCommission,
    required this.billCount,
    required this.label,
  });

  factory DailyCommission.fromJson(Map<String, dynamic> json) {
    return DailyCommission(
      date: json['date'] ?? '',
      totalSales: (json['totalSales'] ?? 0).toDouble(),
      totalCommission: (json['totalCommission'] ?? 0).toDouble(),
      billCount: json['billCount'] ?? 0,
      label: json['label'] ?? 'Today',
    );
  }
}

/// Weekly commission (this week or last week)
class WeeklyCommission {
  final String from;
  final String to;
  final double totalSales;
  final double totalCommission;
  final int billCount;
  final String label;

  WeeklyCommission({
    required this.from,
    required this.to,
    required this.totalSales,
    required this.totalCommission,
    required this.billCount,
    required this.label,
  });

  factory WeeklyCommission.fromJson(Map<String, dynamic> json) {
    return WeeklyCommission(
      from:            json['from'] ?? '',
      to:              json['to'] ?? '',
      totalSales:      (json['totalSales'] ?? 0).toDouble(),
      totalCommission: (json['totalCommission'] ?? 0).toDouble(),
      billCount:       json['billCount'] ?? 0,
      label:           json['label'] ?? 'This Week',
    );
  }
}

/// Lifetime (all time) commission
class LifetimeCommission {
  final double totalSales;
  final double totalCommission;
  final int billCount;
  final String label;

  LifetimeCommission({
    required this.totalSales,
    required this.totalCommission,
    required this.billCount,
    required this.label,
  });

  factory LifetimeCommission.fromJson(Map<String, dynamic> json) {
    return LifetimeCommission(
      totalSales:      (json['totalSales'] ?? 0).toDouble(),
      totalCommission: (json['totalCommission'] ?? 0).toDouble(),
      billCount:       json['billCount'] ?? 0,
      label:           json['label'] ?? 'All Time',
    );
  }
}


/// This month's commission — aggregated full month
class MonthlyCommission {
  final String month;
  final String monthName;
  final String year;
  final double totalSales;
  final double totalCommission;
  final int billCount;
  final double pendingCommission;
  final double paidCommission;
  final String label;

  MonthlyCommission({
    required this.month,
    required this.monthName,
    required this.year,
    required this.totalSales,
    required this.totalCommission,
    required this.billCount,
    required this.pendingCommission,
    required this.paidCommission,
    required this.label,
  });

  factory MonthlyCommission.fromJson(Map<String, dynamic> json) {
    return MonthlyCommission(
      month: json['month'] ?? '',
      monthName: json['monthName'] ?? json['month'] ?? '',
      year: json['year'] ?? '',
      totalSales: (json['totalSales'] ?? json['totalSalesAmount'] ?? 0).toDouble(),
      totalCommission: (json['totalCommission'] ?? json['totalCommissionEarned'] ?? 0).toDouble(),
      billCount: json['billCount'] ?? json['totalBills'] ?? 0,
      pendingCommission: (json['pendingCommission'] ?? 0).toDouble(),
      paidCommission: (json['paidCommission'] ?? 0).toDouble(),
      label: json['label'] ?? 'This Month',
    );
  }
}

class DateRange {
  final String from;
  final String to;

  DateRange({required this.from, required this.to});

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      from: json['from'] ?? '',
      to: json['to'] ?? '',
    );
  }
}

class CommissionBill {
  final String id;
  final String billId;
  final double saleAmount;
  final double commission;
  final DateTime date;
  final String status;
  final String? description;

  CommissionBill({
    required this.id,
    required this.billId,
    required this.saleAmount,
    required this.commission,
    required this.date,
    required this.status,
    this.description,
  });

  factory CommissionBill.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] ?? json['createdAt'] ?? DateTime.now().toIso8601String();
    return CommissionBill(
      id: (json['id'] ?? '').toString(),
      billId: json['billId'] ?? json['invoiceNumber'] ?? '',
      saleAmount: (json['saleAmount'] ?? json['amount'] ?? 0).toDouble(),
      commission: (json['commission'] ?? json['commissionAmount'] ?? 0).toDouble(),
      date: DateTime.tryParse(rawDate.toString()) ?? DateTime.now(),
      status: json['status'] ?? 'APPROVED',
      description: json['description'] ?? json['notes'],
    );
  }
}

class CommissionDetail {
  final String billId;
  final double saleAmount;
  final double commissionRate;
  final double commissionAmount;
  final DateTime date;
  final String status;
  final String? description;
  final DateTime createdAt;
  final EmployeeInfo employee;

  CommissionDetail({
    required this.billId,
    required this.saleAmount,
    required this.commissionRate,
    required this.commissionAmount,
    required this.date,
    required this.status,
    this.description,
    required this.createdAt,
    required this.employee,
  });

  factory CommissionDetail.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] ?? json['createdAt'] ?? DateTime.now().toIso8601String();
    final rawCreated = json['createdAt'] ?? rawDate;
    return CommissionDetail(
      billId: json['billId'] ?? '',
      saleAmount: (json['saleAmount'] ?? json['amount'] ?? 0).toDouble(),
      commissionRate: (json['commissionRate'] ?? json['commissionPercent'] ?? 0).toDouble(),
      commissionAmount: (json['commissionAmount'] ?? json['commission'] ?? 0).toDouble(),
      date: DateTime.tryParse(rawDate.toString()) ?? DateTime.now(),
      status: json['status'] ?? 'APPROVED',
      description: json['description'] ?? json['notes'],
      createdAt: DateTime.tryParse(rawCreated.toString()) ?? DateTime.now(),
      employee: EmployeeInfo.fromJson(json['employee'] ?? {}),
    );
  }
}

class EmployeeInfo {
  final String name;
  final String code;

  EmployeeInfo({required this.name, required this.code});

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      name: json['name'] ?? json['employeeName'] ?? '',
      code: json['code'] ?? json['employeeCode'] ?? '',
    );
  }
}

class CommissionResponse {
  final List<CommissionBill> bills;
  final Pagination pagination;

  CommissionResponse({
    required this.bills,
    required this.pagination,
  });

  factory CommissionResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['bills'] ?? json['transactions'];
    var billsList = (rawList as List?)?.map((b) => CommissionBill.fromJson(b)).toList() ?? [];
    return CommissionResponse(
      bills: billsList,
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Pagination {
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;

  Pagination({
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 20,
      offset: json['offset'] ?? 0,
      hasMore: json['hasMore'] ?? false,
    );
  }
}
