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
      final res = await ApiService.get(AppUrl.employeeHolidays);
      final data = jsonDecode(res.body);

      // API may return { "holidays": [...] } or { "data": [...] }
      final List rawHolidays =
          data['holidays'] ?? data['data'] ?? [];

      final holidays = rawHolidays.map((h) {
        final rawDate = h['date']?.toString() ?? '';
        final dt = DateTime.tryParse(rawDate) ?? DateTime.now();

        // Format date as "dd MMM yyyy" for display
        final months = [
          '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final formatted =
            '${dt.day.toString().padLeft(2, '0')} ${months[dt.month]} ${dt.year}';

        final typeStr = h['type']?.toString().toLowerCase() ?? 'public';
        final isPublic = typeStr == 'public' || typeStr == 'national';

        return HolidayItem(
          id: h['id']?.toString() ?? '',
          name: h['name']?.toString() ?? '',
          date: formatted,
          dateTime: dt,
          isPublic: isPublic,
        );
      }).toList();

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
