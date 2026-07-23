import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/features/auth/data/models/user_model.dart';
import 'package:quickboom_hrm/features/employees/data/models/hopkid_employee_model.dart';
import 'package:quickboom_hrm/features/employees/presentation/providers/employee_repository_provider.dart';

// ─── Employee List State ──────────────────────────────────────────────────────

class EmployeeListState {
  final List<HopkidEmployeeModel> employees;
  final String searchQuery;
  final String? selectedBranch;
  final bool showOnlyActive;
  final bool isLoading;

  const EmployeeListState({
    this.employees = const [],
    this.searchQuery = '',
    this.selectedBranch,
    this.showOnlyActive = true,
    this.isLoading = false,
  });

  List<UserModel> get filteredEmployees {
    final list = employees.where((emp) {
      final q = searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          emp.employeeName.toLowerCase().contains(q) ||
          emp.employeeCode.toLowerCase().contains(q) ||
          emp.branchName.toLowerCase().contains(q);
      
      final matchesActive = !showOnlyActive || emp.isActive;
      
      final matchesBranch = selectedBranch == null ||
          emp.branchName == selectedBranch;
      
      return matchesSearch && matchesActive && matchesBranch;
    });

    return list.map((emp) => UserModel(
      id: emp.employeeID.isNotEmpty ? emp.employeeID : emp.employeeCode,
      employeeId: emp.employeeCode,
      name: emp.employeeName,
      email: emp.email ?? '',
      phone: emp.mobileNo,
      role: UserRole.employee,
      department: emp.branchName,
      designation: emp.isActive ? 'Active Employee' : 'Inactive Employee',
      joinDate: DateTime.tryParse(emp.dateofJoining ?? '') ?? DateTime.now(),
      salary: emp.salary,
      branchName: emp.branchName,
      hopkidEmployeeId: emp.employeeID,
      commissionPercentage: emp.commissionPercentage,
    )).toList();
  }

  List<String> get branches {
    final distinct = employees
        .map((e) => e.branchName)
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList();
    distinct.sort();
    return distinct;
  }

  EmployeeListState copyWith({
    List<HopkidEmployeeModel>? employees,
    String? searchQuery,
    String? selectedBranch,
    bool? showOnlyActive,
    bool? isLoading,
    bool clearBranchFilter = false,
  }) {
    return EmployeeListState(
      employees: employees ?? this.employees,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedBranch:
          clearBranchFilter ? null : (selectedBranch ?? this.selectedBranch),
      showOnlyActive: showOnlyActive ?? this.showOnlyActive,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Employee List ViewModel (HR) ─────────────────────────────────────────────

class EmployeeListViewModel extends StateNotifier<EmployeeListState> {
  final Ref ref;

  EmployeeListViewModel(this.ref) : super(const EmployeeListState()) {
    fetchEmployees();
  }

  Future<void> fetchEmployees({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(employeeRepositoryProvider);
      final list = forceRefresh ? await repo.refresh() : await repo.fetchAndCache();
      state = state.copyWith(employees: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void filterByBranch(String? branch) {
    if (branch == null) {
      state = state.copyWith(clearBranchFilter: true);
    } else {
      state = state.copyWith(selectedBranch: branch);
    }
  }

  void toggleShowOnlyActive(bool val) {
    state = state.copyWith(showOnlyActive: val);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final employeeListViewModelProvider =
    StateNotifierProvider<EmployeeListViewModel, EmployeeListState>((ref) {
  return EmployeeListViewModel(ref);
});
