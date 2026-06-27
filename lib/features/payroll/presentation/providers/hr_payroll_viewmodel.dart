import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';

// ─── HR Payroll Stats ─────────────────────────────────────────────────────────

class HRPayrollStats {
  final int totalEmployees;
  final int activeEmployees;
  final double totalMonthlyPayroll;
  final double averageSalary;
  final String currency;

  const HRPayrollStats({
    this.totalEmployees = 0,
    this.activeEmployees = 0,
    this.totalMonthlyPayroll = 0.0,
    this.averageSalary = 0.0,
    this.currency = 'INR',
  });
}

// ─── Payroll Run ─────────────────────────────────────────────────────────────

class PayrollRun {
  final int id;
  final String officeName;
  final int employeeCount;
  final String lastRunDate;
  final String status;
  final double totalAmount;

  const PayrollRun({
    required this.id,
    required this.officeName,
    required this.employeeCount,
    required this.lastRunDate,
    required this.status,
    required this.totalAmount,
  });
}

// ─── HR Payroll State ─────────────────────────────────────────────────────────

class HRPayrollState {
  final HRPayrollStats stats;
  final List<PayrollRun> payrollRuns;
  final bool isLoading;
  final String? errorMessage;

  const HRPayrollState({
    this.stats = const HRPayrollStats(),
    this.payrollRuns = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  HRPayrollState copyWith({
    HRPayrollStats? stats,
    List<PayrollRun>? payrollRuns,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HRPayrollState(
      stats: stats ?? this.stats,
      payrollRuns: payrollRuns ?? this.payrollRuns,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── HR Payroll ViewModel ─────────────────────────────────────────────────────

class HRPayrollViewModel extends StateNotifier<HRPayrollState> {
  HRPayrollViewModel() : super(const HRPayrollState()) {
    fetchPayrollData();
  }

  Future<void> fetchPayrollData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await Future.wait([
        fetchPayrollStats(),
        fetchPayrollRuns(),
      ]);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> fetchPayrollStats() async {
    try {
      final res = await ApiService.get(AppUrl.hrPayrollStats);
      final data = jsonDecode(res.body);

      final statsData = data['data'];
      final stats = HRPayrollStats(
        totalEmployees: statsData['totalEmployees'] as int? ?? 0,
        activeEmployees: statsData['activeEmployees'] as int? ?? 0,
        totalMonthlyPayroll: (statsData['totalMonthlyPayroll'] as num?)?.toDouble() ?? 0.0,
        averageSalary: (statsData['averageSalary'] as num?)?.toDouble() ?? 0.0,
        currency: statsData['currency']?.toString() ?? 'INR',
      );

      state = state.copyWith(stats: stats, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> fetchPayrollRuns() async {
    try {
      final res = await ApiService.get(AppUrl.hrPayrollRuns);
      final data = jsonDecode(res.body);

      final runs = (data['payrollRuns'] as List?)
              ?.map((pr) => PayrollRun(
                    id: pr['id'] as int? ?? 0,
                    officeName: pr['officeName']?.toString() ?? '',
                    employeeCount: pr['employeeCount'] as int? ?? 0,
                    lastRunDate: pr['lastRunDate']?.toString() ?? '',
                    status: pr['status']?.toString() ?? 'unknown',
                    totalAmount: (pr['totalAmount'] as num?)?.toDouble() ?? 0.0,
                  ))
              .toList() ??
          [];

      state = state.copyWith(payrollRuns: runs, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final hrPayrollViewModelProvider =
    StateNotifierProvider<HRPayrollViewModel, HRPayrollState>((ref) {
  return HRPayrollViewModel();
});
