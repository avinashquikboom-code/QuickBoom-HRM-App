import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_url.dart';

// ─── HR Dashboard Stats ────────────────────────────────────────────────────────

class HRDashboardStats {
  final int totalEmployees;
  final int activeEmployees;
  final int presentToday;
  final int pendingLeaves;
  final int newHires;
  final int openTasks;
  final int departments;
  final int attendanceRate;
  final int totalAttendanceToday;
  final int totalHRAdmins;
  final int activeSessions;
  final String onboardingRate;
  final List<HiringGrowth> hiringGrowth;
  final List<HRDistribution> hrDistribution;

  const HRDashboardStats({
    this.totalEmployees = 0,
    this.activeEmployees = 0,
    this.presentToday = 0,
    this.pendingLeaves = 0,
    this.newHires = 0,
    this.openTasks = 0,
    this.departments = 0,
    this.attendanceRate = 0,
    this.totalAttendanceToday = 0,
    this.totalHRAdmins = 0,
    this.activeSessions = 0,
    this.onboardingRate = '100%',
    this.hiringGrowth = const [],
    this.hrDistribution = const [],
  });
}

class HiringGrowth {
  final String name;
  final int hires;

  const HiringGrowth({required this.name, required this.hires});
}

class HRDistribution {
  final String name;
  final int value;
  final String color;

  const HRDistribution({required this.name, required this.value, required this.color});
}

// ─── HR Dashboard State ─────────────────────────────────────────────────────────

class HRDashboardState {
  final HRDashboardStats stats;
  final bool isLoading;
  final String? errorMessage;

  const HRDashboardState({
    this.stats = const HRDashboardStats(),
    this.isLoading = false,
    this.errorMessage,
  });

  HRDashboardState copyWith({
    HRDashboardStats? stats,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HRDashboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── HR Dashboard ViewModel ─────────────────────────────────────────────────────

class HRDashboardViewModel extends StateNotifier<HRDashboardState> {
  Timer? _refreshTimer;

  HRDashboardViewModel() : super(const HRDashboardState()) {
    fetchDashboardStats();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Auto-refresh dashboard every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (kDebugMode) {
        debugPrint('🔄 Auto-refreshing HR dashboard...');
      }
      fetchDashboardStats();
    });
  }

  Future<void> fetchDashboardStats() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await ApiService.get(AppUrl.hrStats);
      final data = jsonDecode(res.body);

      final statsData = data['data'];

      final hiringGrowth = (statsData['hiringGrowth'] as List?)
              ?.map((hg) => HiringGrowth(
                    name: hg['name']?.toString() ?? '',
                    hires: hg['hires'] as int? ?? 0,
                  ))
              .toList() ??
          [];

      final hrDistribution = (statsData['hrDistribution'] as List?)
              ?.map((hd) => HRDistribution(
                    name: hd['name']?.toString() ?? '',
                    value: hd['value'] as int? ?? 0,
                    color: hd['color']?.toString() ?? '#64748B',
                  ))
              .toList() ??
          [];

      final stats = HRDashboardStats(
        totalEmployees: statsData['totalEmployees'] as int? ?? 0,
        activeEmployees: statsData['activeEmployees'] as int? ?? 0,
        presentToday: statsData['presentToday'] as int? ?? 0,
        pendingLeaves: statsData['pendingLeaves'] as int? ?? 0,
        newHires: statsData['newHires'] as int? ?? 0,
        openTasks: statsData['openTasks'] as int? ?? 0,
        departments: statsData['departments'] as int? ?? 0,
        attendanceRate: statsData['attendanceRate'] as int? ?? 0,
        totalAttendanceToday: statsData['totalAttendanceToday'] as int? ?? 0,
        totalHRAdmins: statsData['totalHRAdmins'] as int? ?? 0,
        activeSessions: statsData['activeSessions'] as int? ?? 0,
        onboardingRate: statsData['onboardingRate']?.toString() ?? '100%',
        hiringGrowth: hiringGrowth,
        hrDistribution: hrDistribution,
      );

      state = state.copyWith(stats: stats, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final hrDashboardViewModelProvider =
    StateNotifierProvider<HRDashboardViewModel, HRDashboardState>((ref) {
  return HRDashboardViewModel();
});
