import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../core/constants/app_url.dart';
import '../core/services/notification_service.dart';
import '../models/user_model.dart';

// ─── Auth State ──────────────────────────────────────────────────────────────

class AuthState {
  final bool isLoading;
  final UserModel? currentUser;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.currentUser,
    this.errorMessage,
  });

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({
    bool? isLoading,
    UserModel? currentUser,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      currentUser: currentUser ?? this.currentUser,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── Auth ViewModel ───────────────────────────────────────────────────────────

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel() : super(const AuthState());

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
        userRole == 'ADMIN';

    return UserModel(
      id: userMap['id'].toString(),
      employeeId: empMap['employeeCode']?.toString() ?? userMap['id'].toString(),
      name: profMap['fullName']?.toString() ??
          '${empMap['firstName']?.toString() ?? ''} ${empMap['lastName']?.toString() ?? ''}'.trim(),
      email: profMap['email']?.toString() ??
          userMap['email']?.toString() ??
          fallbackEmail.trim(),
      phone: profMap['phone']?.toString() ?? '',
      role: isHrRole ? UserRole.hrManager : UserRole.employee,
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
    );
  }

  Future<bool> _performLogin(
    String email,
    String password, {
    required bool forceHrRole,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Use cached FCM only — do not await FirebaseMessaging.getToken() here
      final fcmToken = await _getCachedFcmToken();

      final loginRes = await ApiService.post(
        AppUrl.login,
        {
          'email': email.trim(),
          'password': password.trim(),
          if (fcmToken != null) 'fcmToken': fcmToken,
        },
        timeout: ApiService.loginTimeout,
      );

      final loginData = jsonDecode(loginRes.body);
      if (loginData['success'] != true) {
        final msg = loginData['message'] ?? 'Login failed';
        state = state.copyWith(isLoading: false, errorMessage: msg);
        return false;
      }

      final token = loginData['token'] as String;
      final refreshToken = loginData['refreshToken'] as String? ?? '';
      final userRole = loginData['user']['role'].toString().toUpperCase();
      await ApiService.saveTokens(token, refreshToken, userRole);
      await StorageService.saveUserRole(userRole);

      final parsedUser = _parseUserFromLoginResponse(
        loginData,
        email,
        forceHrRole: forceHrRole,
      );

      state = AuthState(currentUser: parsedUser);

      // Sync FCM in background (handles missing cached token without blocking login)
      _syncFcmTokenInBackground();
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> login(String employeeId, String password) =>
      _performLogin(employeeId, password, forceHrRole: false);

  Future<bool> hrLogin(String email, String password) =>
      _performLogin(email, password, forceHrRole: true);

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
              : UserRole.employee,
          department:  (emp['department'] is Map ? emp['department']['name'] : emp['department'])?.toString() ?? 'General',
          designation: emp['designation']?.toString() ?? 'Employee',
          joinDate:    DateTime.tryParse(emp['joinDate']?.toString() ?? '') ?? DateTime.now(),
          salary:      (prof['salary'] as num?)?.toDouble() ??
              (emp['salary'] as num?)?.toDouble() ?? 0.0,
        );

        state = AuthState(currentUser: parsedUser);
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

    // 2. Perform background cleanup asynchronously
    _performCleanup();
  }

  Future<void> _performCleanup() async {
    try {
      await ApiService.post(AppUrl.logout, {});
      debugPrint('✅ Backend logout successful');
    } catch (e) {
      debugPrint('⚠️ Backend logout failed: $e');
    }
    await StorageService.clearSessionData();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel();
});
