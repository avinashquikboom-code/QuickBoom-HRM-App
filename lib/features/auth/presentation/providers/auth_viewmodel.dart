import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/services/storage_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/notification_service.dart';
import 'package:quickboom_hrm/features/auth/data/models/user_model.dart';
import 'package:quickboom_hrm/features/employees/presentation/providers/employee_repository_provider.dart';
import 'package:quickboom_hrm/features/employees/data/models/hopkid_employee_model.dart';

// Import all user-specific view models for session invalidation on logout
import 'package:quickboom_hrm/features/attendance/presentation/providers/attendance_viewmodel.dart';
import 'package:quickboom_hrm/features/attendance/presentation/providers/geofence_viewmodel.dart';
import 'package:quickboom_hrm/features/attendance/presentation/providers/live_tracking_viewmodel.dart';
import 'package:quickboom_hrm/features/attendance/presentation/providers/hr_attendance_viewmodel.dart';
import 'package:quickboom_hrm/features/expense/presentation/providers/expense_viewmodel.dart';
import 'package:quickboom_hrm/features/expense/presentation/providers/hr_expense_viewmodel.dart';
import 'package:quickboom_hrm/features/employees/presentation/providers/employee_list_viewmodel.dart';
import 'package:quickboom_hrm/features/payroll/presentation/providers/employee_payroll_viewmodel.dart';
import 'package:quickboom_hrm/features/payroll/presentation/providers/hr_payroll_viewmodel.dart';
import 'package:quickboom_hrm/features/leave/presentation/providers/leave_viewmodel.dart';
import 'package:quickboom_hrm/features/leave/presentation/providers/hr_leave_viewmodel.dart';
import 'package:quickboom_hrm/features/task/presentation/providers/task_viewmodel.dart';
import 'package:quickboom_hrm/features/task/presentation/providers/hr_task_viewmodel.dart';
import 'package:quickboom_hrm/features/profile/presentation/providers/profile_viewmodel.dart';
import 'package:quickboom_hrm/features/notification/presentation/providers/notification_viewmodel.dart';
import 'package:quickboom_hrm/features/document/presentation/providers/document_viewmodel.dart';
import 'package:quickboom_hrm/features/shift/presentation/providers/shift_viewmodel.dart';
import 'package:quickboom_hrm/features/dashboard/presentation/providers/employee_dashboard_viewmodel.dart';
import 'package:quickboom_hrm/features/dashboard/presentation/providers/hr_dashboard_viewmodel.dart';
import 'package:quickboom_hrm/features/holiday/presentation/providers/holiday_viewmodel.dart';

// ─── Auth State ──────────────────────────────────────────────────────────────

class AuthState {
  final bool isLoading;
  final UserModel? currentUser;
  final String? errorMessage;
  final bool isNotRegistered;

  const AuthState({
    this.isLoading = false,
    this.currentUser,
    this.errorMessage,
    this.isNotRegistered = false,
  });

  bool get isAuthenticated => currentUser != null && !isNotRegistered;

  AuthState copyWith({
    bool? isLoading,
    UserModel? currentUser,
    String? errorMessage,
    bool? isNotRegistered,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      currentUser: currentUser ?? this.currentUser,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isNotRegistered: isNotRegistered ?? this.isNotRegistered,
    );
  }
}

// ─── Auth ViewModel ───────────────────────────────────────────────────────────

class AuthViewModel extends StateNotifier<AuthState> {
  final Ref ref;

  AuthViewModel(this.ref) : super(const AuthState());

  /// Use cached FCM token only — never block login on Firebase token fetch.
  Future<String?> _getCachedFcmToken() async {
    final cached = await StorageService.getFCMToken();
    if (cached != null && cached.isNotEmpty) return cached;
    return null;
  }

  /// Sync FCM token in background after login (non-blocking).
  void _syncFcmTokenInBackground() {
    NotificationService().refreshToken();
  }

