import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/hr_reports_service.dart';

// ─── Attendance Trend Data ─────────────────────────────────────────────────

class AttendanceTrendData {
  final String date;
  final String day;
  final int present;
  final int absent;
  final int late;
  final int onLeave;

  const AttendanceTrendData({
    required this.date,
    required this.day,
    required this.present,
    required this.absent,
    required this.late,
    required this.onLeave,
  });
}

// ─── Expense Data ─────────────────────────────────────────────────────────

class ExpenseData {
  final int id;
  final String employeeId;
  final String employeeName;
  final String department;
  final String category;
  final double amount;
  final String date;
  final String status;

  const ExpenseData({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.category,
    required this.amount,
    required this.date,
    required this.status,
  });
}

// ─── HR Reports State ─────────────────────────────────────────────────────

class HRReportsState {
  final List<AttendanceTrendData> attendanceTrend;
  final List<ExpenseData> expenses;
  final bool isLoading;
  final String? errorMessage;

  const HRReportsState({
    this.attendanceTrend = const [],
    this.expenses = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  HRReportsState copyWith({
    List<AttendanceTrendData>? attendanceTrend,
    List<ExpenseData>? expenses,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HRReportsState(
      attendanceTrend: attendanceTrend ?? this.attendanceTrend,
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── HR Reports ViewModel ─────────────────────────────────────────────────

class HRReportsViewModel extends StateNotifier<HRReportsState> {
  HRReportsViewModel() : super(const HRReportsState()) {
    fetchReportsData();
  }

  Future<void> fetchReportsData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await Future.wait([
        fetchAttendanceTrend(),
        fetchExpenses(),
      ]);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> fetchAttendanceTrend() async {
    try {
      final data = await HRReportsService.fetchAttendanceTrend();
      if (data != null) {
        final trend = data.map((item) => AttendanceTrendData(
          date: item['date']?.toString() ?? '',
          day: item['day']?.toString() ?? '',
          present: item['present'] as int? ?? 0,
          absent: item['absent'] as int? ?? 0,
          late: item['late'] as int? ?? 0,
          onLeave: item['onLeave'] as int? ?? 0,
        )).toList();
        state = state.copyWith(attendanceTrend: trend, isLoading: false);
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> fetchExpenses() async {
    try {
      final data = await HRReportsService.fetchExpenses();
      if (data != null) {
        final expenses = data.map((item) => ExpenseData(
          id: item['id'] as int? ?? 0,
          employeeId: item['employeeId']?.toString() ?? '',
          employeeName: item['employeeName']?.toString() ?? '',
          department: item['department']?.toString() ?? '',
          category: item['category']?.toString() ?? '',
          amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
          date: item['date']?.toString() ?? '',
          status: item['status']?.toString() ?? '',
        )).toList();
        state = state.copyWith(expenses: expenses, isLoading: false);
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // Get attendance summary for pie chart
  Map<String, int> getAttendanceSummary() {
    int totalPresent = 0;
    int totalAbsent = 0;
    int totalLate = 0;
    int totalLeave = 0;

    for (var day in state.attendanceTrend) {
      totalPresent += day.present;
      totalAbsent += day.absent;
      totalLate += day.late;
      totalLeave += day.onLeave;
    }

    return {
      'present': totalPresent,
      'absent': totalAbsent,
      'late': totalLate,
      'leave': totalLeave,
    };
  }

  // Get monthly expense data grouped by month
  Map<String, Map<String, int>> getMonthlyExpenseData() {
    final Map<String, Map<String, int>> monthlyData = {};
    
    for (var expense in state.expenses) {
      final date = DateTime.parse(expense.date);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {'approved': 0, 'pending': 0};
      }
      
      if (expense.status == 'APPROVED') {
        monthlyData[monthKey]!['approved'] = (monthlyData[monthKey]!['approved'] ?? 0) + 1;
      } else if (expense.status == 'PENDING') {
        monthlyData[monthKey]!['pending'] = (monthlyData[monthKey]!['pending'] ?? 0) + 1;
      }
    }
    
    return monthlyData;
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────

final hrReportsViewModelProvider =
    StateNotifierProvider<HRReportsViewModel, HRReportsState>((ref) {
  return HRReportsViewModel();
});
