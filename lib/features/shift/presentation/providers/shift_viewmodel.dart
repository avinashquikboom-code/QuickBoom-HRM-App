import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/features/shift/data/models/shift_model.dart';
import 'package:quickboom_hrm/features/shift/data/models/shift_request_model.dart';
import 'package:quickboom_hrm/features/auth/data/models/user_model.dart';
import 'package:quickboom_hrm/features/auth/presentation/providers/auth_viewmodel.dart';

// ─── Shift Rule Model ─────────────────────────────────────────────────────────

class ShiftRuleItem {
  final String id;
  final String title;
  final String content;
  final String? shiftType;
  final int priority;
  final bool isNew;

  const ShiftRuleItem({
    required this.id,
    required this.title,
    required this.content,
    this.shiftType,
    this.priority = 0,
    this.isNew = false,
  });

  factory ShiftRuleItem.fromJson(Map<String, dynamic> json) {
    return ShiftRuleItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      shiftType: json['shiftType']?.toString(),
      priority: json['priority'] as int? ?? 0,
      isNew: json['isNew'] as bool? ?? false,
    );
  }
}

// ─── Shift State ───────────────────────────────────────────────────────────────

class ShiftState {
  final List<ShiftModel> shifts; // all available shifts
  final List<EmployeeShiftAssignment> assignments; // current assigned shift
  final List<ShiftRequestModel> myRequests; // shift requests list
  final List<ShiftRuleItem> rules; // dynamic shift rules / guidelines
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const ShiftState({
    this.shifts = const [],
    this.assignments = const [],
    this.myRequests = const [],
    this.rules = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  ShiftState copyWith({
    List<ShiftModel>? shifts,
    List<EmployeeShiftAssignment>? assignments,
    List<ShiftRequestModel>? myRequests,
    List<ShiftRuleItem>? rules,
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
      rules: rules ?? this.rules,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ─── Shift ViewModel ──────────────────────────────────────────────────────────

class ShiftViewModel extends StateNotifier<ShiftState> {
  final Ref _ref;

  ShiftViewModel(this._ref) : super(const ShiftState()) {
    fetchShiftAssignment();
    fetchShifts();
    fetchMyRequests();
    fetchShiftRules();
  }

  Future<void> fetchShiftAssignment() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(authViewModelProvider).currentUser;
      final isHR = user != null &&
          (user.role == UserRole.hrManager || user.role == UserRole.storeManager);

      if (isHR) {
        debugPrint('👥 [ShiftViewModel] HR Mode: Fetching all employee shifts...');
        final res = await ApiService.get('/api/hr/employees');
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['employees'] is List) {
          final List employeesList = data['employees'];
          final List<EmployeeShiftAssignment> allAssignments = [];

          for (var emp in employeesList) {
            final shiftData = emp['shift'];
            ShiftModel shift;
            if (shiftData != null) {
              final workingDaysRaw = shiftData['workingDays'];
              final List<String> workingDays = workingDaysRaw is List
                  ? workingDaysRaw.map((d) => d.toString()).toList()
                  : [];
              shift = ShiftModel(
                id: shiftData['id']?.toString() ?? '',
                name: shiftData['name']?.toString() ?? '',
                startTime: shiftData['startTime']?.toString() ?? '09:00',
                endTime: shiftData['endTime']?.toString() ?? '18:00',
                workingDays: workingDays,
                graceMinutes: shiftData['graceMinutes'] as int? ?? 15,
                breakMinutes: shiftData['breakMinutes'] as int? ?? 60,
                color: shiftData['color']?.toString() ?? '#3BA38B',
              );
            } else {
              shift = const ShiftModel(
                id: 'unassigned',
                name: 'No Shift Assigned',
                startTime: '',
                endTime: '',
                workingDays: [],
                graceMinutes: 0,
                breakMinutes: 0,
                color: '#9E9E9E',
              );
            }

            allAssignments.add(
              EmployeeShiftAssignment(
                employeeId: emp['id']?.toString() ?? '',
                employeeName: emp['fullName']?.toString() ?? '',
                department: emp['department']?.toString() ?? 'Unassigned',
                shift: shift,
                effectiveFrom: emp['joinedAt'] != null
                    ? DateTime.tryParse(emp['joinedAt']) ?? DateTime.now()
                    : DateTime.now(),
              ),
            );
          }

          state = state.copyWith(
            assignments: allAssignments,
            isLoading: false,
          );
          return;
        }
      }

      // Default (Employee Mode)
      debugPrint('👤 [ShiftViewModel] Employee Mode: Fetching current shift...');
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

        if (!mounted) return;
        state = state.copyWith(
          assignments: [assignment],
          isLoading: false,
        );
      } else {
        if (!mounted) return;
        state = state.copyWith(
          assignments: [],
          isLoading: false,
        );
      }
    } catch (_) {
      if (!mounted) return;
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

  Future<void> fetchShiftRules() async {
    try {
      debugPrint('📋 [ShiftViewModel] Fetching shift rules from ${AppUrl.mobileShiftRules}');
      final res = await ApiService.get(AppUrl.mobileShiftRules);
      debugPrint('📋 [ShiftViewModel] Shift rules response: ${res.statusCode} ${res.body}');
      final data = jsonDecode(res.body);
      if (data['success'] == true && data['data'] is List) {
        final List rawRules = data['data'];
        final rulesList = rawRules.map((r) => ShiftRuleItem.fromJson(r)).toList();
        debugPrint('📋 [ShiftViewModel] Loaded ${rulesList.length} shift rule(s).');
        state = state.copyWith(rules: rulesList);
      } else {
        debugPrint('⚠️ [ShiftViewModel] Shift rules response not success or data not a list: ${res.body}');
      }
    } catch (e) {
      debugPrint('❌ [ShiftViewModel] Error fetching shift rules: $e');
    }
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
  return ShiftViewModel(ref);
});
