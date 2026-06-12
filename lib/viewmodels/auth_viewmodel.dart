import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  Future<bool> login(String employeeId, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    String? fcmToken = await StorageService.getFCMToken();
    if (fcmToken == null || fcmToken.isEmpty) {
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await StorageService.saveFCMToken(fcmToken);
        }
        debugPrint('🔑 FCM Token obtained for login: $fcmToken');
      } catch (e) {
        debugPrint('⚠️ Could not get FCM token for login: $e');
      }
    }

    // 1. Mobile login request - returns complete user data
    final loginRes = await ApiService.post(AppUrl.login, {
      'email': employeeId.trim(),
      'password': password.trim(),
      'fcmToken': fcmToken,
    });

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

    // 2. Parse user data from mobile login response
    final userMap = loginData['user'] as Map<String, dynamic>;
    final profMap = userMap['profile'] as Map<String, dynamic>? ?? {};
    final empMap = userMap['employee'] as Map<String, dynamic>? ?? {};

    final parsedUser = UserModel(
      id: userMap['id'].toString(),
      employeeId: empMap['employeeCode']?.toString() ?? userMap['id'].toString(),
      name: profMap['fullName']?.toString() ?? 
             (empMap['firstName']?.toString() ?? '') + ' ' + (empMap['lastName']?.toString() ?? '').trim(),
      email: profMap['email']?.toString() ?? userMap['email']?.toString() ?? employeeId.trim(),
      phone: profMap['phone']?.toString() ?? '',
      role: (userRole == 'HR' || userRole == 'SUPER_ADMIN' || userRole == 'ADMIN')
          ? UserRole.hrManager
          : UserRole.employee,
      department: empMap['department']?.toString() ?? 'General',
      designation: empMap['designation']?.toString() ?? 'Employee',
      joinDate: DateTime.tryParse(profMap['createdAt']?.toString() ?? empMap['joinDate']?.toString() ?? '') ?? DateTime.now(),
      salary: 0.0,
    );

    state = AuthState(currentUser: parsedUser);
    // Sync FCM token to backend now that user is logged in
    NotificationService().refreshToken();
    return true;
  }

  // ─── HR Login ────────────────────────────────────────────────────────────────

  Future<bool> hrLogin(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      String? fcmToken = await StorageService.getFCMToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null && fcmToken.isNotEmpty) {
            await StorageService.saveFCMToken(fcmToken);
          }
          debugPrint('🔑 FCM Token obtained for HR login: $fcmToken');
        } catch (e) {
          debugPrint('⚠️ Could not get FCM token for HR login: $e');
        }
      }

      // Use mobile login endpoint for HR users (same as employees)
      final loginRes = await ApiService.post(AppUrl.login, {
        'email': email.trim(),
        'password': password.trim(),
        'fcmToken': fcmToken,
      });

      final loginData = jsonDecode(loginRes.body);
      if (loginData['success'] != true) {
        final msg = loginData['message'] ?? 'HR login failed';
        state = state.copyWith(isLoading: false, errorMessage: msg);
        return false;
      }

      final token = loginData['token'] as String;
      final refreshToken = loginData['refreshToken'] as String? ?? '';
      final userRole = loginData['user']['role'].toString().toUpperCase();
      await ApiService.saveTokens(token, refreshToken, userRole);
      await StorageService.saveUserRole(userRole);

      // Parse user from mobile login response
      final userMap = loginData['user'] as Map<String, dynamic>;
      final profMap = userMap['profile'] as Map<String, dynamic>? ?? {};
      final empMap = userMap['employee'] as Map<String, dynamic>? ?? {};

      final parsedUser = UserModel(
        id: userMap['id'].toString(),
        employeeId: empMap['employeeCode']?.toString() ?? userMap['id'].toString(),
        name: profMap['fullName']?.toString() ?? 
               (empMap['firstName']?.toString() ?? '') + ' ' + (empMap['lastName']?.toString() ?? '').trim(),
        email: profMap['email']?.toString() ?? userMap['email']?.toString() ?? email.trim(),
        phone: profMap['phone']?.toString() ?? '',
        role: UserRole.hrManager,
        department: empMap['department']?.toString() ?? 'Human Resources',
        designation: empMap['designation']?.toString() ?? profMap['bio']?.toString() ?? 'HR Manager',
        joinDate: DateTime.tryParse(profMap['createdAt']?.toString() ?? empMap['joinDate']?.toString() ?? '') ?? DateTime.now(),
        salary: 0.0,
      );

      state = AuthState(currentUser: parsedUser);
      // Sync FCM token to backend now that user is logged in
      NotificationService().refreshToken();
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
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

        // HR profile endpoint returns a flat profile/user object
        final prof = (profileData['profile'] ?? profileData) as Map<String, dynamic>;
        final user = (profileData['user']   ?? {})           as Map<String, dynamic>;

        final parsedUser = UserModel(
          id:          (user['id'] ?? prof['userId'] ?? 0).toString(),
          employeeId:  (user['id'] ?? prof['userId'] ?? 0).toString(),
          name:        prof['fullName']?.toString() ?? 'HR Manager',
          email:       prof['email']?.toString()    ?? '',
          phone:       prof['phone']?.toString()    ?? '',
          role:        UserRole.hrManager,
          department:  'Human Resources',
          designation: prof['bio']?.toString() ?? 'HR Manager',
          joinDate:    DateTime.tryParse(prof['createdAt']?.toString() ?? '') ?? DateTime.now(),
          salary:      0.0,
        );

        state = AuthState(currentUser: parsedUser);
        // Sync FCM token to backend now that session is restored
        NotificationService().refreshToken();
        return true;
      } else {
        // ── Employee session restore ───────────────────────────────
        final profileRes = await ApiService.get(AppUrl.employeeProfile);
        final profileData = jsonDecode(profileRes.body);

        final emp   = profileData['employee'] as Map<String, dynamic>;
        final prof  = profileData['profile']  as Map<String, dynamic>;
        final uRole = (profileData['user']?['role'] ?? 'EMPLOYEE').toString().toUpperCase();

        final parsedUser = UserModel(
          id:          emp['id'].toString(),
          employeeId:  emp['employeeCode'].toString(),
          name:        emp['name'].toString(),
          email:       prof['email'].toString(),
          phone:       prof['phone'].toString(),
          role:        (uRole == 'HR' || uRole == 'SUPER_ADMIN' || uRole == 'ADMIN' || uRole == 'PLATFORM_ADMIN')
              ? UserRole.hrManager
              : UserRole.employee,
          department:  emp['department'].toString(),
          designation: emp['designation'].toString(),
          joinDate:    DateTime.tryParse(emp['joinDate'].toString()) ?? DateTime.now(),
          salary:      (prof['salary'] as num?)?.toDouble() ??
              (emp['salary'] as num?)?.toDouble() ?? 0.0,
        );

        state = AuthState(currentUser: parsedUser);
        // Sync FCM token to backend now that session is restored
        NotificationService().refreshToken();
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
