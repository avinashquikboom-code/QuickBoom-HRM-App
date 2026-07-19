import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/features/shift/presentation/providers/shift_viewmodel.dart';
import 'package:quickboom_hrm/features/auth/presentation/providers/auth_viewmodel.dart';
import 'package:quickboom_hrm/core/widgets/shimmer_loading.dart';

class EmployeeShiftView extends ConsumerWidget {
  const EmployeeShiftView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shiftViewModelProvider);
    final user = ref.watch(authViewModelProvider).currentUser;

    ref.listen<ShiftState>(shiftViewModelProvider, (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.primary,
          ),
        );
        ref.read(shiftViewModelProvider.notifier).clearMessages();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(shiftViewModelProvider.notifier).clearMessages();
      }
    });

    final myAssignment = state.assignments.where((a) => a.employeeId == user?.employeeId && a.isActive).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
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
            Text(
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Icon(
                      RemixIcons.time_line,
                      size: 48,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Shift Assigned',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You haven\'t been assigned to any work shift yet. Please contact your HR or manager for shift assignment.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
            Text(
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _RequestShiftChangeSheet(
                      currentShiftName: myAssignment?.shift.name ?? 'None',
                    ),
                  );
                },
                icon: const Icon(RemixIcons.refresh_line),
                label: const Text('Request Shift Change', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            if (state.myRequests.isNotEmpty) ...[
              const SizedBox(height: 30),
              Text(
                'My Requests History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.myRequests.length,
                itemBuilder: (context, index) {
                  final req = state.myRequests[index];
                  final statusColor = _statusColor(req.status);
                  final statusBg = _statusBg(req.status);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${req.currentShift} ➔ ${req.requestedShift}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                req.statusLabel,
                                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          req.reason,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Requested: ${DateFormat('dd MMM yyyy').format(req.createdAt)}',
                              style: TextStyle(color: AppColors.textHint, fontSize: 11),
                            ),
                            if (req.decidedAt != null)
                              Text(
                                'Decided: ${DateFormat('dd MMM yyyy').format(req.decidedAt!)}',
                                style: TextStyle(color: AppColors.textHint, fontSize: 11),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
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
          child: Text(text, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
        ),
      ],
    );
  }
}

class _RequestShiftChangeSheet extends ConsumerStatefulWidget {
  final String currentShiftName;
  const _RequestShiftChangeSheet({required this.currentShiftName});

  @override
  ConsumerState<_RequestShiftChangeSheet> createState() => _RequestShiftChangeSheetState();
}

class _RequestShiftChangeSheetState extends ConsumerState<_RequestShiftChangeSheet> {
  String? _selectedShiftName;
  final _reasonCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedShiftName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a shift')),
      );
      return;
    }

    final success = await ref.read(shiftViewModelProvider.notifier).submitShiftRequest(
      _selectedShiftName!,
      _reasonCtrl.text.trim(),
    );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shiftState = ref.watch(shiftViewModelProvider);
    final availableShifts = shiftState.shifts.where((s) => s.name != widget.currentShiftName).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Request Shift Change',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Current Shift: ${widget.currentShiftName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedShiftName,
              decoration: const InputDecoration(
                labelText: 'Select Requested Shift',
                border: OutlineInputBorder(),
              ),
              items: availableShifts.map((s) {
                return DropdownMenuItem<String>(
                  value: s.name,
                  child: Text('${s.name} (${s.timingLabel})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedShiftName = val),
              validator: (val) => val == null ? 'Please select a shift' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for request',
                hintText: 'Describe why you need this shift change...',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Please enter a reason (min 5 characters)'
                  : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: shiftState.isSubmitting ? null : _submit,
                child: shiftState.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'APPROVED':
      return AppColors.success;
    case 'REJECTED':
      return AppColors.error;
    default:
      return AppColors.warning;
  }
}

Color _statusBg(String status) {
  switch (status.toUpperCase()) {
    case 'APPROVED':
      return AppColors.successSurface;
    case 'REJECTED':
      return AppColors.errorSurface;
    default:
      return AppColors.warningSurface;
  }
}