  UserModel _parseUserFromLoginResponse(
    Map<String, dynamic> loginData,
    String fallbackEmail, {
    required bool forceHrRole,
  }) {
    final userMap = loginData['user'] as Map<String, dynamic>;
    final profMap = userMap['profile'] as Map<String, dynamic>? ?? {};
    final empMap = userMap['employee'] as Map<String, dynamic>? ?? {};
    final userRole = userMap['role'].toString().toUpperCase();

    final isHrRole = forceHrRole ||
        userRole == 'HR' ||
        userRole == 'SUPER_ADMIN' ||
        userRole == 'ADMIN' ||
        userRole == 'PLATFORM_ADMIN';

    return UserModel(
      id: userMap['id'].toString(),
      employeeId: empMap['employeeCode']?.toString() ?? userMap['id'].toString(),
      name: profMap['fullName']?.toString() ??
          '${empMap['firstName']?.toString() ?? ''} ${empMap['lastName']?.toString() ?? ''}'.trim(),
      email: profMap['email']?.toString() ??
          userMap['email']?.toString() ??
          fallbackEmail.trim(),
      phone: profMap['phone']?.toString() ?? '',
      role: isHrRole
          ? UserRole.hrManager
          : userRole == 'SALESMAN'
              ? UserRole.salesman
              : userRole == 'STORE_MANAGER'
                  ? UserRole.storeManager
                  : userRole == 'HELPER'
                      ? UserRole.helper
                      : UserRole.employee,
      department: (empMap['department'] is Map 
              ? empMap['department']['name'] 
              : empMap['department'])?.toString() ??
          (isHrRole ? 'Human Resources' : 'General'),
      designation: empMap['designation']?.toString() ??
          profMap['bio']?.toString() ??
          (isHrRole ? 'HR Manager' : 'Employee'),
      joinDate: DateTime.tryParse(
            profMap['createdAt']?.toString() ?? empMap['joinDate']?.toString() ?? '',
          ) ??
          DateTime.now(),
      salary: 0.0,
      avatar: profMap['avatar']?.toString(),
      bankName: empMap['bankName']?.toString(),
      accountNumber: empMap['accountNumber']?.toString(),
      ifscCode: empMap['ifscCode']?.toString(),
      accountType: empMap['accountType']?.toString(),
      branchName: empMap['branchName']?.toString(),
    );
  }

