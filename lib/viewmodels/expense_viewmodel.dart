import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';

// ─── Expense State (Employee) ──────────────────────────────────────────────────

class ExpenseState {
  final List<ExpenseModel> myExpenses;
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;

  const ExpenseState({
    this.myExpenses = const [],
    this.isSubmitting = false,
    this.successMessage,
    this.errorMessage,
  });

  double get totalSubmitted =>
      myExpenses.fold(0, (s, e) => s + e.amount);
  double get totalApproved => myExpenses
      .where((e) =>
          e.status == ExpenseStatus.approved ||
          e.status == ExpenseStatus.reimbursed)
      .fold(0, (s, e) => s + e.amount);
  double get totalPending => myExpenses
      .where((e) => e.status == ExpenseStatus.pending)
      .fold(0, (s, e) => s + e.amount);

  ExpenseState copyWith({
    List<ExpenseModel>? myExpenses,
    bool? isSubmitting,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
  }) {
    return ExpenseState(
      myExpenses: myExpenses ?? this.myExpenses,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── Expense ViewModel (Employee) ─────────────────────────────────────────────

class ExpenseViewModel extends StateNotifier<ExpenseState> {
  ExpenseViewModel() : super(ExpenseState(myExpenses: _generateMockExpenses()));

  Future<void> submitExpense({
    required UserModel user,
    required ExpenseCategory category,
    required double amount,
    required String description,
    required DateTime date,
    bool hasReceipt = false,
  }) async {
    state = state.copyWith(isSubmitting: true, clearMessages: true);
    await Future.delayed(const Duration(milliseconds: 1200));

    final newExpense = ExpenseModel(
      id: 'EXP${DateTime.now().millisecondsSinceEpoch}',
      employeeId: user.employeeId,
      employeeName: user.name,
      department: user.department,
      category: category,
      amount: amount,
      description: description,
      date: date,
      status: ExpenseStatus.pending,
      submittedOn: DateTime.now(),
      hasReceipt: hasReceipt,
    );

    state = ExpenseState(
      myExpenses: [newExpense, ...state.myExpenses],
      isSubmitting: false,
      successMessage: 'Expense submitted successfully!',
    );
  }

  void clearMessages() => state = state.copyWith(clearMessages: true);

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
        employeeId: 'QB001',
        employeeName: 'Rahul Sharma',
        department: 'Engineering',
        category: ExpenseCategory.food,
        amount: 620,
        description: 'Team lunch during sprint planning',
        date: now.subtract(const Duration(days: 10)),
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
