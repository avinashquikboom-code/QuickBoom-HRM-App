import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import 'package:remixicon/remixicon.dart';
import '../../viewmodels/shift_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/shimmer_loading.dart';

class EmployeeShiftView extends ConsumerWidget {
  const EmployeeShiftView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shiftViewModelProvider);
    final user = ref.watch(authViewModelProvider).currentUser;

    final myAssignment = state.assignments.where((a) => a.employeeId == user?.employeeId && a.isActive).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'My Shift Schedule',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Shift',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            if (state.isLoading)
              ShimmerLoading(
                height: 120,
                width: double.infinity,
                borderRadius: BorderRadius.circular(16),
              )
            else if (myAssignment == null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Text('No active shift assigned.'),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          myAssignment.shift.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(RemixIcons.time_line, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          myAssignment.shift.timingLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(RemixIcons.calendar_event_line, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          myAssignment.shift.daysLabel,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ShiftDetailInfo(label: 'Total Hours', value: '${myAssignment.shift.totalHours} hrs'),
                        _ShiftDetailInfo(label: 'Break Time', value: '${myAssignment.shift.breakMinutes} mins'),
                        _ShiftDetailInfo(label: 'Grace Period', value: '${myAssignment.shift.graceMinutes} mins'),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),
            const Text(
              'Shift Guidelines',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Column(
                children: [
                  _GuidelineRow(text: 'Punch in must be done within the grace period to avoid late marks.'),
                  SizedBox(height: 8),
                  _GuidelineRow(text: 'Break time should be strictly adhered to as per the shift policy.'),
                  SizedBox(height: 8),
                  _GuidelineRow(text: 'For shift change requests, contact your reporting manager 7 days prior.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftDetailInfo extends StatelessWidget {
  final String label;
  final String value;
  const _ShiftDetailInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _GuidelineRow extends StatelessWidget {
  final String text;
  const _GuidelineRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 8),
          child: Icon(RemixIcons.checkbox_blank_circle_fill, size: 6, color: AppColors.textHint),
        ),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
        ),
      ],
    );
  }
}
