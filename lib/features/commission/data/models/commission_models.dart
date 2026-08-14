class DateRange {
  final String? startDate;
  final String? endDate;

  DateRange({this.startDate, this.endDate});

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
    );
  }
}

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

double _parseDouble(dynamic val, [double defaultValue = 0.0]) {
  if (val == null) return defaultValue;
  if (val is num) return val.toDouble();
  if (val is String) {
    final cleaned = val.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? defaultValue;
  }
  return defaultValue;
}

int _parseInt(dynamic val, [int defaultValue = 0]) {
  if (val == null) return defaultValue;
  if (val is num) return val.toInt();
  if (val is String) {
    final cleaned = val.replaceAll(',', '').trim();
    return int.tryParse(cleaned) ?? defaultValue;
  }
  return defaultValue;
}

class ProductItem {
  final String name;
  final int quantity;
  final double price;
  final String? salesmanName;

  double get total => quantity * price;

  ProductItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.salesmanName,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      name: (json['name'] ?? json['productName'] ?? '').toString(),
      quantity: _parseInt(json['quantity'] ?? json['qty'], 1),
      price: _parseDouble(json['price'] ?? json['rate'] ?? json['productNetAmount']),
      salesmanName: json['salesmanName']?.toString() ?? json['employeeName']?.toString(),
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
  final String? customerName;
  final String? customerPhone;
  final double? grossSale;
  final double? discount;
  final double? tax;
  final String? storeName;
  final String? salespersonName;
  final List<ProductItem> products;

  CommissionBill({
    required this.id,
    required this.billId,
    required this.saleAmount,
    required this.commission,
    required this.date,
    required this.status,
    this.description,
    this.customerName,
    this.customerPhone,
    this.grossSale,
    this.discount,
    this.tax,
    this.storeName,
    this.salespersonName,
    required this.products,
  });

  factory CommissionBill.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] ?? json['createdAt'] ?? DateTime.now().toIso8601String();
    var rawProducts = json['products'] as List?;
    List<ProductItem> prodList = rawProducts?.map((p) => ProductItem.fromJson(p)).toList() ?? [];

    return CommissionBill(
      id: (json['id'] ?? '').toString(),
      billId: (json['billId'] ?? json['invoiceNumber'] ?? '').toString(),
      saleAmount: _parseDouble(json['saleAmount'] ?? json['amount']),
      commission: _parseDouble(json['commission'] ?? json['commissionAmount']),
      date: (DateTime.tryParse(rawDate.toString()) ?? DateTime.now()).toLocal(),
      status: (json['status'] ?? 'APPROVED').toString(),
      description: json['description']?.toString() ?? json['notes']?.toString(),
      customerName: json['customerName']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      grossSale: json['grossSale'] != null ? _parseDouble(json['grossSale']) : null,
      discount: json['discount'] != null ? _parseDouble(json['discount']) : null,
      tax: json['tax'] != null ? _parseDouble(json['tax']) : null,
      storeName: json['storeName']?.toString(),
      salespersonName: json['salespersonName']?.toString(),
      products: prodList,
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
  final String? customerName;
  final String? customerPhone;
  final String? paymentMode;
  final String? storeName;
  final double? grossSale;
  final double? discount;
  final double? tax;
  final List<ProductItem> products;

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
    this.customerName,
    this.customerPhone,
    this.paymentMode,
    this.storeName,
    this.grossSale,
    this.discount,
    this.tax,
    required this.products,
  });

  factory CommissionDetail.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] ?? json['createdAt'] ?? DateTime.now().toIso8601String();
    final rawCreated = json['createdAt'] ?? rawDate;
    var rawProducts = json['products'] as List?;
    List<ProductItem> prodList = rawProducts?.map((p) => ProductItem.fromJson(p)).toList() ?? [];

    return CommissionDetail(
      billId: (json['billId'] ?? '').toString(),
      saleAmount: _parseDouble(json['saleAmount'] ?? json['amount']),
      commissionRate: _parseDouble(json['commissionRate'] ?? json['commissionPercent']),
      commissionAmount: _parseDouble(json['commissionAmount'] ?? json['commission']),
      date: (DateTime.tryParse(rawDate.toString()) ?? DateTime.now()).toLocal(),
      status: (json['status'] ?? 'APPROVED').toString(),
      description: json['description']?.toString() ?? json['notes']?.toString(),
      createdAt: (DateTime.tryParse(rawCreated.toString()) ?? DateTime.now()).toLocal(),
      employee: EmployeeInfo.fromJson(json['employee'] ?? {}),
      customerName: json['customerName']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      paymentMode: json['paymentMode']?.toString(),
      storeName: json['storeName']?.toString(),
      grossSale: json['grossSale'] != null ? _parseDouble(json['grossSale']) : null,
      discount: json['discount'] != null ? _parseDouble(json['discount']) : null,
      tax: json['tax'] != null ? _parseDouble(json['tax']) : null,
      products: prodList,
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
