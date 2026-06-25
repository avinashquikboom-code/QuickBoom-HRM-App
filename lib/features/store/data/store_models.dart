// Store Data Models for Retail Business Hierarchy

class Store {
  final String id;
  final String storeCode;
  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String phone;
  final String email;
  final String managerId;
  final String managerName;
  final String? geofenceLatitude;
  final String? geofenceLongitude;
  final double? geofenceRadius;
  final String status; // active, inactive
  final DateTime createdAt;
  final DateTime? updatedAt;

  Store({
    required this.id,
    required this.storeCode,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
    required this.email,
    required this.managerId,
    required this.managerName,
    this.geofenceLatitude,
    this.geofenceLongitude,
    this.geofenceRadius,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String? ?? '',
      storeCode: json['storeCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      managerId: json['managerId'] as String? ?? '',
      managerName: json['managerName'] as String? ?? '',
      geofenceLatitude: json['geofenceLatitude'] as String?,
      geofenceLongitude: json['geofenceLongitude'] as String?,
      geofenceRadius: (json['geofenceRadius'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeCode': storeCode,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phone': phone,
      'email': email,
      'managerId': managerId,
      'managerName': managerName,
      'geofenceLatitude': geofenceLatitude,
      'geofenceLongitude': geofenceLongitude,
      'geofenceRadius': geofenceRadius,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class StoreDashboard {
  final String storeId;
  final String storeName;
  final double todaySales;
  final double todayRevenue;
  final int presentEmployees;
  final int absentEmployees;
  final int lateEmployees;
  final int totalEmployees;
  final int pendingLeaves;
  final int pendingExpenses;
  final double storePerformance; // percentage
  final double monthlySales;
  final double monthlyRevenue;
  final List<StoreSalesSummary> dailySalesSummary;
  final List<StoreAttendanceSummary> attendanceSummary;

  StoreDashboard({
    required this.storeId,
    required this.storeName,
    required this.todaySales,
    required this.todayRevenue,
    required this.presentEmployees,
    required this.absentEmployees,
    required this.lateEmployees,
    required this.totalEmployees,
    required this.pendingLeaves,
    required this.pendingExpenses,
    required this.storePerformance,
    required this.monthlySales,
    required this.monthlyRevenue,
    required this.dailySalesSummary,
    required this.attendanceSummary,
  });

  factory StoreDashboard.fromJson(Map<String, dynamic> json) {
    return StoreDashboard(
      storeId: json['storeId'] as String? ?? '',
      storeName: json['storeName'] as String? ?? '',
      todaySales: (json['todaySales'] as num?)?.toDouble() ?? 0.0,
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0.0,
      presentEmployees: json['presentEmployees'] as int? ?? 0,
      absentEmployees: json['absentEmployees'] as int? ?? 0,
      lateEmployees: json['lateEmployees'] as int? ?? 0,
      totalEmployees: json['totalEmployees'] as int? ?? 0,
      pendingLeaves: json['pendingLeaves'] as int? ?? 0,
      pendingExpenses: json['pendingExpenses'] as int? ?? 0,
      storePerformance: (json['storePerformance'] as num?)?.toDouble() ?? 0.0,
      monthlySales: (json['monthlySales'] as num?)?.toDouble() ?? 0.0,
      monthlyRevenue: (json['monthlyRevenue'] as num?)?.toDouble() ?? 0.0,
      dailySalesSummary: (json['dailySalesSummary'] as List?)
              ?.map((e) => StoreSalesSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      attendanceSummary: (json['attendanceSummary'] as List?)
              ?.map((e) => StoreAttendanceSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'storeName': storeName,
      'todaySales': todaySales,
      'todayRevenue': todayRevenue,
      'presentEmployees': presentEmployees,
      'absentEmployees': absentEmployees,
      'lateEmployees': lateEmployees,
      'totalEmployees': totalEmployees,
      'pendingLeaves': pendingLeaves,
      'pendingExpenses': pendingExpenses,
      'storePerformance': storePerformance,
      'monthlySales': monthlySales,
      'monthlyRevenue': monthlyRevenue,
      'dailySalesSummary': dailySalesSummary.map((e) => e.toJson()).toList(),
      'attendanceSummary': attendanceSummary.map((e) => e.toJson()).toList(),
    };
  }
}

class StoreSalesSummary {
  final String date;
  final double sales;
  final double revenue;
  final int billsGenerated;

  StoreSalesSummary({
    required this.date,
    required this.sales,
    required this.revenue,
    required this.billsGenerated,
  });

  factory StoreSalesSummary.fromJson(Map<String, dynamic> json) {
    return StoreSalesSummary(
      date: json['date'] as String? ?? '',
      sales: (json['sales'] as num?)?.toDouble() ?? 0.0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      billsGenerated: json['billsGenerated'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'sales': sales,
      'revenue': revenue,
      'billsGenerated': billsGenerated,
    };
  }
}

class StoreAttendanceSummary {
  final String date;
  final int present;
  final int absent;
  final int late;
  final int total;

  StoreAttendanceSummary({
    required this.date,
    required this.present,
    required this.absent,
    required this.late,
    required this.total,
  });

  factory StoreAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return StoreAttendanceSummary(
      date: json['date'] as String? ?? '',
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      late: json['late'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'present': present,
      'absent': absent,
      'late': late,
      'total': total,
    };
  }
}

class StoreEmployee {
  final String id;
  final String employeeCode;
  final String name;
  final String role;
  final String designation;
  final String department;
  final String phone;
  final String storeId;
  final String storeName;
  final String attendanceStatus; // present, absent, late, not_punched
  final String? checkInTime;
  final String? checkOutTime;
  final String status; // active, inactive

  StoreEmployee({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.role,
    required this.designation,
    required this.department,
    required this.phone,
    required this.storeId,
    required this.storeName,
    required this.attendanceStatus,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
  });

  factory StoreEmployee.fromJson(Map<String, dynamic> json) {
    return StoreEmployee(
      id: json['id'] as String? ?? '',
      employeeCode: json['employeeCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      department: json['department'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      storeId: json['storeId'] as String? ?? '',
      storeName: json['storeName'] as String? ?? '',
      attendanceStatus: json['attendanceStatus'] as String? ?? 'not_punched',
      checkInTime: json['checkInTime'] as String?,
      checkOutTime: json['checkOutTime'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeCode': employeeCode,
      'name': name,
      'role': role,
      'designation': designation,
      'department': department,
      'phone': phone,
      'storeId': storeId,
      'storeName': storeName,
      'attendanceStatus': attendanceStatus,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'status': status,
    };
  }
}

class StoreEmployeeList {
  final List<StoreEmployee> employees;
  final int totalCount;
  final int currentPage;
  final int totalPages;

  StoreEmployeeList({
    required this.employees,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
  });

  factory StoreEmployeeList.fromJson(Map<String, dynamic> json) {
    return StoreEmployeeList(
      employees: (json['employees'] as List?)
              ?.map((e) => StoreEmployee.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employees': employees.map((e) => e.toJson()).toList(),
      'totalCount': totalCount,
      'currentPage': currentPage,
      'totalPages': totalPages,
    };
  }
}

class StorePerformance {
  final String storeId;
  final String storeName;
  final double monthlySales;
  final double monthlyRevenue;
  final double monthlyCommission;
  final int totalEmployees;
  final int averageAttendance;
  final double performanceScore;
  final String ranking; // A, B, C, D
  final List<MonthlyPerformance> monthlyPerformance;

  StorePerformance({
    required this.storeId,
    required this.storeName,
    required this.monthlySales,
    required this.monthlyRevenue,
    required this.monthlyCommission,
    required this.totalEmployees,
    required this.averageAttendance,
    required this.performanceScore,
    required this.ranking,
    required this.monthlyPerformance,
  });

  factory StorePerformance.fromJson(Map<String, dynamic> json) {
    return StorePerformance(
      storeId: json['storeId'] as String? ?? '',
      storeName: json['storeName'] as String? ?? '',
      monthlySales: (json['monthlySales'] as num?)?.toDouble() ?? 0.0,
      monthlyRevenue: (json['monthlyRevenue'] as num?)?.toDouble() ?? 0.0,
      monthlyCommission: (json['monthlyCommission'] as num?)?.toDouble() ?? 0.0,
      totalEmployees: json['totalEmployees'] as int? ?? 0,
      averageAttendance: json['averageAttendance'] as int? ?? 0,
      performanceScore: (json['performanceScore'] as num?)?.toDouble() ?? 0.0,
      ranking: json['ranking'] as String? ?? 'C',
      monthlyPerformance: (json['monthlyPerformance'] as List?)
              ?.map((e) => MonthlyPerformance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeId': storeId,
      'storeName': storeName,
      'monthlySales': monthlySales,
      'monthlyRevenue': monthlyRevenue,
      'monthlyCommission': monthlyCommission,
      'totalEmployees': totalEmployees,
      'averageAttendance': averageAttendance,
      'performanceScore': performanceScore,
      'ranking': ranking,
      'monthlyPerformance': monthlyPerformance.map((e) => e.toJson()).toList(),
    };
  }
}

class MonthlyPerformance {
  final String month;
  final String year;
  final double sales;
  final double revenue;
  final double commission;
  final int attendanceRate;

  MonthlyPerformance({
    required this.month,
    required this.year,
    required this.sales,
    required this.revenue,
    required this.commission,
    required this.attendanceRate,
  });

  factory MonthlyPerformance.fromJson(Map<String, dynamic> json) {
    return MonthlyPerformance(
      month: json['month'] as String? ?? '',
      year: json['year'] as String? ?? '',
      sales: (json['sales'] as num?)?.toDouble() ?? 0.0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0.0,
      attendanceRate: json['attendanceRate'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'year': year,
      'sales': sales,
      'revenue': revenue,
      'commission': commission,
      'attendanceRate': attendanceRate,
    };
  }
}
