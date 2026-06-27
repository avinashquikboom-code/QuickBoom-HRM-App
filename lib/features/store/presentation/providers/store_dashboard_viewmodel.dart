import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/store_service.dart';
import 'package:quickboom_hrm/features/store/data/store_models.dart';

class StoreDashboardState {
  final StoreDashboard? dashboard;
  final StoreEmployeeList? employees;
  final List<StorePerformance>? storePerformance;
  final bool isLoadingDashboard;
  final bool isLoadingEmployees;
  final bool isLoadingPerformance;
  final String? errorMessage;

  const StoreDashboardState({
    this.dashboard,
    this.employees,
    this.storePerformance,
    this.isLoadingDashboard = false,
    this.isLoadingEmployees = false,
    this.isLoadingPerformance = false,
    this.errorMessage,
  });

  StoreDashboardState copyWith({
    StoreDashboard? dashboard,
    StoreEmployeeList? employees,
    List<StorePerformance>? storePerformance,
    bool? isLoadingDashboard,
    bool? isLoadingEmployees,
    bool? isLoadingPerformance,
    String? errorMessage,
  }) {
    return StoreDashboardState(
      dashboard: dashboard ?? this.dashboard,
      employees: employees ?? this.employees,
      storePerformance: storePerformance ?? this.storePerformance,
      isLoadingDashboard: isLoadingDashboard ?? this.isLoadingDashboard,
      isLoadingEmployees: isLoadingEmployees ?? this.isLoadingEmployees,
      isLoadingPerformance: isLoadingPerformance ?? this.isLoadingPerformance,
      errorMessage: errorMessage,
    );
  }
}

class StoreDashboardViewModel extends StateNotifier<StoreDashboardState> {
  StoreDashboardViewModel() : super(const StoreDashboardState());

  // Fetch Store Dashboard
  Future<void> fetchDashboard() async {
    state = state.copyWith(isLoadingDashboard: true, errorMessage: null);
    try {
      debugPrint('🔄 Fetching store dashboard...');
      final dashboard = await StoreService.fetchStoreDashboard();
      state = state.copyWith(
        dashboard: dashboard,
        isLoadingDashboard: false,
        errorMessage: dashboard == null ? 'Failed to load store dashboard' : null,
      );
      debugPrint('✅ Store dashboard loaded');
    } catch (e) {
      debugPrint('❌ Error fetching store dashboard: $e');
      state = state.copyWith(
        isLoadingDashboard: false,
        errorMessage: 'Failed to load store dashboard',
      );
    }
  }

  // Fetch Store Employees
  Future<void> fetchEmployees({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? role,
  }) async {
    state = state.copyWith(isLoadingEmployees: true, errorMessage: null);
    try {
      debugPrint('🔄 Fetching store employees...');
      final employees = await StoreService.fetchStoreEmployees(
        page: page,
        limit: limit,
        search: search,
        status: status,
        role: role,
      );
      state = state.copyWith(
        employees: employees,
        isLoadingEmployees: false,
        errorMessage: employees == null ? 'Failed to load store employees' : null,
      );
      debugPrint('✅ Store employees loaded');
    } catch (e) {
      debugPrint('❌ Error fetching store employees: $e');
      state = state.copyWith(
        isLoadingEmployees: false,
        errorMessage: 'Failed to load store employees',
      );
    }
  }

  // Fetch Store Performance (for HR)
  Future<void> fetchStorePerformance({
    String? month,
    String? year,
  }) async {
    state = state.copyWith(isLoadingPerformance: true, errorMessage: null);
    try {
      debugPrint('🔄 Fetching store performance...');
      final performance = await StoreService.fetchStorePerformance(
        month: month,
        year: year,
      );
      state = state.copyWith(
        storePerformance: performance,
        isLoadingPerformance: false,
        errorMessage: performance == null ? 'Failed to load store performance' : null,
      );
      debugPrint('✅ Store performance loaded');
    } catch (e) {
      debugPrint('❌ Error fetching store performance: $e');
      state = state.copyWith(
        isLoadingPerformance: false,
        errorMessage: 'Failed to load store performance',
      );
    }
  }

  // Refresh all store data
  Future<void> refreshAll() async {
    await Future.wait([
      fetchDashboard(),
    ]);
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Provider
final storeDashboardViewModelProvider =
    StateNotifierProvider<StoreDashboardViewModel, StoreDashboardState>((ref) {
  return StoreDashboardViewModel();
});
