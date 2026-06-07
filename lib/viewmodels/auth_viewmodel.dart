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
    await ApiService.saveToken(token);

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

  Future<bool> restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    final profileRes = await ApiService.get(AppUrl.employeeProfile);
    final profileData = jsonDecode(profileRes.body);

    final emp = profileData['employee'];
    final prof = profileData['profile'];
    final uRole = (profileData['user']?['role'] ?? 'EMPLOYEE').toString().toUpperCase();

    final parsedUser = UserModel(
      id: emp['id'].toString(),
      employeeId: emp['employeeCode'].toString(),
      name: emp['name'].toString(),
      email: prof['email'].toString(),
      phone: prof['phone'].toString(),
      role: (uRole == 'HR' || uRole == 'SUPER_ADMIN' || uRole == 'ADMIN' || uRole == 'PLATFORM_ADMIN')
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
