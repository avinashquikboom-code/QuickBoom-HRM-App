import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_url.dart';
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

    // 1. Live login request
    final loginRes = await ApiService.post(AppUrl.login, {
      'email': employeeId.trim(),
      'password': password.trim(),
    });

    final loginData = jsonDecode(loginRes.body);
    final token = loginData['token'];
    await ApiService.saveToken(token);

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
    ApiService.clearToken();
    state = const AuthState();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel();
});
