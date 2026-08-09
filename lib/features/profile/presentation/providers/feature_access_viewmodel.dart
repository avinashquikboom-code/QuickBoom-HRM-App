import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/features/profile/data/models/feature_access_model.dart';

class FeatureAccessState {
  final List<FeatureAccessModel> features;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const FeatureAccessState({
    this.features = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  FeatureAccessState copyWith({
    List<FeatureAccessModel>? features,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return FeatureAccessState(
      features: features ?? this.features,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class FeatureAccessViewModel extends StateNotifier<FeatureAccessState> {
  FeatureAccessViewModel() : super(const FeatureAccessState());

  Future<void> fetchFeatures() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final response = await ApiService.get(AppUrl.mobileFeatureAccess);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['features'] != null) {
          final List rawList = data['features'];
          final parsed = rawList
              .map((item) => FeatureAccessModel.fromJson(item))
              .toList();
          state = state.copyWith(features: parsed, isLoading: false);
          return;
        }
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load feature access data.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error fetching features: $e',
      );
    }
  }

  Future<bool> requestFeatureAccess({
    required String featureName,
    required String reason,
    required DateTime fromDate,
    required DateTime toDate,
    String? fromTime,
    String? toTime,
  }) async {
    state = state.copyWith(isSubmitting: true, clearMessages: true);
    try {
      final body = {
        'featureName': featureName,
        'reason': reason,
        'requestedFromDate': fromDate.toIso8601String().split('T')[0],
        'requestedToDate': toDate.toIso8601String().split('T')[0],
        if (fromTime != null && fromTime.isNotEmpty) 'requestedFromTime': fromTime,
        if (toTime != null && toTime.isNotEmpty) 'requestedToTime': toTime,
      };

      final response = await ApiService.post(AppUrl.mobileFeatureAccessRequest, body);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        state = state.copyWith(
          isSubmitting: false,
          successMessage: 'Feature access request submitted successfully!',
        );
        fetchFeatures(); // Refresh list after submitting
        return true;
      } else {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: data['message'] ?? 'Failed to submit request.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Error submitting request: $e',
      );
      return false;
    }
  }
}

final featureAccessViewModelProvider =
    StateNotifierProvider<FeatureAccessViewModel, FeatureAccessState>((ref) {
  return FeatureAccessViewModel();
});
