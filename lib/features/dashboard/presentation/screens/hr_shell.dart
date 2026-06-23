import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/features/dashboard/presentation/screens/hr_dashboard_view.dart';
import 'package:quickboom_hrm/features/employees/presentation/screens/hr_employees_view.dart';
import 'package:quickboom_hrm/features/payroll/presentation/screens/hr_payroll_view.dart';
import 'package:quickboom_hrm/features/leave/presentation/screens/hr_leave_approval_view.dart';
import 'package:quickboom_hrm/features/profile/presentation/screens/hr_profile_view.dart';

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
        return const HrPayrollView();
      case 3:
        return const HrLeaveApprovalView();
      case 4:
        return const HrProfileView();
      default:
        return const HrDashboardView();
    }
  }

  Widget _buildNavItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
    ColorScheme cs,
  ) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? selectedIcon : unselectedIcon,
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  size: 22,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textHint,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: true,
      body: _buildPage(_currentIndex),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 60,
        width: 60,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => setState(() => _currentIndex = 2),
          elevation: 0,
          hoverElevation: 0,
          focusElevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: _currentIndex == 2
                  ? const LinearGradient(
                      colors: [Color(0xFF3BA38B), Color(0xFF1E6B5A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF5BBDA6), Color(0xFF3BA38B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: const Center(
              child: Icon(
                RemixIcons.wallet_3_fill,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        elevation: 16,
        height: 65,
        padding: EdgeInsets.zero,
        color: AppColors.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, RemixIcons.dashboard_line, RemixIcons.dashboard_fill, 'Home', cs),
            _buildNavItem(1, RemixIcons.group_line, RemixIcons.group_fill, 'Staff', cs),
            const SizedBox(width: 44), // Central notch spacing
            _buildNavItem(3, RemixIcons.calendar_event_line, RemixIcons.calendar_event_fill, 'Leaves', cs),
            _buildNavItem(4, RemixIcons.user_line, RemixIcons.user_fill, 'Profile', cs),
          ],
        ),
      ),
    );
  }
}
