import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/features/dashboard/presentation/screens/employee_dashboard_view.dart';
import 'package:quickboom_hrm/features/attendance/presentation/screens/employee_attendance_view.dart';
import 'package:quickboom_hrm/features/leave/presentation/screens/employee_leave_view.dart';
import 'package:quickboom_hrm/features/profile/presentation/screens/employee_profile_view.dart';

class EmployeeShell extends ConsumerStatefulWidget {
  const EmployeeShell({super.key});

  @override
  ConsumerState<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends ConsumerState<EmployeeShell> {
  int _currentIndex = 0;

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const EmployeeDashboardView();
      case 1:
        return const EmployeeAttendanceView();
      case 2:
        return const EmployeeLeaveView();
      case 3:
        return const EmployeeProfileView();
      default:
        return const EmployeeDashboardView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: _buildPage(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: cs.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: cs.onSurface.withValues(alpha: 0.45),
        selectedFontSize: 12,
        unselectedFontSize: 11,
        elevation: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(RemixIcons.home_3_line),
            activeIcon: Icon(RemixIcons.home_3_fill),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(RemixIcons.time_line),
            activeIcon: Icon(RemixIcons.time_fill),
            label: 'Attend',
          ),
          BottomNavigationBarItem(
            icon: Icon(RemixIcons.calendar_todo_line),
            activeIcon: Icon(RemixIcons.calendar_todo_fill),
            label: 'Leave',
          ),
          BottomNavigationBarItem(
            icon: Icon(RemixIcons.user_3_line),
            activeIcon: Icon(RemixIcons.user_3_fill),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
