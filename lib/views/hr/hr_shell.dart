import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import '../widgets/custom_bottom_nav_bar.dart';
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
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onItemSelected: (i) => setState(() => _currentIndex = i),
        items: [
          CustomBottomNavBarItem(
            icon: RemixIcons.dashboard_line,
            selectedIcon: RemixIcons.dashboard_fill,
            label: 'Home',
          ),
          CustomBottomNavBarItem(
            icon: RemixIcons.group_line,
            selectedIcon: RemixIcons.group_fill,
            label: 'Staff',
          ),
          CustomBottomNavBarItem(
            icon: RemixIcons.calendar_event_line,
            selectedIcon: RemixIcons.calendar_event_fill,
            label: 'Leaves',
          ),
          CustomBottomNavBarItem(
            icon: RemixIcons.wallet_3_line,
            selectedIcon: RemixIcons.wallet_3_fill,
            label: 'Payroll',
          ),
        ],
      ),
    );
  }
}
