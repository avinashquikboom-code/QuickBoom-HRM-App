import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../models/user_model.dart';

// ─── Mock Users ──────────────────────────────────────────────────────────────

List<UserModel> _buildMockUsers() {
  return [
    UserModel(
      id: '1',
      employeeId: 'HR001',
      name: 'Sarah Johnson',
      email: 'sarah.j@company.com',
      phone: '+91 98765 43210',
      role: UserRole.hrManager,
      department: 'Human Resources',
      designation: 'HR Manager',
      joinDate: DateTime(2020, 1, 15),
      salary: 85000,
    ),
    UserModel(
      id: '2',
      employeeId: 'QB001',
      name: 'Rahul Sharma',
      email: 'rahul.s@company.com',
      phone: '+91 87654 32109',
      role: UserRole.employee,
      department: 'Engineering',
      designation: 'Senior Developer',
      joinDate: DateTime(2022, 3, 10),
      salary: 65000,
    ),
  ];
}

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

  final List<UserModel> _allUsers = _buildMockUsers();

  List<UserModel> get allUsers => _allUsers;

  List<UserModel> get allEmployees =>
      _allUsers.where((u) => u.role == UserRole.employee).toList();

  Future<bool> login(String employeeId, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 1. Live login request
      final loginRes = await ApiService.post('/api/auth/login', {
        'email': employeeId.trim(),
        'password': password.trim(),
      });

      final loginData = jsonDecode(loginRes.body);
      final token = loginData['token'];
      await ApiService.saveToken(token);

      // 2. Live profile request
      final profileRes = await ApiService.get('/api/employee/profile');
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
        salary: double.tryParse(prof['clearanceLevel'].toString()) != null
            ? 65000.0 // placeholder salary
            : 65000.0,
      );

      state = AuthState(currentUser: parsedUser);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> restoreSession() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profileRes = await ApiService.get('/api/employee/profile');
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
        salary: 65000.0,
      );

      state = AuthState(currentUser: parsedUser);
      return true;
    } catch (error) {
      await ApiService.clearToken();
      state = const AuthState();
      return false;
    }
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
