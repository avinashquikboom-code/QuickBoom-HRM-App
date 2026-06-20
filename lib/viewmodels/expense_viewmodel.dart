import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_url.dart';
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

  ExpenseModel _parseExpense(Map<String, dynamic> e) {
    ExpenseCategory category;
    switch (e['category']?.toString().toLowerCase()) {
      case 'travel':
        category = ExpenseCategory.travel;
        break;
      case 'food':
        category = ExpenseCategory.food;
        break;
      case 'accommodation':
        category = ExpenseCategory.accommodation;
        break;
      case 'stationery':
        category = ExpenseCategory.stationery;
        break;
      case 'medical':
        category = ExpenseCategory.medical;
        break;
      default:
        category = ExpenseCategory.other;
    }

    ExpenseStatus status;
    switch (e['status']?.toString().toLowerCase()) {
      case 'approved':
        status = ExpenseStatus.approved;
        break;
      case 'rejected':
        status = ExpenseStatus.rejected;
        break;
      case 'reimbursed':
        status = ExpenseStatus.reimbursed;
        break;
      default:
        status = ExpenseStatus.pending;
    }

    return ExpenseModel(
      id: e['id']?.toString() ?? '',
      employeeId: e['employeeId']?.toString() ?? '',
      employeeName: e['employeeName']?.toString() ?? '',
      department: (e['department'] is Map ? e['department']['name'] : e['department'])?.toString() ?? '',
      category: category,
      amount: (e['amount'] as num?)?.toDouble() ?? 0.0,
      description: e['description']?.toString() ?? '',
      date: e['date'] != null ? DateTime.parse(e['date']) : DateTime.now(),
      status: status,
      submittedOn: e['submittedOn'] != null ? DateTime.parse(e['submittedOn']) : DateTime.now(),
      reviewedBy: e['reviewedBy']?.toString(),
      reviewNote: e['reviewNote']?.toString(),
      hasReceipt: e['hasReceipt'] ?? false,
    );
  }

  Future<void> fetchExpenses() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiService.get(AppUrl.employeeExpenses);
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
    try {
      final categoryStr = category.toString().split('.').last; // e.g. "travel"
      final res = await ApiService.post(AppUrl.employeeExpenses, {
        'category': categoryStr,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
        'imageBase64': null, // for potential picture receipt base64 data
      });
      final data = jsonDecode(res.body);
      final newExpense = _parseExpense(data['expense']);

      state = state.copyWith(
        myExpenses: [newExpense, ...state.myExpenses],
        isSubmitting: false,
        successMessage: 'Expense filed successfully!',
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final expenseViewModelProvider =
    StateNotifierProvider<ExpenseViewModel, ExpenseState>((ref) {
  return ExpenseViewModel();
});
