import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'auth_viewmodel.dart';

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
  EmployeeListViewModel(List<UserModel> employees)
      : super(EmployeeListState(
          employees:
              employees.where((e) => e.role == UserRole.employee).toList(),
        ));

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
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final employeeListViewModelProvider =
    StateNotifierProvider<EmployeeListViewModel, EmployeeListState>((ref) {
  final authVm = ref.read(authViewModelProvider.notifier);
  return EmployeeListViewModel(authVm.allUsers);
});
