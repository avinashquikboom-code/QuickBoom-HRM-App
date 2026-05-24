import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leave_request_model.dart';

// ─── HR Leave State ────────────────────────────────────────────────────────────

class HrLeaveState {
  final List<LeaveRequestModel> allLeaves;
  final bool isProcessing;
  final String? successMessage;

  const HrLeaveState({
    this.allLeaves = const [],
    this.isProcessing = false,
    this.successMessage,
  });

  List<LeaveRequestModel> get pendingLeaves =>
      allLeaves.where((l) => l.status == LeaveStatus.pending).toList();

  List<LeaveRequestModel> get reviewedLeaves =>
      allLeaves.where((l) => l.status != LeaveStatus.pending).toList();

  HrLeaveState copyWith({
    List<LeaveRequestModel>? allLeaves,
    bool? isProcessing,
    String? successMessage,
    bool clearMessage = false,
  }) {
    return HrLeaveState(
      allLeaves: allLeaves ?? this.allLeaves,
      isProcessing: isProcessing ?? this.isProcessing,
      successMessage: clearMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ─── HR Leave ViewModel ────────────────────────────────────────────────────────

class HrLeaveViewModel extends StateNotifier<HrLeaveState> {
  HrLeaveViewModel() : super(HrLeaveState(allLeaves: _generateMockLeaves()));

  Future<void> approveLeave(String leaveId, String reviewerName) async {
    state = state.copyWith(isProcessing: true, clearMessage: true);
    await Future.delayed(const Duration(milliseconds: 800));

    final updated = state.allLeaves.map((l) {
      if (l.id == leaveId) {
        return l.copyWith(
          status: LeaveStatus.approved,
          reviewedBy: reviewerName,
          reviewNote: 'Approved',
        );
      }
      return l;
    }).toList();

    state = state.copyWith(
      allLeaves: updated,
      isProcessing: false,
      successMessage: 'Leave approved successfully.',
    );
  }

  Future<void> rejectLeave(
      String leaveId, String reviewerName, String note) async {
    state = state.copyWith(isProcessing: true, clearMessage: true);
    await Future.delayed(const Duration(milliseconds: 800));

    final updated = state.allLeaves.map((l) {
      if (l.id == leaveId) {
        return l.copyWith(
          status: LeaveStatus.rejected,
          reviewedBy: reviewerName,
          reviewNote: note.isEmpty ? 'Rejected' : note,
        );
      }
      return l;
    }).toList();

    state = state.copyWith(
      allLeaves: updated,
      isProcessing: false,
      successMessage: 'Leave rejected.',
    );
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  static List<LeaveRequestModel> _generateMockLeaves() {
    final now = DateTime.now();
    return [
      LeaveRequestModel(
        id: 'HL001',
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
        id: 'HL002',
        employeeId: 'QB002',
        employeeName: 'Priya Patel',
        department: 'Design',
        type: LeaveType.sick,
        fromDate: now.add(const Duration(days: 2)),
        toDate: now.add(const Duration(days: 3)),
        reason: 'Not feeling well, doctor visit',
        status: LeaveStatus.pending,
        appliedOn: now.subtract(const Duration(days: 1)),
      ),
      LeaveRequestModel(
        id: 'HL003',
        employeeId: 'QB004',
        employeeName: 'Sneha Verma',
        department: 'Marketing',
        type: LeaveType.casual,
        fromDate: now.add(const Duration(days: 5)),
        toDate: now.add(const Duration(days: 5)),
        reason: 'Personal work',
        status: LeaveStatus.pending,
        appliedOn: now,
      ),
      LeaveRequestModel(
        id: 'HL004',
        employeeId: 'QB003',
        employeeName: 'Amit Kumar',
        department: 'Engineering',
        type: LeaveType.casual,
        fromDate: now.subtract(const Duration(days: 10)),
        toDate: now.subtract(const Duration(days: 9)),
        reason: 'Home renovation',
        status: LeaveStatus.approved,
        appliedOn: now.subtract(const Duration(days: 15)),
        reviewedBy: 'Sarah Johnson',
        reviewNote: 'Approved',
      ),
      LeaveRequestModel(
        id: 'HL005',
        employeeId: 'QB005',
        employeeName: 'Deepak Nair',
        department: 'Finance',
        type: LeaveType.sick,
        fromDate: now.subtract(const Duration(days: 5)),
        toDate: now.subtract(const Duration(days: 5)),
        reason: 'Flu symptoms',
        status: LeaveStatus.approved,
        appliedOn: now.subtract(const Duration(days: 6)),
        reviewedBy: 'Sarah Johnson',
        reviewNote: 'Take rest',
      ),
      LeaveRequestModel(
        id: 'HL006',
        employeeId: 'QB006',
        employeeName: 'Kavya Reddy',
        department: 'Design',
        type: LeaveType.earned,
        fromDate: now.subtract(const Duration(days: 20)),
        toDate: now.subtract(const Duration(days: 16)),
        reason: 'Wedding anniversary trip',
        status: LeaveStatus.rejected,
        appliedOn: now.subtract(const Duration(days: 25)),
        reviewedBy: 'Sarah Johnson',
        reviewNote: 'Product launch week, please reschedule.',
      ),
    ];
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final hrLeaveViewModelProvider =
    StateNotifierProvider<HrLeaveViewModel, HrLeaveState>((ref) {
  return HrLeaveViewModel();
});
