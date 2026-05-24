import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leave_request_model.dart';
import '../models/user_model.dart';

// ─── Leave Balance ─────────────────────────────────────────────────────────────

class LeaveBalance {
  final int casualTotal;
  final int casualUsed;
  final int sickTotal;
  final int sickUsed;
  final int earnedTotal;
  final int earnedUsed;

  const LeaveBalance({
    this.casualTotal = 12,
    this.casualUsed = 3,
    this.sickTotal = 10,
    this.sickUsed = 1,
    this.earnedTotal = 15,
    this.earnedUsed = 5,
  });

  int get casualRemaining => casualTotal - casualUsed;
  int get sickRemaining => sickTotal - sickUsed;
  int get earnedRemaining => earnedTotal - earnedUsed;
}

// ─── Leave State ──────────────────────────────────────────────────────────────

class LeaveState {
  final List<LeaveRequestModel> myLeaves;
  final LeaveBalance balance;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const LeaveState({
    this.myLeaves = const [],
    this.balance = const LeaveBalance(),
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  LeaveState copyWith({
    List<LeaveRequestModel>? myLeaves,
    LeaveBalance? balance,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return LeaveState(
      myLeaves: myLeaves ?? this.myLeaves,
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ─── Leave ViewModel (Employee) ────────────────────────────────────────────────

class LeaveViewModel extends StateNotifier<LeaveState> {
  LeaveViewModel() : super(LeaveState(myLeaves: _generateMockLeaves()));

  Future<void> applyLeave({
    required UserModel user,
    required LeaveType type,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) async {
    state = state.copyWith(isSubmitting: true, clearMessages: true);
    await Future.delayed(const Duration(milliseconds: 1200));

    final newLeave = LeaveRequestModel(
      id: 'L${DateTime.now().millisecondsSinceEpoch}',
      employeeId: user.employeeId,
      employeeName: user.name,
      department: user.department,
      type: type,
      fromDate: fromDate,
      toDate: toDate,
      reason: reason,
      status: LeaveStatus.pending,
      appliedOn: DateTime.now(),
    );

    state = LeaveState(
      myLeaves: [newLeave, ...state.myLeaves],
      balance: state.balance,
      isSubmitting: false,
      successMessage: 'Leave request submitted successfully!',
    );
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }

  static List<LeaveRequestModel> _generateMockLeaves() {
    final now = DateTime.now();
    return [
      LeaveRequestModel(
        id: 'L001',
        employeeId: 'QB001',
        employeeName: 'Rahul Sharma',
        department: 'Engineering',
        type: LeaveType.casual,
        fromDate: now.subtract(const Duration(days: 30)),
        toDate: now.subtract(const Duration(days: 29)),
        reason: 'Personal work at home',
        status: LeaveStatus.approved,
        appliedOn: now.subtract(const Duration(days: 35)),
        reviewedBy: 'Sarah Johnson',
        reviewNote: 'Approved',
      ),
      LeaveRequestModel(
        id: 'L002',
        employeeId: 'QB001',
        employeeName: 'Rahul Sharma',
        department: 'Engineering',
        type: LeaveType.sick,
        fromDate: now.subtract(const Duration(days: 60)),
        toDate: now.subtract(const Duration(days: 60)),
        reason: 'Fever and cold',
        status: LeaveStatus.approved,
        appliedOn: now.subtract(const Duration(days: 61)),
        reviewedBy: 'Sarah Johnson',
        reviewNote: 'Get well soon',
      ),
      LeaveRequestModel(
        id: 'L003',
        employeeId: 'QB001',
        employeeName: 'Rahul Sharma',
        department: 'Engineering',
        type: LeaveType.earned,
        fromDate: now.add(const Duration(days: 10)),
        toDate: now.add(const Duration(days: 14)),
        reason: 'Family vacation trip',
        status: LeaveStatus.pending,
        appliedOn: now.subtract(const Duration(days: 2)),
      ),
      LeaveRequestModel(
        id: 'L004',
        employeeId: 'QB001',
        employeeName: 'Rahul Sharma',
        department: 'Engineering',
        type: LeaveType.casual,
        fromDate: now.subtract(const Duration(days: 10)),
        toDate: now.subtract(const Duration(days: 10)),
        reason: 'Bank work',
        status: LeaveStatus.rejected,
        appliedOn: now.subtract(const Duration(days: 12)),
        reviewedBy: 'Sarah Johnson',
        reviewNote: 'Critical project deadline, please reschedule.',
      ),
    ];
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final leaveViewModelProvider =
    StateNotifierProvider<LeaveViewModel, LeaveState>((ref) {
  return LeaveViewModel();
});
