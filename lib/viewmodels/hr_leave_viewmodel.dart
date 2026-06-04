import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_url.dart';
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
  HrLeaveViewModel() : super(const HrLeaveState()) {
    fetchLeaves();
  }

  Future<void> fetchLeaves() async {
    try {
      final res = await ApiService.get(AppUrl.hrLeaves);
      final data = jsonDecode(res.body);
      final List rawLeaves = data['leaves'] ?? [];
      final leaves = rawLeaves.map((l) => _parseLeave(l)).toList();

      state = state.copyWith(allLeaves: leaves);
    } catch (_) {
      state = state.copyWith(allLeaves: []);
    }
  }

  Future<void> approveLeave(String leaveId, String reviewerName) async {
    state = state.copyWith(isProcessing: true, clearMessage: true);
    try {
      await ApiService.post(AppUrl.hrApproveLeave(leaveId), {
        'reviewerName': reviewerName,
        'reviewNote': 'Approved',
      });

      await fetchLeaves();
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Leave approved successfully.',
      );
    } catch (error) {
      state = state.copyWith(
        isProcessing: false,
        successMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> rejectLeave(
      String leaveId, String reviewerName, String note) async {
    state = state.copyWith(isProcessing: true, clearMessage: true);
    try {
      await ApiService.post(AppUrl.hrRejectLeave(leaveId), {
        'reviewerName': reviewerName,
        'reviewNote': note.isEmpty ? 'Rejected' : note,
      });

      await fetchLeaves();
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Leave rejected.',
      );
    } catch (error) {
      state = state.copyWith(
        isProcessing: false,
        successMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  LeaveRequestModel _parseLeave(Map<String, dynamic> data) {
    return LeaveRequestModel(
      id: data['id'].toString(),
      employeeId: data['employeeId'].toString(),
      employeeName: data['employeeName'].toString(),
      department: data['department'].toString(),
      type: _parseLeaveType(data['type']?.toString() ?? 'CASUAL'),
      fromDate: DateTime.tryParse(data['fromDate'].toString()) ?? DateTime.now(),
      toDate: DateTime.tryParse(data['toDate'].toString()) ?? DateTime.now(),
      reason: data['reason'].toString(),
      status: _parseLeaveStatus(data['status']?.toString() ?? 'PENDING'),
      appliedOn: DateTime.tryParse(data['appliedOn'].toString()) ?? DateTime.now(),
      reviewedBy: data['reviewedBy']?.toString(),
      reviewNote: data['reviewNote']?.toString(),
    );
  }

  LeaveType _parseLeaveType(String type) {
    switch (type.toUpperCase()) {
      case 'CASUAL':
        return LeaveType.casual;
      case 'SICK':
        return LeaveType.sick;
      case 'EARNED':
        return LeaveType.earned;
      case 'MATERNITY':
        return LeaveType.maternity;
      case 'PATERNITY':
        return LeaveType.paternity;
      default:
        return LeaveType.unpaid;
    }
  }

  LeaveStatus _parseLeaveStatus(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return LeaveStatus.approved;
      case 'REJECTED':
        return LeaveStatus.rejected;
      case 'CANCELLED':
        return LeaveStatus.cancelled;
      default:
        return LeaveStatus.pending;
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final hrLeaveViewModelProvider =
    StateNotifierProvider<HrLeaveViewModel, HrLeaveState>((ref) {
  return HrLeaveViewModel();
});
