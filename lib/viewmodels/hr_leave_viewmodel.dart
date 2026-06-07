import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
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
  Timer? _refreshTimer;

  HrLeaveViewModel() : super(const HrLeaveState()) {
    fetchLeaves();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh HR leaves every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      // Check if user is still authenticated before refreshing
      final hasToken = await StorageService.hasToken();
      if (!hasToken) {
        _refreshTimer?.cancel();
        return;
      }
      if (kDebugMode) {
        debugPrint('🔄 Auto-refreshing HR leaves...');
      }
      fetchLeaves();
    });
  }

  Future<void> fetchLeaves() async {
    try {
      final res = await ApiService.get(AppUrl.hrLeaves);
      final data = jsonDecode(res.body);

      // Handle both response structures
      final List rawLeaves = data['data']?['leaveRequests'] ?? data['leaves'] ?? [];
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

  Future<void> downloadLeaveReport() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      final downloadUri = Uri.parse(
        '${AppUrl.baseUrl}${AppUrl.leaveReportDownload}?token=$token',
      );

      debugPrint('📥 Opening HR leave report URL: $downloadUri');

      bool launched = await launchUrl(
        downloadUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback for devices without an external browser handler.
        launched = await launchUrl(
          downloadUri,
          mode: LaunchMode.platformDefault,
        );
      }
      if (!launched) {
        throw Exception('Could not open the leave report URL.');
      }
    } catch (error) {
      throw Exception('Failed to download leave report: ${error.toString()}');
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  LeaveRequestModel _parseLeave(Map<String, dynamic> data) {
    // Handle both flat and nested employee data structures
    final employeeData = data['employee'] as Map<String, dynamic>?;
    final employeeName = employeeData != null
        ? '${employeeData['firstName'] ?? ''} ${employeeData['lastName'] ?? ''}'.trim()
        : (data['employeeName']?.toString() ?? 'Unknown');
    final employeeId = employeeData != null
        ? employeeData['id']?.toString()
        : data['employeeId']?.toString();
    final department = employeeData != null
        ? employeeData['department']?.toString() ?? 'N/A'
        : data['department']?.toString() ?? 'N/A';

    return LeaveRequestModel(
      id: data['id'].toString(),
      employeeId: employeeId ?? '0',
      employeeName: employeeName,
      department: department,
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
