import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../core/constants/app_url.dart';
import '../models/shift_model.dart';

// ─── Shift State ───────────────────────────────────────────────────────────────

class ShiftState {
  final List<ShiftModel> shifts;
  final List<EmployeeShiftAssignment> assignments;
  final bool isLoading;

  const ShiftState({
    this.shifts = const [],
    this.assignments = const [],
    this.isLoading = false,
  });

  ShiftState copyWith({
    List<ShiftModel>? shifts,
    List<EmployeeShiftAssignment>? assignments,
    bool? isLoading,
  }) {
    return ShiftState(
      shifts: shifts ?? this.shifts,
      assignments: assignments ?? this.assignments,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Shift ViewModel ──────────────────────────────────────────────────────────

class ShiftViewModel extends StateNotifier<ShiftState> {
  ShiftViewModel() : super(const ShiftState()) {
    fetchShiftAssignment();
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
          shifts: [shift],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          assignments: [],
          shifts: [],
          isLoading: false,
        );
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final shiftViewModelProvider =
    StateNotifierProvider<ShiftViewModel, ShiftState>((ref) {
  return ShiftViewModel();
});
