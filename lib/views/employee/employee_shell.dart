import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_bottom_nav_bar.dart';
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
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onItemSelected: (i) => setState(() => _currentIndex = i),
        items: const [
          CustomBottomNavBarItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            label: 'Home',
          ),
          CustomBottomNavBarItem(
            icon: Icons.access_time_outlined,
            selectedIcon: Icons.access_time_filled_rounded,
            label: 'Attend',
          ),
          CustomBottomNavBarItem(
            icon: Icons.event_note_outlined,
            selectedIcon: Icons.event_note_rounded,
            label: 'Leave',
          ),
          CustomBottomNavBarItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
