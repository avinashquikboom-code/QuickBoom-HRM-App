import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/features/dashboard/presentation/screens/employee_dashboard_view.dart';
import 'package:quickboom_hrm/features/attendance/presentation/screens/employee_attendance_view.dart';
import 'package:quickboom_hrm/features/payroll/presentation/screens/employee_payroll_view.dart';
import 'package:quickboom_hrm/features/leave/presentation/screens/employee_leave_view.dart';
import 'package:quickboom_hrm/features/profile/presentation/screens/employee_profile_view.dart';
import 'package:quickboom_hrm/features/wallet/presentation/screens/employee_wallet_view.dart';

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
        return const EmployeeWalletView();
      case 3:
        return const EmployeeLeaveView();
      case 4:
        return const EmployeeProfileView();
      default:
        return const EmployeeDashboardView();
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
                  color: isSelected ? AppColors.primary : cs.onSurface.withValues(alpha: 0.45),
                  size: 22,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : cs.onSurface.withValues(alpha: 0.45),
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
        color: cs.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, RemixIcons.home_3_line, RemixIcons.home_3_fill, 'Home', cs),
            _buildNavItem(1, RemixIcons.time_line, RemixIcons.time_fill, 'Attend', cs),
            const SizedBox(width: 44), // Central notch spacing
            _buildNavItem(3, RemixIcons.calendar_todo_line, RemixIcons.calendar_todo_fill, 'Leave', cs),
            _buildNavItem(4, RemixIcons.user_3_line, RemixIcons.user_3_fill, 'Profile', cs),
          ],
        ),
      ),
    );
  }
}
