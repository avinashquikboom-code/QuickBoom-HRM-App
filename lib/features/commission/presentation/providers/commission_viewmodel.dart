import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/commission_service.dart';
import 'package:quickboom_hrm/features/commission/data/commission_models.dart';

class CommissionState {
  final CommissionWallet? wallet;
  final CommissionHistory? history;
  final CommissionDetails? details;
  final CommissionDashboardWidget? dashboardWidget;
  final bool isLoadingWallet;
  final bool isLoadingHistory;
  final bool isLoadingDetails;
  final bool isLoadingDashboard;
  final String? errorMessage;

  const CommissionState({
    this.wallet,
    this.history,
    this.details,
    this.dashboardWidget,
    this.isLoadingWallet = false,
    this.isLoadingHistory = false,
    this.isLoadingDetails = false,
    this.isLoadingDashboard = false,
    this.errorMessage,
  });

  CommissionState copyWith({
    CommissionWallet? wallet,
    CommissionHistory? history,
    CommissionDetails? details,
    CommissionDashboardWidget? dashboardWidget,
    bool? isLoadingWallet,
    bool? isLoadingHistory,
    bool? isLoadingDetails,
    bool? isLoadingDashboard,
    String? errorMessage,
  }) {
    return CommissionState(
      wallet: wallet ?? this.wallet,
      history: history ?? this.history,
      details: details ?? this.details,
      dashboardWidget: dashboardWidget ?? this.dashboardWidget,
      isLoadingWallet: isLoadingWallet ?? this.isLoadingWallet,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      isLoadingDashboard: isLoadingDashboard ?? this.isLoadingDashboard,
      errorMessage: errorMessage,
    );
  }
}

class CommissionViewModel extends StateNotifier<CommissionState> {
  CommissionViewModel() : super(const CommissionState());

  // Fetch Commission Wallet
  Future<void> fetchWallet() async {
    state = state.copyWith(isLoadingWallet: true, errorMessage: null);
    try {
      debugPrint('🔄 Fetching commission wallet...');
      final wallet = await CommissionService.fetchCommissionWallet();
      state = state.copyWith(
        wallet: wallet,
        isLoadingWallet: false,
        errorMessage: wallet == null ? 'Failed to load commission wallet' : null,
      );
      debugPrint('✅ Commission wallet loaded');
    } catch (e) {
      debugPrint('❌ Error fetching commission wallet: $e');
      state = state.copyWith(
        isLoadingWallet: false,
        errorMessage: 'Failed to load commission wallet',
      );
    }
  }

  // Fetch Commission History with pagination and filters
  Future<void> fetchHistory({
    int page = 1,
    int limit = 20,
    String? status,
    String? startDate,
    String? endDate,
    String? month,
  }) async {
    state = state.copyWith(isLoadingHistory: true, errorMessage: null);
    try {
      debugPrint('🔄 Fetching commission history...');
      final history = await CommissionService.fetchCommissionHistory(
        page: page,
        limit: limit,
        status: status,
        startDate: startDate,
        endDate: endDate,
        month: month,
      );
      state = state.copyWith(
        history: history,
        isLoadingHistory: false,
        errorMessage: history == null ? 'Failed to load commission history' : null,
      );
      debugPrint('✅ Commission history loaded');
    } catch (e) {
      debugPrint('❌ Error fetching commission history: $e');
      state = state.copyWith(
        isLoadingHistory: false,
        errorMessage: 'Failed to load commission history',
      );
    }
  }

  // Fetch Commission Details
  Future<void> fetchDetails() async {
    state = state.copyWith(isLoadingDetails: true, errorMessage: null);
    try {
      debugPrint('🔄 Fetching commission details...');
      final details = await CommissionService.fetchCommissionDetails();
      state = state.copyWith(
        details: details,
        isLoadingDetails: false,
        errorMessage: details == null ? 'Failed to load commission details' : null,
      );
      debugPrint('✅ Commission details loaded');
    } catch (e) {
      debugPrint('❌ Error fetching commission details: $e');
      state = state.copyWith(
        isLoadingDetails: false,
        errorMessage: 'Failed to load commission details',
      );
    }
  }

  // Fetch Commission Dashboard Widget
  Future<void> fetchDashboardWidget() async {
    state = state.copyWith(isLoadingDashboard: true, errorMessage: null);
    try {
      debugPrint('🔄 Fetching commission dashboard widget...');
      final widget = await CommissionService.fetchCommissionDashboardWidget();
      state = state.copyWith(
        dashboardWidget: widget,
        isLoadingDashboard: false,
        errorMessage: widget == null ? 'Failed to load commission widget' : null,
      );
      debugPrint('✅ Commission dashboard widget loaded');
    } catch (e) {
      debugPrint('❌ Error fetching commission dashboard widget: $e');
      state = state.copyWith(
        isLoadingDashboard: false,
        errorMessage: 'Failed to load commission widget',
      );
    }
  }

  // Refresh all commission data
  Future<void> refreshAll() async {
    await Future.wait([
      fetchWallet(),
      fetchDashboardWidget(),
    ]);
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Provider
final commissionViewModelProvider =
    StateNotifierProvider<CommissionViewModel, CommissionState>((ref) {
  return CommissionViewModel();
});
