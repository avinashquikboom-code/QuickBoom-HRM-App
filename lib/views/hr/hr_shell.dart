import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import '../../core/constants/app_colors.dart';
import 'hr_dashboard_view.dart';
import 'hr_employees_view.dart';
import 'hr_leave_approval_view.dart';
import 'hr_payroll_view.dart';

class HrShell extends ConsumerStatefulWidget {
  const HrShell({super.key});

  @override
  ConsumerState<HrShell> createState() => _HrShellState();
}

class _HrShellState extends ConsumerState<HrShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HrDashboardView(),
    HrEmployeesView(),
    HrLeaveApprovalView(),
    HrPayrollView(),
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
            icon: Icon(RemixIcons.wallet_3_line),
            activeIcon: Icon(RemixIcons.wallet_3_fill),
            label: 'Payroll',
          ),
        ],
      ),
    );
  }
}
