import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/services/websocket_service.dart';
import 'package:quickboom_hrm/features/auth/presentation/providers/auth_viewmodel.dart';
import 'package:http/http.dart' as http;

class FeatureAccess {
  final String name;
  final bool enabled;
  final String reason;
  final String? validFrom;
  final String? validUntil;

  FeatureAccess({
    required this.name,
    required this.enabled,
    required this.reason,
    this.validFrom,
    this.validUntil,
  });

  factory FeatureAccess.fromJson(Map<String, dynamic> json) {
    return FeatureAccess(
      name: json['name'] as String,
      enabled: json['enabled'] as bool,
      reason: json['reason'] as String? ?? '',
      validFrom: json['validFrom'] as String?,
      validUntil: json['validUntil'] as String?,
    );
  }

  bool get isCurrentlyValid {
    if (!enabled) return false;
    final now = DateTime.now();
    if (validFrom != null) {
      final from = DateTime.tryParse(validFrom!);
      if (from != null && now.isBefore(from)) return false;
    }
    if (validUntil != null) {
      final until = DateTime.tryParse(validUntil!);
      if (until != null && now.isAfter(until)) return false;
    }
    return true;
  }
}

final featureAccessProvider =
    StateNotifierProvider<FeatureAccessNotifier, List<FeatureAccess>>((ref) {
      return FeatureAccessNotifier(ref);
    });

class FeatureAccessNotifier extends StateNotifier<List<FeatureAccess>> {
  final Ref ref;
  StreamSubscription? _permissionSubscription;

  FeatureAccessNotifier(this.ref) : super([]) {
    fetchFeatures();
    _listenToRealTimeUpdates();
  }

  void _listenToRealTimeUpdates() {
    _permissionSubscription = WebSocketService().permissionUpdates.listen((event) {
      fetchFeatures();
      ref.read(authViewModelProvider.notifier).refreshUserPermissions();
    });
  }

  @override
  void dispose() {
    _permissionSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchFeatures() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return;

      final url = Uri.parse('${AppUrl.baseUrl}/mobile/features/access');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List featuresList = data['features'] ?? [];
          state = featuresList.map((f) => FeatureAccess.fromJson(f)).toList();
        }
      }
    } catch (e) {
      // Ignore network failures gracefully
    }
  }

  FeatureAccess? getFeature(String name) {
    try {
      final feature = state.firstWhere(
        (f) => f.name.toLowerCase() == name.toLowerCase(),
      );

      if (!feature.isCurrentlyValid) {
        return FeatureAccess(
          name: feature.name,
          enabled: false,
          reason: 'Access time window has expired or is not active yet',
          validFrom: feature.validFrom,
          validUntil: feature.validUntil,
        );
      }

      return feature;
    } catch (e) {
      return null;
    }
  }

  Future<bool> requestAccess(
    String name,
    String reason,
    String fromDate,
    String toDate,
  ) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return false;

      final url = Uri.parse('${AppUrl.baseUrl}/mobile/access-requests');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'featureName': name,
          'reason': reason,
          'requestedFromDate': fromDate,
          'requestedToDate': toDate,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        fetchFeatures();
        ref.read(authViewModelProvider.notifier).refreshUserPermissions();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
