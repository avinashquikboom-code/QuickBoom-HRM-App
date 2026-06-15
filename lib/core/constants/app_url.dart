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
      'https://api.voxiqai.com';

  // ─────────────────────────────────────────────
  //  Auth
  // ─────────────────────────────────────────────
  static const String login = '/api/mobile/auth/login';
  static const String hrLogin = '/api/auth/hr/login';
  static const String logout = '/api/mobile/auth/logout';
  static const String refreshToken = '/api/mobile/auth/refresh';
  static const String changePassword = '/api/mobile/auth/change-password';
  static const String forgotPassword = '/api/mobile/auth/forgot-password';

  // ─────────────────────────────────────────────
  //  Employee – Profile
  // ─────────────────────────────────────────────
  static const String employeeProfile  = '/api/mobile/auth/profile';
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
  static const String attendanceMyReportDownload = '/api/mobile/attendance/my-report/download';
  static const String attendanceReportDownload = '/api/mobile/attendance/report/download';

  // ─────────────────────────────────────────────
  //  Employee – Leaves
  // ─────────────────────────────────────────────
  static const String employeeLeaves = '/api/employee/leaves';
  static const String leaveMyReportDownload = '/api/mobile/leave/my-report/download';
  static const String leaveReportDownload = '/api/mobile/leave/report/download';

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
  //  Employee – Documents
  // ─────────────────────────────────────────────
  static const String employeeDocuments = '/api/employee/documents';

  // ─────────────────────────────────────────────
  //  HR – Dashboard
  // ─────────────────────────────────────────────
  static const String hrStats = '/api/hr/stats';
  static const String hrTodayAttendance = '/api/mobile/attendance/all';

  // ─────────────────────────────────────────────
  //  HR – Employees
  // ─────────────────────────────────────────────
  static const String hrEmployees = '/api/hr/employees';

  // ─────────────────────────────────────────────
  //  HR – Leaves
  // ─────────────────────────────────────────────
  static const String hrLeaves = '/api/mobile/leave/hr/requests';

  /// Approve a leave request.
  static String hrApproveLeave(String leaveId) =>
      '/api/mobile/leave/hr/$leaveId/approve';

  /// Reject a leave request.
  static String hrRejectLeave(String leaveId) =>
      '/api/mobile/leave/hr/$leaveId/reject';

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

  // ─────────────────────────────────────────────
  //  Employee – Payroll (Mobile)
  // ─────────────────────────────────────────────
  static const String employeePayslips = '/api/mobile/payroll/slips';
  static String employeeDownloadPayslip(String id) =>
      '/api/mobile/payroll/slips/$id/download';

  // ─────────────────────────────────────────────
  // Mobile – Leave
  // ─────────────────────────────────────────────
  static const String mobileMyLeaves = '/api/mobile/leave/my-leaves';
  static const String mobileApplyLeave = '/api/mobile/leave/apply';

  // ─────────────────────────────────────────────
  // Mobile – Attendance (HR/Admin)
  // ─────────────────────────────────────────────
  static const String mobileAllAttendance = '/api/mobile/attendance/all';

  // ─────────────────────────────────────────────
  // Mobile – Notifications
  // ─────────────────────────────────────────────
  static const String mobileNotifications = '/api/mobile/notifications';
  static String mobileMarkNotificationRead(String id) =>
      '/api/mobile/notifications/$id/read';
  static const String mobileMarkAllNotificationsRead = '/api/mobile/notifications/read-all';

  // ─────────────────────────────────────────────
  // Live Tracking (Mobile)
  // ─────────────────────────────────────────────
  static const String trackingStart = '/api/mobile/tracking/start';
  static const String trackingStop = '/api/mobile/tracking/stop';
  static const String trackingUpdateLocation = '/api/mobile/tracking/location';
  static const String trackingSessions = '/api/mobile/tracking/sessions';
  static const String trackingHistory = '/api/mobile/tracking/history';
  static const String trackingLive = '/api/mobile/tracking/live';

  // ─────────────────────────────────────────────
  // Geofencing (Mobile)
  // ─────────────────────────────────────────────
  static const String geofenceCheck = '/api/mobile/geofence/check';
  static const String geofenceOffices = '/api/mobile/geofence/offices';
  static const String geofenceStatus = '/api/mobile/geofence/status';
  static const String geofenceNearby = '/api/mobile/geofence/nearby';

  // ─────────────────────────────────────────────
  // FCM Token
  // ─────────────────────────────────────────────
  static const String saveFCMToken = '/api/mobile/notifications/fcm-token';

  // ─────────────────────────────────────────────
  // Distance Tracking (Mobile)
  // ─────────────────────────────────────────────
  static const String distanceCurrent = '/api/mobile/distance/current';
  static const String distanceHistory = '/api/mobile/distance/history';
  static const String distanceOfficeInfo = '/api/mobile/distance/office-info';

  // ─────────────────────────────────────────────
  // Comprehensive Attendance Report (Mobile)
  // ─────────────────────────────────────────────
  static const String attendanceComprehensiveReport = '/api/mobile/attendance/comprehensive/comprehensive-report';
}
