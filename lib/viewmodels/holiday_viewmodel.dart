import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_url.dart';

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
      // Mocking the API call for now since backend doesn't have the endpoint implemented.
      await Future.delayed(const Duration(milliseconds: 600));

      final dtNow = DateTime.now();
      final holidays = [
        HolidayItem(
          id: '1',
          name: 'New Year Day',
          date: '01 Jan ${dtNow.year}',
          dateTime: DateTime(dtNow.year, 1, 1),
          isPublic: true,
        ),
        HolidayItem(
          id: '2',
          name: 'Independence Day',
          date: '15 Aug ${dtNow.year}',
          dateTime: DateTime(dtNow.year, 8, 15),
          isPublic: true,
        ),
        HolidayItem(
          id: '3',
          name: 'Diwali',
          date: '01 Nov ${dtNow.year}',
          dateTime: DateTime(dtNow.year, 11, 1),
          isPublic: true,
        ),
        HolidayItem(
          id: '4',
          name: 'Christmas',
          date: '25 Dec ${dtNow.year}',
          dateTime: DateTime(dtNow.year, 12, 25),
          isPublic: true,
        ),
      ];

      // Sort by date ascending
      holidays.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      state = state.copyWith(holidays: holidays, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final holidayViewModelProvider =
    StateNotifierProvider<HolidayViewModel, HolidayState>((ref) {
  return HolidayViewModel();
});