  Future<bool> _performLogin(
    String email,
    String password, {
    required bool forceHrRole,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    debugPrint('🔐 [AUTH] Login attempt for email: $email (${forceHrRole ? "HR" : "Employee"})');

    try {
      // Use cached FCM only — do not await FirebaseMessaging.getToken() here
      final fcmToken = await _getCachedFcmToken();

      final loginEndpoint = forceHrRole ? AppUrl.hrLogin : AppUrl.login;
      debugPrint('🔐 [AUTH] Using endpoint: $loginEndpoint (forceHrRole: $forceHrRole)');
      final loginRes = await ApiService.post(
        loginEndpoint,
        {
          'email': email.trim(),
          'password': password.trim(),
          'fcmToken': ?fcmToken,
        },
        timeout: ApiService.loginTimeout,
      );

      final loginData = jsonDecode(loginRes.body);
      if (loginData is! Map<String, dynamic> || loginData['success'] != true) {
        final msg = (loginData is Map ? loginData['message'] : null) ?? 'Login failed. Please try again.';
        debugPrint('❌ [AUTH] Login failed: $msg');
        state = state.copyWith(isLoading: false, errorMessage: msg.toString());
        return false;
      }

      final token = loginData['token'] as String?;
      if (token == null || token.isEmpty || loginData['user'] is! Map<String, dynamic>) {
        debugPrint('❌ [AUTH] Login response missing token/user: ${loginRes.body}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login failed due to an unexpected server response. Please try again.',
        );
        return false;
      }
      final refreshToken = loginData['refreshToken'] as String? ?? '';
      final userRole = loginData['user']['role'].toString().toUpperCase();
      
      debugPrint('✅ [AUTH] Login successful for email: $email');
      debugPrint('👤 [AUTH] User role: $userRole');
      debugPrint('🔑 [AUTH] Token saved to storage');
      
      await ApiService.saveTokens(token, refreshToken, userRole);
      await StorageService.saveUserRole(userRole);

      final parsedUser = _parseUserFromLoginResponse(
        loginData,
        email,
        forceHrRole: forceHrRole,
      );

      UserModel hydratedUser = parsedUser;
      if (parsedUser.role != UserRole.hrManager) {
        final repo = ref.read(employeeRepositoryProvider);
        List<HopkidEmployeeModel> cache = await repo.getCachedEmployees();
        if (cache.isEmpty) {
          try {
            cache = await repo.refresh();
          } catch (e) {
            debugPrint('⚠️ Cold employee sync failed: $e');
          }
        }

        final cleanedPhone = parsedUser.phone.replaceAll(RegExp(r'\D'), '');
        HopkidEmployeeModel? matched;
        
        for (final emp in cache) {
          final cleanedEmpPhone = emp.mobileNo.replaceAll(RegExp(r'\D'), '');
          if (cleanedEmpPhone.isNotEmpty && cleanedPhone.isNotEmpty && cleanedPhone == cleanedEmpPhone) {
            matched = emp;
            break;
          }
        }
        
        if (matched == null) {
          for (final emp in cache) {
            if (emp.employeeCode.toUpperCase() == parsedUser.employeeId.toUpperCase()) {
              matched = emp;
              break;
            }
          }
        }

        if (matched == null) {
          debugPrint('⚠️ [AUTH] Employee user is not in HopKid master list, continuing as local employee: ${parsedUser.phone} / ${parsedUser.employeeId}');
          hydratedUser = parsedUser;
        } else {
          hydratedUser = parsedUser.copyWith(
            hopkidEmployeeId: matched.employeeID,
            salary: matched.salary,
            commissionPercentage: matched.commissionPercentage,
            branchName: matched.branchName,
          );
          // Persist the HopKid GUID so SalesService can use it across restarts.
          await StorageService.saveHopkidEmployeeId(matched.employeeID);
          debugPrint('✅ [AUTH] Mapped employee to HopKid ID: ${matched.employeeID}');
        }
      }

      debugPrint('👤 [AUTH] Hydrated user: ${hydratedUser.name} (${hydratedUser.email})');
      state = AuthState(currentUser: hydratedUser);

      // Sync FCM in background (handles missing cached token without blocking login)
      _syncFcmTokenInBackground();
      return true;
    } on ApiException catch (e) {
      // Already sanitized user-facing message from ApiService
      debugPrint('❌ [AUTH] Login error (${e.statusCode}): ${e.message}');
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } on FormatException catch (e) {
      debugPrint('❌ [AUTH] Login response parse error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected response from the server. Please try again later.',
      );
      return false;
    } catch (e) {
      debugPrint('❌ [AUTH] Login error: $e');
      final raw = e.toString().replaceFirst('Exception: ', '');
      // Only show raw messages that look user-presentable; hide type/cast errors etc.
      final presentable = raw.length <= 200 &&
          !raw.contains('\n') &&
          !RegExp(r"type '|subtype|Null|Instance of", caseSensitive: false).hasMatch(raw);
      state = state.copyWith(
        isLoading: false,
        errorMessage: presentable ? raw : 'Login failed. Please try again.',
      );
      return false;
    }
  }

  Future<bool> login(String employeeId, String password) =>
      _performLogin(employeeId, password, forceHrRole: false);

  Future<bool> hrLogin(String email, String password) {
    debugPrint('🔐 [AUTH] HR Login called for email: $email');
    return _performLogin(email, password, forceHrRole: true);
  }

  Future<bool> restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final activeRole = await StorageService.getUserRole();

      if (activeRole == 'HR') {
        // ── HR session restore ─────────────────────────────────────
        // HR token is stored; fetch HR profile via employee/profile endpoint
        // using the hr_token that getToken() will now return.
        final profileRes = await ApiService.get(AppUrl.employeeProfile);
        final profileData = jsonDecode(profileRes.body);

        final userMap = profileData['user'] as Map<String, dynamic>;
        final prof = userMap['profile'] as Map<String, dynamic>? ?? {};

        final parsedUser = UserModel(
          id:          userMap['id'].toString(),
          employeeId:  userMap['id'].toString(),
          name:        prof['fullName']?.toString() ?? 'HR Manager',
          email:       prof['email']?.toString() ?? userMap['email']?.toString() ?? '',
          phone:       prof['phone']?.toString() ?? '',
          role:        UserRole.hrManager,
          department:  'Human Resources',
          designation: prof['bio']?.toString() ?? 'HR Manager',
          joinDate:    DateTime.tryParse(prof['createdAt']?.toString() ?? '') ?? DateTime.now(),
          salary:      0.0,
          avatar:      prof['avatar']?.toString(),
        );

        state = AuthState(currentUser: parsedUser);
        _syncFcmTokenInBackground();
        return true;
      } else {
        // ── Employee session restore ───────────────────────────────
        final profileRes = await ApiService.get(AppUrl.employeeProfile);
        final profileData = jsonDecode(profileRes.body);

        final userMap = profileData['user'] as Map<String, dynamic>;
        final emp   = userMap['employee'] as Map<String, dynamic>? ?? {};
        final prof  = userMap['profile']  as Map<String, dynamic>? ?? {};
        final uRole = (userMap['role'] ?? 'EMPLOYEE').toString().toUpperCase();

        final parsedUser = UserModel(
          id:          emp['id']?.toString() ?? userMap['id'].toString(),
          employeeId:  emp['employeeCode']?.toString() ?? userMap['id'].toString(),
          name:        prof['fullName']?.toString() ?? 
                       '${emp['firstName'] ?? ''} ${emp['lastName'] ?? ''}'.trim(),
          email:       prof['email']?.toString() ?? userMap['email']?.toString() ?? '',
          phone:       prof['phone']?.toString() ?? '',
          role:        (uRole == 'HR' || uRole == 'SUPER_ADMIN' || uRole == 'ADMIN' || uRole == 'PLATFORM_ADMIN')
              ? UserRole.hrManager
              : uRole == 'SALESMAN'
                  ? UserRole.salesman
                  : uRole == 'STORE_MANAGER'
                      ? UserRole.storeManager
                      : uRole == 'HELPER'
                          ? UserRole.helper
                          : UserRole.employee,
          department:  (emp['department'] is Map ? emp['department']['name'] : emp['department'])?.toString() ?? 'General',
          designation: emp['designation']?.toString() ?? 'Employee',
          joinDate:    DateTime.tryParse(emp['joinDate']?.toString() ?? '') ?? DateTime.now(),
          salary:      (prof['salary'] as num?)?.toDouble() ??
              (emp['salary'] as num?)?.toDouble() ?? 0.0,
          avatar:      prof['avatar']?.toString(),
          bankName:    emp['bankName']?.toString(),
          accountNumber: emp['accountNumber']?.toString(),
          ifscCode:    emp['ifscCode']?.toString(),
          accountType: emp['accountType']?.toString(),
          branchName:  emp['branchName']?.toString(),
        );

        UserModel hydratedUser = parsedUser;
        if (parsedUser.role != UserRole.hrManager) {
          final repo = ref.read(employeeRepositoryProvider);
          List<HopkidEmployeeModel> cache = await repo.getCachedEmployees();
          if (cache.isEmpty) {
            try {
              cache = await repo.refresh();
            } catch (e) {
              debugPrint('⚠️ Cold employee sync failed: $e');
            }
          }

          final cleanedPhone = parsedUser.phone.replaceAll(RegExp(r'\D'), '');
          HopkidEmployeeModel? matched;
          
          for (final emp in cache) {
            final cleanedEmpPhone = emp.mobileNo.replaceAll(RegExp(r'\D'), '');
            if (cleanedEmpPhone.isNotEmpty && cleanedPhone.isNotEmpty && cleanedPhone == cleanedEmpPhone) {
              matched = emp;
              break;
            }
          }
          
          if (matched == null) {
            for (final emp in cache) {
              if (emp.employeeCode.toUpperCase() == parsedUser.employeeId.toUpperCase()) {
                matched = emp;
                break;
              }
            }
          }

          if (matched != null) {
            hydratedUser = parsedUser.copyWith(
              hopkidEmployeeId: matched.employeeID,
              salary: matched.salary,
              commissionPercentage: matched.commissionPercentage,
              branchName: matched.branchName,
            );
            debugPrint('✅ [AUTH] Restored and mapped employee to HopKid ID: ${matched.employeeID}');
          } else {
            debugPrint('⚠️ [AUTH] Restored employee not found in HopKid master list: ${parsedUser.phone} / ${parsedUser.employeeId}');
          }
        }

        state = AuthState(currentUser: hydratedUser);
        _syncFcmTokenInBackground();
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Session restore failed: $e');
      // Clear invalid/expired session data so the app doesn't try to restore it next time
      try {
        await StorageService.clearSessionData();
      } catch (err) {
        debugPrint('⚠️ Failed to clear invalid session data: $err');
      }
      state = const AuthState();
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void logout() {
    // 1. Reset local AuthState synchronously so UI reacts instantly
    state = const AuthState();

    // 2. Invalidate all user-specific providers so they reset to default/empty state
    ref.invalidate(attendanceViewModelProvider);
    ref.invalidate(geofenceViewModelProvider);
    ref.invalidate(liveTrackingViewModelProvider);
    ref.invalidate(hrAttendanceViewModelProvider);
    ref.invalidate(expenseViewModelProvider);
    ref.invalidate(hrExpenseViewModelProvider);
    ref.invalidate(employeeListViewModelProvider);
    ref.invalidate(employeePayrollViewModelProvider);
    ref.invalidate(hrPayrollViewModelProvider);
    ref.invalidate(leaveViewModelProvider);
    ref.invalidate(hrLeaveViewModelProvider);
    ref.invalidate(taskViewModelProvider);
    ref.invalidate(hrTaskViewModelProvider);
    ref.invalidate(profileViewModelProvider);
    ref.invalidate(notificationViewModelProvider);
    ref.invalidate(documentViewModelProvider);
    ref.invalidate(shiftViewModelProvider);
    ref.invalidate(hrDashboardViewModelProvider);
    ref.invalidate(employeeDashboardViewModelProvider);
    ref.invalidate(holidayViewModelProvider);

    // 3. Perform background cleanup asynchronously
    _performCleanup();
  }

  Future<void> _performCleanup() async {
    try {
      await NotificationService().deleteFCMToken();
    } catch (e) {
      debugPrint('⚠️ FCM token unregistration failed: $e');
    }
    try {
      await ApiService.post(AppUrl.logout, {});
      debugPrint('✅ Backend logout successful');
    } catch (e) {
      debugPrint('⚠️ Backend logout failed: $e');
    }
    await StorageService.clearSessionData();
    debugPrint('🗑️ Session data cleared from storage');
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(ref);
});
