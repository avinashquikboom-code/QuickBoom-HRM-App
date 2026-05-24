import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shift_model.dart';

// ─── Shift State ───────────────────────────────────────────────────────────────

class ShiftState {
  final List<ShiftModel> shifts;
  final List<EmployeeShiftAssignment> assignments;
  final bool isLoading;

  const ShiftState({
    this.shifts = const [],
    this.assignments = const [],
    this.isLoading = false,
  });

  ShiftState copyWith({
    List<ShiftModel>? shifts,
    List<EmployeeShiftAssignment>? assignments,
    bool? isLoading,
  }) {
    return ShiftState(
      shifts: shifts ?? this.shifts,
      assignments: assignments ?? this.assignments,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Shift ViewModel ──────────────────────────────────────────────────────────

class ShiftViewModel extends StateNotifier<ShiftState> {
  ShiftViewModel()
      : super(ShiftState(
          shifts: _mockShifts,
          assignments: _mockAssignments,
        ));

  static final List<ShiftModel> _mockShifts = [
    const ShiftModel(
      id: 'SH001',
      name: 'General Shift',
      startTime: '09:00',
      endTime: '18:00',
      workingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      graceMinutes: 15,
      breakMinutes: 60,
      color: '#3BA38B',
    ),
    const ShiftModel(
      id: 'SH002',
      name: 'Morning Shift',
      startTime: '06:00',
      endTime: '14:00',
      workingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      graceMinutes: 10,
      breakMinutes: 30,
      color: '#F59E0B',
    ),
    const ShiftModel(
      id: 'SH003',
      name: 'Evening Shift',
      startTime: '14:00',
      endTime: '22:00',
      workingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      graceMinutes: 10,
      breakMinutes: 30,
      color: '#8B5CF6',
    ),
    const ShiftModel(
      id: 'SH004',
      name: 'Night Shift',
      startTime: '22:00',
      endTime: '06:00',
      workingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      graceMinutes: 15,
      breakMinutes: 60,
      color: '#1E40AF',
    ),
  ];

  static final List<EmployeeShiftAssignment> _mockAssignments = [
    EmployeeShiftAssignment(
      employeeId: 'QB001',
      employeeName: 'Rahul Sharma',
      department: 'Engineering',
      shift: _mockShifts[0],
      effectiveFrom: DateTime(2025, 1, 1),
    ),
    EmployeeShiftAssignment(
      employeeId: 'QB002',
      employeeName: 'Priya Patel',
      department: 'Design',
      shift: _mockShifts[0],
      effectiveFrom: DateTime(2025, 1, 1),
    ),
    EmployeeShiftAssignment(
      employeeId: 'QB003',
      employeeName: 'Amit Kumar',
      department: 'Engineering',
      shift: _mockShifts[1],
      effectiveFrom: DateTime(2025, 3, 1),
    ),
    EmployeeShiftAssignment(
      employeeId: 'QB004',
      employeeName: 'Sneha Verma',
      department: 'Marketing',
      shift: _mockShifts[0],
      effectiveFrom: DateTime(2025, 1, 1),
    ),
    EmployeeShiftAssignment(
      employeeId: 'QB005',
      employeeName: 'Deepak Nair',
      department: 'Finance',
      shift: _mockShifts[2],
      effectiveFrom: DateTime(2025, 4, 1),
    ),
  ];
}

// ─── Providers ────────────────────────────────────────────────────────────────

final shiftViewModelProvider =
    StateNotifierProvider<ShiftViewModel, ShiftState>((ref) {
  return ShiftViewModel();
});
