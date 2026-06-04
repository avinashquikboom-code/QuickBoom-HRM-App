/// Central repository for all API endpoints used in the app.
///
/// Usage:
///   ApiService.get(AppUrl.employeeProfile)
///   ApiService.post(AppUrl.hrApproveLeave(leaveId), body)
class AppUrl {
  AppUrl._(); // prevent instantiation

  // ─────────────────────────────────────────────
  //  Base
  // ─────────────────────────────────────────────
  static const String baseUrl =
      'https://quickboom-hrm-backend.onrender.com';

  // ─────────────────────────────────────────────
  //  Auth
  // ─────────────────────────────────────────────
  static const String login = '/api/auth/login';

  // ─────────────────────────────────────────────
  //  Employee – Profile
  // ─────────────────────────────────────────────
  static const String employeeProfile  = '/api/employee/profile';
  static const String employeeAvatar   = '/api/employee/avatar';

  // ─────────────────────────────────────────────
  //  Employee – Dashboard
  // ─────────────────────────────────────────────
  static const String employeeDashboardStats = '/api/employee/dashboard/stats';

  // ─────────────────────────────────────────────
  //  Employee – Attendance  (mobile)
  // ─────────────────────────────────────────────
  static const String attendanceToday   = '/api/mobile/attendance/today';
  static const String attendanceHistory = '/api/mobile/attendance/history?limit=30';
  static const String attendancePunchIn  = '/api/mobile/attendance/punch-in';
  static const String attendancePunchOut = '/api/mobile/attendance/punch-out';
  static const String attendanceBreakStart = '/api/mobile/attendance/break/start';
  static const String attendanceBreakEnd   = '/api/mobile/attendance/break/end';

  // ─────────────────────────────────────────────
  //  Employee – Leaves
  // ─────────────────────────────────────────────
  static const String employeeLeaves = '/api/employee/leaves';

  // ─────────────────────────────────────────────
  //  Employee – Tasks
  // ─────────────────────────────────────────────
  static const String employeeTasks = '/api/employee/tasks';

  /// Update a specific task's status.
  static String employeeTaskById(String taskId) =>
      '/api/employee/tasks/$taskId';

  // ─────────────────────────────────────────────
  //  Employee – Expenses
  // ─────────────────────────────────────────────
  static const String employeeExpenses = '/api/employee/expenses';

  // ─────────────────────────────────────────────
  //  Employee – Notifications
  // ─────────────────────────────────────────────
  static const String employeeNotifications    = '/api/employee/notifications';
  static const String employeeNotificationsReadAll =
      '/api/employee/notifications/read-all';

  /// Mark a single notification as read.
  static String employeeNotificationRead(String id) =>
      '/api/employee/notifications/$id/read';

  // ─────────────────────────────────────────────
  //  Employee – Shifts
  // ─────────────────────────────────────────────
  static const String employeeShifts = '/api/employee/shifts';

  // ─────────────────────────────────────────────
  //  Employee – Holidays
  // ─────────────────────────────────────────────
  static const String employeeHolidays = '/api/employee/holidays';

  // ─────────────────────────────────────────────
  //  HR – Dashboard
  // ─────────────────────────────────────────────
  static const String hrStats = '/api/hr/stats';
  static const String hrTodayAttendance = '/api/admin/attendance/today';

  // ─────────────────────────────────────────────
  //  HR – Employees
  // ─────────────────────────────────────────────
  static const String hrEmployees = '/api/hr/employees';

  // ─────────────────────────────────────────────
  //  HR – Leaves
  // ─────────────────────────────────────────────
  static const String hrLeaves = '/api/hr/leaves';

  /// Approve a leave request.
  static String hrApproveLeave(String leaveId) =>
      '/api/hr/leaves/$leaveId/approve';

  /// Reject a leave request.
  static String hrRejectLeave(String leaveId) =>
      '/api/hr/leaves/$leaveId/reject';

  // ─────────────────────────────────────────────
  //  HR – Tasks
  // ─────────────────────────────────────────────
  static const String hrTasks = '/api/hr/tasks';

  // ─────────────────────────────────────────────
  //  HR – Expenses
  // ─────────────────────────────────────────────
  static const String hrExpenses = '/api/hr/expenses';

  /// Approve an expense claim.
  static String hrApproveExpense(String expenseId) =>
      '/api/hr/expenses/$expenseId/approve';

  /// Reject an expense claim.
  static String hrRejectExpense(String expenseId) =>
      '/api/hr/expenses/$expenseId/reject';

  // ─────────────────────────────────────────────
  //  HR – Payroll
  // ─────────────────────────────────────────────
  static const String hrPayrollStats = '/api/hr/payroll/stats';
  static const String hrPayrollRuns  = '/api/hr/payroll/runs';
}
