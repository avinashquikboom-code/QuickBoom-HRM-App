import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../models/expense_model.dart';

// ─── HR Expense State ─────────────────────────────────────────────────────────

class HrExpenseState {
  final List<ExpenseModel> allExpenses;
  final bool isProcessing;
  final String? successMessage;

  const HrExpenseState({
    this.allExpenses = const [],
    this.isProcessing = false,
    this.successMessage,
  });

  List<ExpenseModel> get pendingExpenses =>
      allExpenses.where((e) => e.status == ExpenseStatus.pending).toList();

  List<ExpenseModel> get reviewedExpenses =>
      allExpenses.where((e) => e.status != ExpenseStatus.pending).toList();

  double get totalPendingAmount =>
      pendingExpenses.fold(0, (s, e) => s + e.amount);
  double get totalApprovedAmount => allExpenses
      .where((e) =>
          e.status == ExpenseStatus.approved ||
          e.status == ExpenseStatus.reimbursed)
      .fold(0, (s, e) => s + e.amount);

  HrExpenseState copyWith({
    List<ExpenseModel>? allExpenses,
    bool? isProcessing,
    String? successMessage,
    bool clearMessage = false,
  }) {
    return HrExpenseState(
      allExpenses: allExpenses ?? this.allExpenses,
      isProcessing: isProcessing ?? this.isProcessing,
      successMessage: clearMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ─── HR Expense ViewModel ─────────────────────────────────────────────────────

class HrExpenseViewModel extends StateNotifier<HrExpenseState> {
  HrExpenseViewModel() : super(const HrExpenseState()) {
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    try {
      final res = await ApiService.get('/api/hr/expenses');
      final data = jsonDecode(res.body);
      final List rawExpenses = data['expenses'] ?? [];
      final expenses = rawExpenses.map((e) => _parseExpense(e)).toList();

      state = state.copyWith(allExpenses: expenses);
    } catch (_) {
      state = state.copyWith(allExpenses: []);
    }
  }

  Future<void> approveExpense(String expenseId, String reviewerName) async {
    state = state.copyWith(isProcessing: true, clearMessage: true);
    try {
      await ApiService.post('/api/hr/expenses/$expenseId/approve', {
        'reviewerName': reviewerName,
        'reviewNote': 'Approved',
      });

      await fetchExpenses();
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Expense approved successfully.',
      );
    } catch (error) {
      state = state.copyWith(
        isProcessing: false,
        successMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> rejectExpense(
      String expenseId, String reviewerName, String note) async {
    state = state.copyWith(isProcessing: true, clearMessage: true);
    try {
      await ApiService.post('/api/hr/expenses/$expenseId/reject', {
        'reviewerName': reviewerName,
        'reviewNote': note.isEmpty ? 'Rejected' : note,
      });

      await fetchExpenses();
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Expense rejected.',
      );
    } catch (error) {
      state = state.copyWith(
        isProcessing: false,
        successMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearMessage() => state = state.copyWith(clearMessage: true);

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
      department: e['department']?.toString() ?? '',
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
}

final hrExpenseViewModelProvider =
    StateNotifierProvider<HrExpenseViewModel, HrExpenseState>((ref) {
  return HrExpenseViewModel();
});
