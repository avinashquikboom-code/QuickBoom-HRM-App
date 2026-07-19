import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/features/shift/data/models/shift_model.dart';
import 'package:quickboom_hrm/features/shift/data/models/shift_request_model.dart';

// ─── Shift State ───────────────────────────────────────────────────────────────

class ShiftState {
  final List<ShiftModel> shifts; // all available shifts
  final List<EmployeeShiftAssignment> assignments; // current assigned shift
  final List<ShiftRequestModel> myRequests; // shift requests list
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const ShiftState({
    this.shifts = const [],
    this.assignments = const [],
    this.myRequests = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  ShiftState copyWith({
    List<ShiftModel>? shifts,
    List<EmployeeShiftAssignment>? assignments,
    List<ShiftRequestModel>? myRequests,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ShiftState(
      shifts: shifts ?? this.shifts,
      assignments: assignments ?? this.assignments,
      myRequests: myRequests ?? this.myRequests,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ─── Shift ViewModel ──────────────────────────────────────────────────────────

class ShiftViewModel extends StateNotifier<ShiftState> {
  ShiftViewModel() : super(const ShiftState()) {
    fetchShiftAssignment();
    fetchShifts();
    fetchMyRequests();
  }

  Future<void> fetchShiftAssignment() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiService.get(AppUrl.employeeShifts);
      final data = jsonDecode(res.body);
      final rawAssignment = data['assignment'];

      if (rawAssignment != null) {
        final shiftData = rawAssignment['shift'];
        final workingDaysRaw = shiftData['workingDays'];
        final List<String> workingDays = workingDaysRaw is List
            ? workingDaysRaw.map((d) => d.toString()).toList()
            : [];

        final shift = ShiftModel(
          id: shiftData['id']?.toString() ?? '',
          name: shiftData['name']?.toString() ?? '',
          startTime: shiftData['startTime']?.toString() ?? '09:00',
          endTime: shiftData['endTime']?.toString() ?? '18:00',
          workingDays: workingDays,
          graceMinutes: shiftData['graceMinutes'] as int? ?? 15,
          breakMinutes: shiftData['breakMinutes'] as int? ?? 60,
          color: shiftData['color']?.toString() ?? '#3BA38B',
        );

        final assignment = EmployeeShiftAssignment(
          employeeId: rawAssignment['employeeId']?.toString() ?? '',
          employeeName: rawAssignment['employeeName']?.toString() ?? '',
          department: rawAssignment['department']?.toString() ?? '',
          shift: shift,
          effectiveFrom: rawAssignment['effectiveFrom'] != null
              ? DateTime.parse(rawAssignment['effectiveFrom'])
              : DateTime.now(),
        );

        state = state.copyWith(
          assignments: [assignment],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          assignments: [],
          isLoading: false,
        );
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchShifts() async {
    try {
      final res = await ApiService.get('/api/shifts');
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final List rawShifts = data['data'] ?? [];
        final shiftsList = rawShifts.map((s) {
          final workingDaysRaw = s['workingDays'];
          final List<String> workingDays = workingDaysRaw is List
              ? workingDaysRaw.map((d) => d.toString()).toList()
              : [];
          return ShiftModel(
            id: s['id']?.toString() ?? '',
            name: s['name']?.toString() ?? '',
            startTime: s['startTime']?.toString() ?? '09:00',
            endTime: s['endTime']?.toString() ?? '18:00',
            workingDays: workingDays,
            graceMinutes: s['graceMinutes'] as int? ?? 15,
            breakMinutes: s['breakMinutes'] as int? ?? 60,
            color: s['color']?.toString() ?? '#3BA38B',
          );
        }).toList();

        state = state.copyWith(shifts: shiftsList);
      }
    } catch (_) {
      // Silently ignore or set error state if critical
    }
  }

  Future<void> fetchMyRequests() async {
    try {
      final res = await ApiService.get('/api/shift-requests/my');
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final List rawRequests = data['data'] ?? [];
        final requests = rawRequests.map((r) => ShiftRequestModel.fromJson(r)).toList();
        state = state.copyWith(myRequests: requests);
      }
    } catch (_) {}
  }

  Future<bool> submitShiftRequest(String requestedShift, String reason) async {
    state = state.copyWith(isSubmitting: true, clearMessages: true);
    try {
      final res = await ApiService.post('/api/shift-requests', {
        'requestedShift': requestedShift,
        'reason': reason
      });
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        state = state.copyWith(
          isSubmitting: false,
          successMessage: 'Shift change request submitted successfully!',
        );
        await fetchMyRequests();
        return true;
      } else {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: data['message'] ?? 'Failed to submit shift request.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final shiftViewModelProvider =
    StateNotifierProvider<ShiftViewModel, ShiftState>((ref) {
  return ShiftViewModel();
});
