import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

// ─── Mock Users ──────────────────────────────────────────────────────────────

List<UserModel> _buildMockUsers() {
  return [
    UserModel(
      id: '1',
      employeeId: 'HR001',
      name: 'Sarah Johnson',
      email: 'sarah.j@quickboom.com',
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
      email: 'rahul.s@quickboom.com',
      phone: '+91 87654 32109',
      role: UserRole.employee,
      department: 'Engineering',
      designation: 'Senior Developer',
      joinDate: DateTime(2022, 3, 10),
      salary: 65000,
    ),
    UserModel(
      id: '3',
      employeeId: 'QB002',
      name: 'Priya Patel',
      email: 'priya.p@quickboom.com',
      phone: '+91 76543 21098',
      role: UserRole.employee,
      department: 'Design',
      designation: 'UI/UX Designer',
      joinDate: DateTime(2021, 6, 20),
      salary: 62000,
    ),
    UserModel(
      id: '4',
      employeeId: 'QB003',
      name: 'Amit Kumar',
      email: 'amit.k@quickboom.com',
      phone: '+91 65432 10987',
      role: UserRole.employee,
      department: 'Engineering',
      designation: 'Backend Developer',
      joinDate: DateTime(2023, 1, 5),
      salary: 70000,
    ),
    UserModel(
      id: '5',
      employeeId: 'QB004',
      name: 'Sneha Verma',
      email: 'sneha.v@quickboom.com',
      phone: '+91 54321 09876',
      role: UserRole.employee,
      department: 'Marketing',
      designation: 'Marketing Executive',
      joinDate: DateTime(2022, 8, 15),
      salary: 55000,
    ),
    UserModel(
      id: '6',
      employeeId: 'QB005',
      name: 'Deepak Nair',
      email: 'deepak.n@quickboom.com',
      phone: '+91 43210 98765',
      role: UserRole.employee,
      department: 'Finance',
      designation: 'Finance Analyst',
      joinDate: DateTime(2021, 11, 1),
      salary: 68000,
    ),
    UserModel(
      id: '7',
      employeeId: 'QB006',
      name: 'Kavya Reddy',
      email: 'kavya.r@quickboom.com',
      phone: '+91 32109 87654',
      role: UserRole.employee,
      department: 'Design',
      designation: 'Graphic Designer',
      joinDate: DateTime(2023, 4, 12),
      salary: 52000,
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
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      final user = _allUsers.firstWhere(
        (u) => u.employeeId.toUpperCase() == employeeId.trim().toUpperCase(),
        orElse: () => throw Exception('not_found'),
      );

      final validPassword =
          user.role == UserRole.hrManager ? 'hr123' : 'emp123';

      if (password.trim() != validPassword) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid password. Please try again.',
        );
        return false;
      }

      state = AuthState(currentUser: user);
      return true;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Employee ID not found. Please check and retry.',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void logout() {
    state = const AuthState();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel();
});
