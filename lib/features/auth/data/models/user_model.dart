enum UserRole { employee, hrManager, salesman, storeManager, helper }

class UserModel {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String department;
  final String designation;
  final DateTime joinDate;
  final double salary;
  final String? avatar;
  final String? storeId;
  final String? storeName;
  final String? officeId;
  final String? officeName;
  final String? reportingManagerId;
  final String? reportingManagerName;
  final Map<String, bool>? permissions;

  const UserModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.department,
    required this.designation,
    required this.joinDate,
    required this.salary,
    this.avatar,
    this.storeId,
    this.storeName,
    this.officeId,
    this.officeName,
    this.reportingManagerId,
    this.reportingManagerName,
    this.permissions,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) {
      return name.length >= 2
          ? name.substring(0, 2).toUpperCase()
          : name.toUpperCase();
    }
    return 'U';
  }

  String get roleLabel {
    switch (role) {
      case UserRole.hrManager:
        return 'HR Manager';
      case UserRole.salesman:
        return 'Salesman';
      case UserRole.storeManager:
        return 'Store Manager';
      case UserRole.helper:
        return 'Helper';
      default:
        return 'Employee';
    }
  }

  int get yearsOfService {
    final now = DateTime.now();
    return now.year - joinDate.year;
  }

  bool get isSalesman => role == UserRole.salesman;
  bool get isStoreManager => role == UserRole.storeManager;
  bool get isHelper => role == UserRole.helper;
  bool get isHRManager => role == UserRole.hrManager;
  bool get isEmployee => role == UserRole.employee;

  bool hasPermission(String permission) {
    return permissions?[permission] ?? false;
  }

  bool get canViewCommission => hasPermission('canViewCommission');
  bool get canViewWallet => hasPermission('canViewWallet');
  bool get canApproveLeave => hasPermission('canApproveLeave');
  bool get canApproveExpense => hasPermission('canApproveExpense');
  bool get canManageEmployees => hasPermission('canManageEmployees');
  bool get canManageStore => hasPermission('canManageStore');
  bool get canViewPayroll => hasPermission('canViewPayroll');
  bool get canViewReports => hasPermission('canViewReports');
  bool get canViewStoreReports => hasPermission('canViewStoreReports');
}
