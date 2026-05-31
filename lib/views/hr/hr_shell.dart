import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        items: const [
          CustomBottomNavBarItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            label: 'Home',
          ),
          CustomBottomNavBarItem(
            icon: Icons.people_outline_rounded,
            selectedIcon: Icons.people_rounded,
            label: 'Staff',
          ),
          CustomBottomNavBarItem(
            icon: Icons.event_note_outlined,
            selectedIcon: Icons.event_note_rounded,
            label: 'Leaves',
          ),
          CustomBottomNavBarItem(
            icon: Icons.payments_outlined,
            selectedIcon: Icons.payments_rounded,
            label: 'Payroll',
          ),
        ],
      ),
    );
  }
}
