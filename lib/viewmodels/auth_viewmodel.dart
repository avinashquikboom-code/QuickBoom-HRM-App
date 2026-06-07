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

    // 1. Live login request
    final loginRes = await ApiService.post(AppUrl.login, {
      'email': employeeId.trim(),
      'password': password.trim(),
      'fcmToken': fcmToken,
    });

    final loginData = jsonDecode(loginRes.body);
    final token = loginData['token'];
    await ApiService.saveToken(token, 'EMPLOYEE');
    await StorageService.saveUserRole('EMPLOYEE');

    // Refresh FCM token on backend after successful login
    try {
      await NotificationService().refreshToken();
    } catch (e) {
      debugPrint('⚠️ Failed to refresh FCM token after login: $e');
    }

    // 2. Live profile request
    final profileRes = await ApiService.get(AppUrl.employeeProfile);
    final profileData = jsonDecode(profileRes.body);

    final emp = profileData['employee'];
    final prof = profileData['profile'];
    final uRole = loginData['user']['role'].toString().toUpperCase();

    final parsedUser = UserModel(
      id: emp['id'].toString(),
      employeeId: emp['employeeCode'].toString(),
      name: emp['name'].toString(),
      email: prof['email'].toString(),
      phone: prof['phone'].toString(),
      role: (uRole == 'HR' || uRole == 'SUPER_ADMIN' || uRole == 'ADMIN')
          ? UserRole.hrManager
          : UserRole.employee,
      department: emp['department'].toString(),
      designation: emp['designation'].toString(),
      joinDate: DateTime.tryParse(emp['joinDate'].toString()) ?? DateTime.now(),
      salary: (prof['salary'] as num?)?.toDouble() ??
          (emp['salary'] as num?)?.toDouble() ?? 0.0,
    );

    state = AuthState(currentUser: parsedUser);
    return true;
  }

  // ─── HR Login ────────────────────────────────────────────────────────────────

  Future<bool> hrLogin(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 1. HR login request — no FCM token required for web-based HR
      final loginRes = await ApiService.post(AppUrl.hrLogin, {
        'email': email.trim(),
        'password': password.trim(),
      });

      final loginData = jsonDecode(loginRes.body);
      if (loginData['success'] != true) {
        final msg = loginData['message'] ?? 'HR login failed';
        state = state.copyWith(isLoading: false, errorMessage: msg);
        return false;
      }

      final token = loginData['token'] as String;
      await ApiService.saveToken(token, 'HR');
      await StorageService.saveUserRole('HR');

      // 2. Parse user from login response (HR endpoint returns full user)
      final userMap  = loginData['user']  as Map<String, dynamic>;
      final profMap  = userMap['profile'] as Map<String, dynamic>;

      final parsedUser = UserModel(
        id:          userMap['id'].toString(),
        employeeId:  userMap['id'].toString(),
        name:        profMap['fullName']?.toString() ?? 'HR Manager',
        email:       profMap['email']?.toString()    ?? email.trim(),
        phone:       profMap['phone']?.toString()    ?? '',
        role:        UserRole.hrManager,
        department:  'Human Resources',
        designation: profMap['bio']?.toString()       ?? 'HR Manager',
        joinDate:    DateTime.tryParse(profMap['createdAt']?.toString() ?? '') ?? DateTime.now(),
        salary:      0.0,
      );

      state = AuthState(currentUser: parsedUser);
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
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Session restore failed: $e');
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
    final fcmToken = await StorageService.getFCMToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      try {
        await ApiService.post(AppUrl.logout, {
          'fcmToken': fcmToken,
        });
        debugPrint('✅ Backend logout successful');
      } catch (e) {
        debugPrint('⚠️ Backend logout failed: $e');
      }
    }
    await StorageService.clearSessionData();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel();
});
