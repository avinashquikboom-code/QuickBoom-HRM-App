import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
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
}

final featureAccessProvider =
    StateNotifierProvider<FeatureAccessNotifier, List<FeatureAccess>>((ref) {
      return FeatureAccessNotifier();
    });

class FeatureAccessNotifier extends StateNotifier<List<FeatureAccess>> {
  FeatureAccessNotifier() : super([]) {
    fetchFeatures();
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
      // Ignore
    }
  }

  FeatureAccess? getFeature(String name) {
    try {
      return state.firstWhere(
        (f) => f.name.toLowerCase() == name.toLowerCase(),
      );
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

      final url = Uri.parse('${AppUrl.baseUrl}/mobile/features/access-request');
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      // Ignore
    }
    return false;
  }
}
