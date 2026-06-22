import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';

// ─── Holiday Model ────────────────────────────────────────────────────────────

class HolidayItem {
  final String id;
  final String name;
  final String date;        // formatted display string e.g. "26 Jan 2026"
  final DateTime dateTime;
  final bool isPublic;

  const HolidayItem({
    required this.id,
    required this.name,
    required this.date,
    required this.dateTime,
    required this.isPublic,
  });
}

// ─── Holiday State ────────────────────────────────────────────────────────────

class HolidayState {
  final List<HolidayItem> holidays;
  final bool isLoading;

  const HolidayState({
    this.holidays = const [],
    this.isLoading = false,
  });

  HolidayState copyWith({
    List<HolidayItem>? holidays,
    bool? isLoading,
  }) {
    return HolidayState(
      holidays: holidays ?? this.holidays,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Holiday ViewModel ────────────────────────────────────────────────────────

class HolidayViewModel extends StateNotifier<HolidayState> {
  HolidayViewModel() : super(const HolidayState()) {
    fetchHolidays();
  }

  Future<void> fetchHolidays() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiService.get(AppUrl.employeeHolidays);
      final data = jsonDecode(response.body);
      
      final List rawHolidays = data['holidays'] ?? [];
      final holidays = rawHolidays.map((h) => HolidayItem(
        id: h['id']?.toString() ?? '',
        name: h['name']?.toString() ?? '',
        date: h['date']?.toString() ?? '',
        dateTime: DateTime.tryParse(h['date']?.toString() ?? '') ?? DateTime.now(),
        isPublic: h['isPublic'] ?? true,
      )).toList();

      // Sort by date ascending
      holidays.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      state = state.copyWith(holidays: holidays, isLoading: false);
    } catch (e) {
      debugPrint('Error fetching holidays: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final holidayViewModelProvider =
    StateNotifierProvider<HolidayViewModel, HolidayState>((ref) {
  return HolidayViewModel();
});
