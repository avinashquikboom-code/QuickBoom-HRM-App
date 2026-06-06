import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_url.dart';
import '../models/leave_request_model.dart';
import '../models/user_model.dart';

// ─── Leave Balance ─────────────────────────────────────────────────────────────

class LeaveBalance {
  final int casualTotal;
  final int casualUsed;
  final int casualRemaining;
  final int sickTotal;
  final int sickUsed;
  final int sickRemaining;
  final int earnedTotal;
  final int earnedUsed;
  final int earnedRemaining;

  const LeaveBalance({
    this.casualTotal = 12,
    this.casualUsed = 0,
    this.casualRemaining = 12,
    this.sickTotal = 10,
    this.sickUsed = 0,
    this.sickRemaining = 10,
    this.earnedTotal = 15,
    this.earnedUsed = 0,
    this.earnedRemaining = 15,
  });
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
  LeaveViewModel() : super(const LeaveState()) {
    fetchLeaves();
  }

  Future<void> fetchLeaves() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiService.get(AppUrl.employeeLeaves);
      final data = jsonDecode(res.body);

      final List rawLeaves = data['leaves'] ?? [];
      final leaves = rawLeaves.map((l) => _parseLeave(l)).toList();

      final bal = data['balance'];
      final balance = LeaveBalance(
        casualTotal: bal['casualTotal'] ?? 12,
        casualUsed: bal['casualUsed'] ?? 0,
        casualRemaining: bal['casualRemaining'] ?? 12,
        sickTotal: bal['sickTotal'] ?? 10,
        sickUsed: bal['sickUsed'] ?? 0,
        sickRemaining: bal['sickRemaining'] ?? 10,
        earnedTotal: bal['earnedTotal'] ?? 15,
        earnedUsed: bal['earnedUsed'] ?? 0,
        earnedRemaining: bal['earnedRemaining'] ?? 15,
      );

      state = state.copyWith(
        myLeaves: leaves,
        balance: balance,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> downloadLeaveReport() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      final downloadUri = Uri.parse(
        '${AppUrl.baseUrl}${AppUrl.leaveMyReportDownload}?token=$token',
      );

      debugPrint('📥 Opening leave report URL: $downloadUri');

      if (await canLaunchUrl(downloadUri)) {
        await launchUrl(downloadUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open the leave report URL.');
      }
    } catch (error) {
      throw Exception('Failed to download leave report: ${error.toString()}');
    }
  }

  Future<void> applyLeave({
    required UserModel user,
    required LeaveType type,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) async {
    state = state.copyWith(isSubmitting: true, clearMessages: true);

    try {
      await ApiService.post(AppUrl.employeeLeaves, {
        'type': type.name.toUpperCase(),
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
        'reason': reason.trim(),
      });

      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Leave request submitted successfully!',
      );

      await fetchLeaves();
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
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

final leaveViewModelProvider =
    StateNotifierProvider<LeaveViewModel, LeaveState>((ref) {
  return LeaveViewModel();
});
