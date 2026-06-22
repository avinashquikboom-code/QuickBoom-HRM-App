import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import '../../core/constants/app_colors.dart';
import 'hr_dashboard_view.dart';
import 'hr_employees_view.dart';
import 'hr_leave_approval_view.dart';
import 'hr_profile_view.dart';

class HrShell extends ConsumerStatefulWidget {
  const HrShell({super.key});

  @override
  ConsumerState<HrShell> createState() => _HrShellState();
}

class _HrShellState extends ConsumerState<HrShell> {
  int _currentIndex = 0;

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HrDashboardView();
      case 1:
        return const HrEmployeesView();
      case 2:
        return const HrLeaveApprovalView();
      case 3:
        return const HrProfileView();
      default:
        return const HrDashboardView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(_currentIndex),
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
            icon: Icon(RemixIcons.dashboard_line),
            activeIcon: Icon(RemixIcons.dashboard_fill),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(RemixIcons.group_line),
            activeIcon: Icon(RemixIcons.group_fill),
            label: 'Staff',
          ),
          BottomNavigationBarItem(
            icon: Icon(RemixIcons.calendar_event_line),
            activeIcon: Icon(RemixIcons.calendar_event_fill),
            label: 'Leaves',
          ),
          BottomNavigationBarItem(
            icon: Icon(RemixIcons.user_line),
            activeIcon: Icon(RemixIcons.user_fill),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
