import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import '../../core/constants/app_colors.dart';
import 'employee_dashboard_view.dart';
import 'employee_attendance_view.dart';
import 'employee_leave_view.dart';
import 'employee_profile_view.dart';

class EmployeeShell extends ConsumerStatefulWidget {
  const EmployeeShell({super.key});

  @override
  ConsumerState<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends ConsumerState<EmployeeShell> {
  int _currentIndex = 0;

  final _pages = const [
    EmployeeDashboardView(),
    EmployeeAttendanceView(),
    EmployeeLeaveView(),
    EmployeeProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: [
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
