import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/viewmodels/leave_viewmodel.dart';
import '../models/attendance_model.dart';

class AttendanceState {
  final List<AttendanceModel> history;
  final AttendanceModel? todayRecord;
  final bool isCheckedIn;
  final bool isLoading;
  final LeaveBalance leaveBalance;

  const AttendanceState({
    this.history = const [],
    this.todayRecord,
    this.isCheckedIn = false,
    this.isLoading = false,
    this.leaveBalance = const LeaveBalance(),
  });

  AttendanceState copyWith({
    List<AttendanceModel>? history,
    AttendanceModel? todayRecord,
    bool? isCheckedIn,
    bool? isLoading,
    LeaveBalance? leaveBalance,
    bool clearToday = false,
  }) {
    return AttendanceState(
      history: history ?? this.history,
      todayRecord: clearToday ? null : (todayRecord ?? this.todayRecord),
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      isLoading: isLoading ?? this.isLoading,
      leaveBalance: leaveBalance ?? this.leaveBalance,
    );
  }

  int get presentCount => history
      .where(
        (a) =>
            a.status == AttendanceStatus.present ||
            a.status == AttendanceStatus.late,
      )
      .length;

  int get absentCount =>
      history.where((a) => a.status == AttendanceStatus.absent).length;

  int get lateCount =>
      history.where((a) => a.status == AttendanceStatus.late).length;

  int get halfDayCount =>
      history.where((a) => a.status == AttendanceStatus.halfDay).length;
}

// ─── Attendance ViewModel ────────────────────────────────────────────────────

class AttendanceViewModel extends StateNotifier<AttendanceState> {
  AttendanceViewModel()
    : super(AttendanceState(history: _generateMockHistory()));

  void checkIn({bool viaFingerprint = false}) {
    final now = DateTime.now();
    final isLate = now.hour > 9 || (now.hour == 9 && now.minute > 15);
    final record = AttendanceModel(
      id: 'today_${now.millisecondsSinceEpoch}',
      employeeId: 'current',
      date: DateTime(now.year, now.month, now.day),
      checkIn: now,
      status: isLate ? AttendanceStatus.late : AttendanceStatus.present,
      isFingerprintCheckIn: viaFingerprint,
    );
    state = state.copyWith(todayRecord: record, isCheckedIn: true);
  }

  void checkOut({bool viaFingerprint = false}) {
    if (state.todayRecord == null) return;
    final now = DateTime.now();
    
    var today = state.todayRecord!;
    if (today.isOnBreak && today.breakStartTime != null) {
      final elapsed = now.difference(today.breakStartTime!);
      today = today.copyWith(
        isOnBreak: false,
        clearBreakStartTime: true,
        totalBreakDuration: today.totalBreakDuration + elapsed,
      );
    }

    final updated = today.copyWith(
      checkOut: now,
      isFingerprintCheckOut: viaFingerprint,
    );
    state = state.copyWith(todayRecord: updated, isCheckedIn: false);
  }

  void startBreak() {
    if (state.todayRecord == null || !state.isCheckedIn) return;
    final updated = state.todayRecord!.copyWith(
      isOnBreak: true,
      breakStartTime: DateTime.now(),
    );
    state = state.copyWith(todayRecord: updated);
  }

  void endBreak() {
    if (state.todayRecord == null || !state.isCheckedIn || !state.todayRecord!.isOnBreak || state.todayRecord!.breakStartTime == null) return;
    final now = DateTime.now();
    final elapsed = now.difference(state.todayRecord!.breakStartTime!);
    final updated = state.todayRecord!.copyWith(
      isOnBreak: false,
      clearBreakStartTime: true,
      totalBreakDuration: state.todayRecord!.totalBreakDuration + elapsed,
    );
    state = state.copyWith(todayRecord: updated);
  }

  static List<AttendanceModel> _generateMockHistory() {
    final List<AttendanceModel> history = [];
    final now = DateTime.now();
    final statuses = [
      AttendanceStatus.present,
      AttendanceStatus.present,
      AttendanceStatus.present,
      AttendanceStatus.late,
      AttendanceStatus.present,
      AttendanceStatus.absent,
      AttendanceStatus.present,
      AttendanceStatus.halfDay,
      AttendanceStatus.present,
      AttendanceStatus.present,
    ];

    for (int i = 1; i <= 25; i++) {
      final date = now.subtract(Duration(days: i));
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        history.add(
          AttendanceModel(
            id: 'att_$i',
            employeeId: 'QB001',
            date: date,
            status: AttendanceStatus.weekend,
          ),
        );
      } else {
        final status = statuses[i % statuses.length];
        final hasRecord = status != AttendanceStatus.absent;
        final checkInHour = status == AttendanceStatus.late ? 10 : 9;
        final checkInMin = status == AttendanceStatus.late ? 30 : 5;

        history.add(
          AttendanceModel(
            id: 'att_$i',
            employeeId: 'QB001',
            date: date,
            checkIn: hasRecord
                ? DateTime(
                    date.year,
                    date.month,
                    date.day,
                    checkInHour,
                    checkInMin,
                  )
                : null,
            checkOut: hasRecord
                ? DateTime(
                    date.year,
                    date.month,
                    date.day,
                    status == AttendanceStatus.halfDay ? 13 : 18,
                    0,
                  )
                : null,
            status: status,
          ),
        );
      }
    }
    return history;
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final attendanceViewModelProvider =
    StateNotifierProvider<AttendanceViewModel, AttendanceState>((ref) {
      return AttendanceViewModel();
    });
