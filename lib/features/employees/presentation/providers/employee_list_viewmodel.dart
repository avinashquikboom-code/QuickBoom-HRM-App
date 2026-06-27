import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/features/auth/data/models/user_model.dart';

// ─── Employee List State ──────────────────────────────────────────────────────

class EmployeeListState {
  final List<UserModel> employees;
  final String searchQuery;
  final String? selectedDepartment;
  final bool isLoading;

  const EmployeeListState({
    this.employees = const [],
    this.searchQuery = '',
    this.selectedDepartment,
    this.isLoading = false,
  });

  List<UserModel> get filteredEmployees {
    return employees.where((emp) {
      final q = searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          emp.name.toLowerCase().contains(q) ||
          emp.employeeId.toLowerCase().contains(q) ||
          emp.designation.toLowerCase().contains(q) ||
          emp.department.toLowerCase().contains(q);
      final matchesDept = selectedDepartment == null ||
          emp.department == selectedDepartment;
      return matchesSearch && matchesDept;
    }).toList();
  }

  List<String> get departments {
    final depts = employees.map((e) => e.department).toSet().toList();
    depts.sort();
    return depts;
  }

  EmployeeListState copyWith({
    List<UserModel>? employees,
    String? searchQuery,
    String? selectedDepartment,
    bool? isLoading,
    bool clearDeptFilter = false,
  }) {
    return EmployeeListState(
      employees: employees ?? this.employees,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDepartment:
          clearDeptFilter ? null : (selectedDepartment ?? this.selectedDepartment),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Employee List ViewModel (HR) ─────────────────────────────────────────────

class EmployeeListViewModel extends StateNotifier<EmployeeListState> {
  EmployeeListViewModel() : super(const EmployeeListState()) {
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiService.get(AppUrl.hrEmployees);
      final data = jsonDecode(res.body);
      final List rawEmployees = data['employees'] ?? [];
      final employees = rawEmployees.map((e) => _parseEmployee(e)).toList();

      state = state.copyWith(employees: employees, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void filterByDepartment(String? department) {
    if (department == null) {
      state = state.copyWith(clearDeptFilter: true);
    } else {
      state = state.copyWith(selectedDepartment: department);
    }
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  UserModel _parseEmployee(Map<String, dynamic> e) {
    return UserModel(
      id: e['id']?.toString() ?? '',
      employeeId: e['employeeCode']?.toString() ?? e['employeeId']?.toString() ?? '',
      name: e['name']?.toString() ?? '',
      email: e['email']?.toString() ?? '',
      phone: e['phone']?.toString() ?? '',
      role: UserRole.employee,
      department: (e['department'] is Map ? e['department']['name'] : e['department'])?.toString() ?? '',
      designation: e['designation']?.toString() ?? '',
      joinDate: e['joinDate'] != null ? DateTime.tryParse(e['joinDate'].toString()) ?? DateTime.now() : DateTime.now(),
      salary: (e['salary'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final employeeListViewModelProvider =
    StateNotifierProvider<EmployeeListViewModel, EmployeeListState>((ref) {
  return EmployeeListViewModel();
});
