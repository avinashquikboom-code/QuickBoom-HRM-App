import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';

// ─── Expense State (Employee) ──────────────────────────────────────────────────

class ExpenseState {
  final List<ExpenseModel> myExpenses;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const ExpenseState({
    this.myExpenses = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  double get totalSubmitted =>
      myExpenses.fold(0, (s, e) => s + e.amount);
  double get totalApproved => myExpenses
      .where((e) =>
          e.status == ExpenseStatus.approved ||
          e.status == ExpenseStatus.reimbursed)
      .fold(0.0, (sum, e) => sum + e.amount);
  double get totalPending => myExpenses
      .where((e) => e.status == ExpenseStatus.pending)
      .fold(0.0, (sum, e) => sum + e.amount);

  ExpenseState copyWith({
    List<ExpenseModel>? myExpenses,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ExpenseState(
      myExpenses: myExpenses ?? this.myExpenses,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ─── Expense ViewModel ────────────────────────────────────────────────────────

class ExpenseViewModel extends StateNotifier<ExpenseState> {
  ExpenseViewModel() : super(const ExpenseState()) {
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiService.get('/api/employee/expenses');
      final data = jsonDecode(res.body);
      final List rawExpenses = data['expenses'] ?? [];
      final expenses = rawExpenses.map((e) => _parseExpense(e)).toList();

      state = state.copyWith(
        myExpenses: expenses,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> submitExpense({
    required UserModel user,
    required ExpenseCategory category,
    required double amount,
    required String description,
    required DateTime date,
    bool hasReceipt = false,
  }) async {
    state = state.copyWith(isSubmitting: true, clearMessages: true);
        status: ExpenseStatus.reimbursed,
        submittedOn: now.subtract(const Duration(days: 10)),
        reviewedBy: 'Sarah Johnson',
        reviewNote: 'Reimbursed via payroll',
        hasReceipt: true,
      ),
      ExpenseModel(
        id: 'EXP003',
        employeeId: 'QB001',
        employeeName: 'Rahul Sharma',
        department: 'Engineering',
        category: ExpenseCategory.stationery,
        amount: 340,
        description: 'Office supplies — notepads and pens',
        date: now.subtract(const Duration(days: 2)),
        status: ExpenseStatus.pending,
        submittedOn: now.subtract(const Duration(days: 2)),
        hasReceipt: false,
      ),
      ExpenseModel(
        id: 'EXP004',
        employeeId: 'QB001',
        employeeName: 'Rahul Sharma',
        department: 'Engineering',
        category: ExpenseCategory.travel,
        amount: 3200,
        description: 'Flight ticket to Bangalore for tech conference',
        date: now.subtract(const Duration(days: 20)),
        status: ExpenseStatus.rejected,
        submittedOn: now.subtract(const Duration(days: 20)),
        reviewedBy: 'Sarah Johnson',
        reviewNote: 'Policy limit exceeded. Max ₹2500 for domestic travel.',
        hasReceipt: true,
      ),
    ];
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final expenseViewModelProvider =
    StateNotifierProvider<ExpenseViewModel, ExpenseState>((ref) {
  return ExpenseViewModel();
});
