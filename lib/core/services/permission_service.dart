import 'package:quickboom_hrm/features/auth/data/models/user_model.dart';

class PermissionService {
  // Permission keys
  static const String canViewCommission = 'canViewCommission';
  static const String canViewWallet = 'canViewWallet';
  static const String canApproveLeave = 'canApproveLeave';
  static const String canApproveExpense = 'canApproveExpense';
  static const String canManageEmployees = 'canManageEmployees';
  static const String canManageStore = 'canManageStore';
  static const String canViewPayroll = 'canViewPayroll';
  static const String canViewReports = 'canViewReports';
  static const String canViewStoreReports = 'canViewStoreReports';
  static const String canViewStoreDashboard = 'canViewStoreDashboard';
  static const String canViewCommissionHistory = 'canViewCommissionHistory';
  static const String canViewCommissionDetails = 'canViewCommissionDetails';

  // Default permissions based on role
  static Map<String, bool> getDefaultPermissions(UserRole role) {
    switch (role) {
      case UserRole.salesman:
        return {
          canViewCommission: true,
          canViewWallet: true,
          canViewCommissionHistory: true,
          canViewCommissionDetails: true,
          canApproveLeave: false,
          canApproveExpense: false,
          canManageEmployees: false,
          canManageStore: false,
          canViewPayroll: true,
          canViewReports: true,
          canViewStoreReports: false,
          canViewStoreDashboard: false,
        };
      case UserRole.storeManager:
        return {
          canViewCommission: false,
          canViewWallet: true,
          canViewCommissionHistory: false,
          canViewCommissionDetails: false,
          canApproveLeave: true,
          canApproveExpense: true,
          canManageEmployees: true,
          canManageStore: true,
          canViewPayroll: true,
          canViewReports: true,
          canViewStoreReports: true,
          canViewStoreDashboard: true,
        };
      case UserRole.helper:
        return {
          canViewCommission: false,
          canViewWallet: true,
          canViewCommissionHistory: false,
          canViewCommissionDetails: false,
          canApproveLeave: false,
          canApproveExpense: false,
          canManageEmployees: false,
          canManageStore: false,
          canViewPayroll: true,
          canViewReports: false,
          canViewStoreReports: false,
          canViewStoreDashboard: false,
        };
      case UserRole.hrManager:
        return {
          canViewCommission: false, // Only Salesman can view commission
          canViewWallet: true,
          canViewCommissionHistory: false,
          canViewCommissionDetails: false,
          canApproveLeave: true,
          canApproveExpense: true,
          canManageEmployees: true,
          canManageStore: true,
          canViewPayroll: true,
          canViewReports: true,
          canViewStoreReports: true,
          canViewStoreDashboard: true,
        };
      case UserRole.employee:
        return {
          canViewCommission: false,
          canViewWallet: true,
          canViewCommissionHistory: false,
          canViewCommissionDetails: false,
          canApproveLeave: false,
          canApproveExpense: false,
          canManageEmployees: false,
          canManageStore: false,
          canViewPayroll: true,
          canViewReports: true,
          canViewStoreReports: false,
          canViewStoreDashboard: false,
        };
    }
  }

  // Check if user has specific permission
  static bool hasPermission(UserModel? user, String permission) {
    if (user == null) return false;
    if (user.permissions != null && user.permissions!.containsKey(permission)) {
      return user.permissions![permission] ?? false;
    }
    return getDefaultPermissions(user.role)[permission] ?? false;
  }

  // Check multiple permissions (all must be true)
  static bool hasAllPermissions(UserModel? user, List<String> permissions) {
    if (user == null) return false;
    return permissions.every((permission) => user.hasPermission(permission));
  }

  // Check multiple permissions (at least one must be true)
  static bool hasAnyPermission(UserModel? user, List<String> permissions) {
    if (user == null) return false;
    return permissions.any((permission) => user.hasPermission(permission));
  }

  // Visibility helpers for common UI elements
  static bool canViewCommissionWidget(UserModel? user) {
    return hasPermission(user, canViewCommission);
  }

  static bool canAccessStoreDashboard(UserModel? user) {
    return hasPermission(user, canViewStoreDashboard);
  }

  static bool canManageStoreEmployees(UserModel? user) {
    return hasPermission(user, canManageEmployees) && hasPermission(user, canManageStore);
  }

  static bool canApproveStoreLeave(UserModel? user) {
    return hasPermission(user, canApproveLeave) && hasPermission(user, canManageStore);
  }

  static bool canApproveStoreExpense(UserModel? user) {
    return hasPermission(user, canApproveExpense) && hasPermission(user, canManageStore);
  }
}
