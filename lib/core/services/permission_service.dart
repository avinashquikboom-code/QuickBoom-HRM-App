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

  // Normalize permission keys across Web Admin Panel and Mobile App
  static String normalizePermissionKey(String key) {
    final clean = key.trim();
    if (clean.startsWith('canView') ||
        clean.startsWith('canLog') ||
        clean.startsWith('canApply') ||
        clean.startsWith('canSubmit') ||
        clean.startsWith('canRequest') ||
        clean.startsWith('canPunch') ||
        clean.startsWith('canTake') ||
        clean.startsWith('canDownload') ||
        clean.startsWith('canComplete') ||
        clean.startsWith('canCancel') ||
        clean.startsWith('canEdit') ||
        clean.startsWith('canChange')) {
      return clean;
    }
    switch (clean.toLowerCase()) {
      case 'view_salary_slip':
      case 'salary_slip':
      case 'salary':
      case 'wallet':
        return canViewSalary;
      case 'view_attendance_calendar':
      case 'attendance':
      case 'attendance_calendar':
        return canViewAttendance;
      case 'view_commission_dashboard':
      case 'commission':
      case 'commission_dashboard':
        return canViewCommission;
      case 'view_expense_claims':
      case 'expenses':
      case 'expense_claims':
        return canViewExpenses;
      case 'view_leave_balance':
      case 'leave':
      case 'leave_balance':
        return canViewLeaveBalance;
      case 'view_assigned_tasks':
      case 'tasks':
      case 'assigned_tasks':
        return canViewTasks;
      case 'view_shift_schedule':
      case 'shift':
      case 'shift_guidelines':
        return canViewShiftGuidelines;
      case 'view_remote_work_status':
      case 'remote_work':
        return canViewRemoteWorkStatus;
      default:
        return clean;
    }
  }

  static List<String> _getAliases(String key) {
    final norm = normalizePermissionKey(key);
    switch (norm) {
      case canViewSalary:
        return ['view_salary_slip', 'salary_slip', 'salary', 'wallet', 'canViewSalary'];
      case canViewAttendance:
        return ['view_attendance_calendar', 'attendance', 'attendance_calendar', 'canViewAttendance'];
      case canViewCommission:
        return ['view_commission_dashboard', 'commission', 'commission_dashboard', 'canViewCommission'];
      case canViewExpenses:
        return ['view_expense_claims', 'expenses', 'expense_claims', 'canViewExpenses'];
      case canViewLeaveBalance:
        return ['view_leave_balance', 'leave', 'leave_balance', 'canViewLeaveBalance'];
      case canViewTasks:
        return ['view_assigned_tasks', 'tasks', 'assigned_tasks', 'canViewTasks'];
      case canViewShiftGuidelines:
        return ['view_shift_schedule', 'shift', 'shift_guidelines', 'canViewShiftGuidelines'];
      case canViewRemoteWorkStatus:
        return ['view_remote_work_status', 'remote_work', 'canViewRemoteWorkStatus'];
      default:
        return [key, norm];
    }
  }

  // Check if user has specific permission
  static bool hasPermission(UserModel? user, String permission) {
    if (user == null) return false;

    final perms = user.permissions;
    if (perms != null && perms.isNotEmpty) {
      // 1. Direct key lookup
      if (perms.containsKey(permission)) {
        return perms[permission] ?? false;
      }

      // 2. Normalized key lookup
      final normKey = normalizePermissionKey(permission);
      if (perms.containsKey(normKey)) {
        return perms[normKey] ?? false;
      }

      // 3. Alias list lookup (if any alias is explicitly false, deny access)
      final aliases = _getAliases(permission);
      for (final alias in aliases) {
        if (perms.containsKey(alias)) {
          return perms[alias] ?? false;
        }
      }
    }

    final defaultMap = getDefaultPermissions(user.role);
    if (defaultMap.containsKey(permission)) {
      return defaultMap[permission] ?? true;
    }
    final normKey = normalizePermissionKey(permission);
    if (defaultMap.containsKey(normKey)) {
      return defaultMap[normKey] ?? true;
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
