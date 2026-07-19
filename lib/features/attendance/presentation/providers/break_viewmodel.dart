import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/features/attendance/data/models/break_model.dart';

class BreakState {
  final List<BreakModel> todayBreaks;
  final BreakModel? activeBreak;
  final bool isLoading;
  final String? errorMessage;

  const BreakState({
    this.todayBreaks = const [],
    this.activeBreak,
    this.isLoading = false,
    this.errorMessage,
  });

  BreakState copyWith({
    List<BreakModel>? todayBreaks,
    BreakModel? activeBreak,
    bool? isLoading,
    String? errorMessage,
    bool clearActiveBreak = false,
    bool clearError = false,
  }) {
    return BreakState(
      todayBreaks: todayBreaks ?? this.todayBreaks,
      activeBreak: clearActiveBreak ? null : (activeBreak ?? this.activeBreak),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class BreakViewModel extends StateNotifier<BreakState> {
  BreakViewModel() : super(const BreakState()) {
    fetchTodayBreaks();
  }

  Future<void> fetchTodayBreaks() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiService.get('/api/breaks/today');
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        final List rawBreaks = data['breaks'] ?? [];
        final breaks = rawBreaks.map((b) => BreakModel.fromJson(b)).toList();
        final rawActive = data['activeBreak'];
        final activeBreak = rawActive != null ? BreakModel.fromJson(rawActive) : null;

        state = state.copyWith(
          todayBreaks: breaks,
          activeBreak: activeBreak,
          clearActiveBreak: activeBreak == null,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['message'] ?? 'Failed to load breaks.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> startBreak(String type) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiService.post('/api/breaks/start', {'type': type});
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        await fetchTodayBreaks();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['message'] ?? 'Failed to start break.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> endBreak() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiService.post('/api/breaks/end', {});
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        await fetchTodayBreaks();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: data['message'] ?? 'Failed to end break.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final breakViewModelProvider = StateNotifierProvider<BreakViewModel, BreakState>((ref) {
  return BreakViewModel();
});
