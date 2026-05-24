import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  HrExpenseViewModel()
      : super(HrExpenseState(allExpenses: _generateMockExpenses()));

  Future<void> approveExpense(String expenseId, String reviewerName) async {
    state = state.copyWith(isProcessing: true, clearMessage: true);
    await Future.delayed(const Duration(milliseconds: 700));

    final updated = state.allExpenses.map((e) {
      if (e.id == expenseId) {
        return e.copyWith(
          status: ExpenseStatus.approved,
          reviewedBy: reviewerName,
          reviewNote: 'Approved',
        );
      }
      return e;
    }).toList();

    state = state.copyWith(
      allExpenses: updated,
      isProcessing: false,
      successMessage: 'Expense approved successfully.',
    );
  }

  Future<void> rejectExpense(
      String expenseId, String reviewerName, String note) async {
    state = state.copyWith(isProcessing: true, clearMessage: true);
    await Future.delayed(const Duration(milliseconds: 700));

    final updated = state.allExpenses.map((e) {
      if (e.id == expenseId) {
        return e.copyWith(
          status: ExpenseStatus.rejected,
          reviewedBy: reviewerName,
          reviewNote: note.isEmpty ? 'Rejected' : note,
        );
      }
      return e;
    }).toList();

    state = state.copyWith(
      allExpenses: updated,
      isProcessing: false,
      successMessage: 'Expense rejected.',
    );
  }

  void clearMessage() => state = state.copyWith(clearMessage: true);

  static List<ExpenseModel> _generateMockExpenses() {
    final now = DateTime.now();
    return [
      ExpenseModel(
        id: 'EXP001',
        employeeId: 'QB001',
        employeeName: 'Rahul Sharma',
        department: 'Engineering',
        category: ExpenseCategory.travel,
        amount: 1850,
        description: 'Cab to client office and back',
        date: now.subtract(const Duration(days: 5)),
        status: ExpenseStatus.approved,
        submittedOn: now.subtract(const Duration(days: 5)),
        reviewedBy: 'Sarah Johnson',
        reviewNote: 'Approved',
        hasReceipt: true,
      ),
      ExpenseModel(
        id: 'EXP002',
        employeeId: 'QB002',
        employeeName: 'Priya Patel',
        department: 'Design',
        category: ExpenseCategory.stationery,
        amount: 780,
        description: 'Design tools and notebook',
        date: now.subtract(const Duration(days: 3)),
        status: ExpenseStatus.pending,
        submittedOn: now.subtract(const Duration(days: 3)),
        hasReceipt: true,
      ),
      ExpenseModel(
        id: 'EXP003',
        employeeId: 'QB001',
        employeeName: 'Rahul Sharma',
        department: 'Engineering',
        category: ExpenseCategory.stationery,
        amount: 340,
        description: 'Office supplies',
        date: now.subtract(const Duration(days: 2)),
        status: ExpenseStatus.pending,
        submittedOn: now.subtract(const Duration(days: 2)),
        hasReceipt: false,
      ),
      ExpenseModel(
        id: 'EXP004',
        employeeId: 'QB004',
        employeeName: 'Sneha Verma',
        department: 'Marketing',
        category: ExpenseCategory.travel,
        amount: 2100,
        description: 'Client meeting travel expenses',
        date: now.subtract(const Duration(days: 1)),
        status: ExpenseStatus.pending,
        submittedOn: now.subtract(const Duration(days: 1)),
        hasReceipt: true,
      ),
      ExpenseModel(
        id: 'EXP005',
        employeeId: 'QB005',
        employeeName: 'Deepak Nair',
        department: 'Finance',
        category: ExpenseCategory.food,
        amount: 950,
        description: 'Team dinner after quarterly review',
        date: now.subtract(const Duration(days: 7)),
        status: ExpenseStatus.reimbursed,
        submittedOn: now.subtract(const Duration(days: 7)),
        reviewedBy: 'Sarah Johnson',
        hasReceipt: true,
      ),
    ];
  }
}

final hrExpenseViewModelProvider =
    StateNotifierProvider<HrExpenseViewModel, HrExpenseState>((ref) {
  return HrExpenseViewModel();
});
