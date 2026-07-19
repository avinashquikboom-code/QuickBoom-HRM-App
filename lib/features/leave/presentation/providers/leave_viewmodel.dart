import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/services/websocket_service.dart';
import 'package:quickboom_hrm/core/services/leave_report_pdf_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/features/leave/data/models/leave_request_model.dart';
import 'package:quickboom_hrm/features/auth/data/models/user_model.dart';

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
  final List<String> holidays; // list of date strings (YYYY-MM-DD)
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const LeaveState({
    this.myLeaves = const [],
    this.balance = const LeaveBalance(),
    this.holidays = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  LeaveState copyWith({
    List<LeaveRequestModel>? myLeaves,
    LeaveBalance? balance,
    List<String>? holidays,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return LeaveState(
      myLeaves: myLeaves ?? this.myLeaves,
      balance: balance ?? this.balance,
      holidays: holidays ?? this.holidays,
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
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription? _leaveBalanceSubscription;

  LeaveViewModel() : super(const LeaveState()) {
    _initializeWebSocket();
    fetchLeaves();
    fetchHolidays();
  }

  Future<void> fetchHolidays() async {
    try {
      final res = await ApiService.get('/api/holidays');
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final List rawHolidays = data['holidays'] ?? [];
        final holidayDates = rawHolidays
            .map((h) => h['date']?.toString() ?? '')
            .where((d) => d.isNotEmpty)
            .toList();
        state = state.copyWith(holidays: holidayDates);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _leaveBalanceSubscription?.cancel();
    _wsService.disconnect();
    super.dispose();
  }

  void _initializeWebSocket() {
    // Connect to WebSocket
    _wsService.connect();

    // Listen for real-time leave balance updates
    _leaveBalanceSubscription = _wsService.leaveBalanceUpdates.listen((data) {
      if (data['type'] == 'LEAVE_BALANCE_UPDATED' && data['leaveBalance'] != null) {
        final leaveBalance = data['leaveBalance'];
        _updateLeaveBalanceFromWebSocket(leaveBalance);
      }
    });
  }

  void _updateLeaveBalanceFromWebSocket(Map<String, dynamic> leaveBalanceData) {
    final updatedBalance = LeaveBalance(
      casualTotal: leaveBalanceData['casualTotal'] ?? state.balance.casualTotal,
      casualUsed: leaveBalanceData['casualUsed'] ?? state.balance.casualUsed,
      casualRemaining: leaveBalanceData['casualRemaining'] ?? state.balance.casualRemaining,
      sickTotal: leaveBalanceData['sickTotal'] ?? state.balance.sickTotal,
      sickUsed: leaveBalanceData['sickUsed'] ?? state.balance.sickUsed,
      sickRemaining: leaveBalanceData['sickRemaining'] ?? state.balance.sickRemaining,
      earnedTotal: leaveBalanceData['earnedTotal'] ?? state.balance.earnedTotal,
      earnedUsed: leaveBalanceData['earnedUsed'] ?? state.balance.earnedUsed,
      earnedRemaining: leaveBalanceData['earnedRemaining'] ?? state.balance.earnedRemaining,
    );

    state = state.copyWith(
      balance: updatedBalance,
      successMessage: 'Leave balance updated in real-time',
    );

    // Clear success message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (state.successMessage?.contains('real-time') == true) {
        state = state.copyWith(clearMessages: true);
      }
    });
  }

  Future<void> fetchLeaves() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiService.get(AppUrl.mobileMyLeaves);
      final data = jsonDecode(res.body);

      final List rawLeaves = data['data']['leaveRequests'] ?? [];
      final leaves = rawLeaves.map((l) => _parseLeave(l)).toList();

      final bal = data['data']['leaveBalances'];
      final balance = LeaveBalance(
        casualTotal: bal['casual']['total'] ?? 12,
        casualUsed: bal['casual']['used'] ?? 0,
        casualRemaining: bal['casual']['remaining'] ?? 12,
        sickTotal: bal['sick']['total'] ?? 10,
        sickUsed: bal['sick']['used'] ?? 0,
        sickRemaining: bal['sick']['remaining'] ?? 10,
        earnedTotal: bal['earned']['total'] ?? 15,
        earnedUsed: bal['earned']['used'] ?? 0,
        earnedRemaining: bal['earned']['remaining'] ?? 15,
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

  Future<void> downloadLeaveReport({String employeeName = 'Employee'}) async {
    try {
      final res = await ApiService.get(AppUrl.mobileDownloadMyLeaveReport);
      
      if (res.statusCode != 200) {
        throw Exception('Failed to download leave report: ${res.statusCode}');
      }
      
      // The backend returns the PDF directly, we need to handle it
      // For now, we'll use the local PDF generation as fallback since the backend API might not work properly
      if (state.myLeaves.isEmpty) {
        await fetchLeaves();
      }

      final approvedLeaves = state.myLeaves
          .where((l) => l.status == LeaveStatus.approved)
          .toList();

      if (approvedLeaves.isEmpty) {
        throw Exception('No approved leaves available to download.');
      }

      await LeaveReportPdfService.generateAndShare(
        balance: state.balance,
        leaves: approvedLeaves,
        employeeName: employeeName,
      );
    } catch (error) {
      throw Exception('Failed to generate leave report: ${error.toString()}');
    }
  }

  Future<void> applyLeave({
    required UserModel user,
    required LeaveType type,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
    required String leaveCategory,
  }) async {
    state = state.copyWith(isSubmitting: true, clearMessages: true);

    try {
      await ApiService.post(AppUrl.employeeLeaves, {
        'type': type.name.toUpperCase(),
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
        'reason': reason.trim(),
        'leaveCategory': leaveCategory.toUpperCase(),
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
