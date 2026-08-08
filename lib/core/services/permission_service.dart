import 'package:quickboom_hrm/features/auth/data/models/user_model.dart';

class PermissionService {
  // 1. Home & Dashboard
  static const String canViewGeofence = 'canViewGeofence';
  static const String canPunchInOut = 'canPunchInOut';
  static const String canPunchHalfDay = 'canPunchHalfDay';
  static const String canTakeBreaks = 'canTakeBreaks';

  // 2. Attendance & Logs
  static const String canViewAttendance = 'canViewAttendance';
  static const String canViewBreakHistory = 'canViewBreakHistory';
  static const String canRequestAttendanceCorrection = 'canRequestAttendanceCorrection';

  // 3. Wallet & Financials
  static const String canViewSalary = 'canViewSalary';
  static const String canDownloadSalaryPDF = 'canDownloadSalaryPDF';
  static const String canRequestSalaryAdvance = 'canRequestSalaryAdvance';
  static const String canViewCommission = 'canViewCommission';
  static const String canLogSale = 'canLogSale';
  static const String canViewExpenses = 'canViewExpenses';
  static const String canSubmitExpenseClaim = 'canSubmitExpenseClaim';
  static const String canCancelExpenseClaim = 'canCancelExpenseClaim';
  static const String canRequestBankDetailsEdit = 'canRequestBankDetailsEdit';

  // 4. Leave & Holidays
  static const String canViewLeaveBalance = 'canViewLeaveBalance';
  static const String canViewLeaveHistory = 'canViewLeaveHistory';
  static const String canApplyLeave = 'canApplyLeave';
  static const String canCancelLeave = 'canCancelLeave';
  static const String canViewHolidays = 'canViewHolidays';

  // 5. Tasks Management
  static const String canViewTasks = 'canViewTasks';
  static const String canCompleteTask = 'canCompleteTask';

  // 6. Shift & Guidelines
  static const String canViewShift = 'canViewShift';
  static const String canRequestShiftChange = 'canRequestShiftChange';
  static const String canCancelShiftRequest = 'canCancelShiftRequest';
  static const String canViewShiftGuidelines = 'canViewShiftGuidelines';

  // 7. Remote Work
  static const String canViewRemoteWorkStatus = 'canViewRemoteWorkStatus';
  static const String canApplyRemoteWork = 'canApplyRemoteWork';
  static const String canCancelRemoteRequest = 'canCancelRemoteRequest';

  // 8. Profile & System
  static const String canViewProfile = 'canViewProfile';
  static const String canEditAvatar = 'canEditAvatar';
  static const String canChangePassword = 'canChangePassword';
  static const String canViewNotifications = 'canViewNotifications';

  // Legacy / Management Keys
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
      case UserRole.helper:
      case UserRole.employee:
        return {
          canViewGeofence: true,
          canPunchInOut: true,
          canPunchHalfDay: true,
          canTakeBreaks: true,
          canViewAttendance: true,
          canViewBreakHistory: true,
          canRequestAttendanceCorrection: true,
          canViewSalary: true,
          canDownloadSalaryPDF: true,
          canRequestSalaryAdvance: true,
          canViewCommission: true,
          canLogSale: true,
          canViewExpenses: true,
          canSubmitExpenseClaim: true,
          canCancelExpenseClaim: true,
          canRequestBankDetailsEdit: true,
          canViewLeaveBalance: true,
          canViewLeaveHistory: true,
          canApplyLeave: true,
          canCancelLeave: true,
          canViewHolidays: true,
          canViewTasks: true,
          canCompleteTask: true,
          canViewShift: true,
          canRequestShiftChange: true,
          canCancelShiftRequest: true,
          canViewShiftGuidelines: true,
          canViewRemoteWorkStatus: true,
          canApplyRemoteWork: true,
          canCancelRemoteRequest: true,
          canViewProfile: true,
          canEditAvatar: true,
          canChangePassword: true,
          canViewNotifications: true,
          canViewWallet: true,
          canViewPayroll: true,
        };
      case UserRole.storeManager:
      case UserRole.hrManager:
        return {
          canViewGeofence: true,
          canPunchInOut: true,
          canPunchHalfDay: true,
          canTakeBreaks: true,
          canViewAttendance: true,
          canViewBreakHistory: true,
          canRequestAttendanceCorrection: true,
          canViewSalary: true,
          canDownloadSalaryPDF: true,
          canRequestSalaryAdvance: true,
          canViewCommission: true,
          canLogSale: true,
          canViewExpenses: true,
          canSubmitExpenseClaim: true,
          canCancelExpenseClaim: true,
          canRequestBankDetailsEdit: true,
          canViewLeaveBalance: true,
          canViewLeaveHistory: true,
          canApplyLeave: true,
          canCancelLeave: true,
          canViewHolidays: true,
          canViewTasks: true,
          canCompleteTask: true,
          canViewShift: true,
          canRequestShiftChange: true,
          canCancelShiftRequest: true,
          canViewShiftGuidelines: true,
          canViewRemoteWorkStatus: true,
          canApplyRemoteWork: true,
          canCancelRemoteRequest: true,
          canViewProfile: true,
          canEditAvatar: true,
          canChangePassword: true,
          canViewNotifications: true,
          canViewWallet: true,
          canApproveLeave: true,
          canApproveExpense: true,
          canManageEmployees: true,
          canManageStore: true,
          canViewPayroll: true,
          canViewReports: true,
          canViewStoreReports: true,
          canViewStoreDashboard: true,
        };
    }
  }

  // Check if user has specific permission
  static bool hasPermission(UserModel? user, String permission) {
    if (user == null) return false;
    if (user.permissions != null && user.permissions!.containsKey(permission)) {
      return user.permissions![permission] ?? true;
    }
    final defaultMap = getDefaultPermissions(user.role);
    if (defaultMap.containsKey(permission)) {
      return defaultMap[permission] ?? true;
    }
    return true;
  }

  // Check multiple permissions (all must be true)
  static bool hasAllPermissions(UserModel? user, List<String> permissions) {
    if (user == null) return false;
    return permissions.every((permission) => hasPermission(user, permission));
  }

  // Check multiple permissions (at least one must be true)
  static bool hasAnyPermission(UserModel? user, List<String> permissions) {
    if (user == null) return false;
    return permissions.any((permission) => hasPermission(user, permission));
  }

  // Specific UI helpers
  static bool canViewSalaryWidget(UserModel? user) {
    if (user == null) return false;
    return hasPermission(user, canViewSalary);
  }

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
