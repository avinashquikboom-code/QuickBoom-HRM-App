import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import '../../core/constants/app_colors.dart';
import '../../models/leave_request_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/hr_leave_viewmodel.dart';
import '../../viewmodels/leave_viewmodel.dart';

class HrLeaveApprovalView extends ConsumerStatefulWidget {
  const HrLeaveApprovalView({super.key});

  @override
  ConsumerState<HrLeaveApprovalView> createState() =>
      _HrLeaveApprovalViewState();
}

class _HrLeaveApprovalViewState extends ConsumerState<HrLeaveApprovalView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _downloadLeaveReport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading leave report...')),
      );
      await ref.read(hrLeaveViewModelProvider.notifier).downloadLeaveReport();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave report downloaded successfully!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download report')),
        );
      }
    }
  }

  void _showApplyLeaveSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApplyLeaveSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hrLeaveViewModelProvider);

    ref.listen<HrLeaveState>(hrLeaveViewModelProvider, (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.primary,
          ),
        );
        ref.read(hrLeaveViewModelProvider.notifier).clearMessage();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'Leave Management',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _downloadLeaveReport(),
            icon: Icon(RemixIcons.download_line, color: AppColors.primary),
            tooltip: 'Download Leave Report',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (state.pendingLeaves.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${state.pendingLeaves.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'All Requests'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApplyLeaveSheet(context),
        backgroundColor: AppColors.primary,
        icon: Icon(RemixIcons.add_line, color: Colors.white),
        label: const Text(
          'Apply Leave',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── Pending Tab ──────────────────────────────────────────────
          _LeaveList(
            leaves: state.pendingLeaves,
            isPending: true,
            isProcessing: state.isProcessing,
            emptyMessage: '🎉 All leave requests have been reviewed!',
          ),

          // ─── All Tab ──────────────────────────────────────────────────
          _LeaveList(
            leaves: state.allLeaves,
            isPending: false,
            isProcessing: state.isProcessing,
            emptyMessage: 'No leave requests found.',
          ),
        ],
      ),
    );
  }
}

// ─── Leave List ───────────────────────────────────────────────────────────────

class _LeaveList extends ConsumerWidget {
  final List<LeaveRequestModel> leaves;
  final bool isPending;
  final bool isProcessing;
  final String emptyMessage;

  const _LeaveList({
    required this.leaves,
    required this.isPending,
    required this.isProcessing,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (leaves.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPending
                    ? RemixIcons.checkbox_circle_line
                    : RemixIcons.file_list_line,
                size: 56,
                color: AppColors.textHint.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      itemCount: leaves.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final leave = leaves[i];
        return _LeaveCard(
          leave: leave,
          isPending: leave.status == LeaveStatus.pending,
          isProcessing: isProcessing,
          onApprove: isPending
              ? () => _approve(context, ref, leave.id)
              : null,
          onReject: isPending
              ? () => _showRejectDialog(context, ref, leave.id)
              : null,
        );
      },
    );
  }

  Future<void> _approve(
      BuildContext context, WidgetRef ref, String leaveId) async {
    final reviewer =
        ref.read(authViewModelProvider).currentUser?.name ?? 'HR Manager';
    await ref
        .read(hrLeaveViewModelProvider.notifier)
        .approveLeave(leaveId, reviewer);
  }

  Future<void> _showRejectDialog(
      BuildContext context, WidgetRef ref, String leaveId) async {
    final noteCtrl = TextEditingController();
    final reviewer =
        ref.read(authViewModelProvider).currentUser?.name ?? 'HR Manager';

    await showDialog(
      context: context,
      builder: (ctx) => _buildDialog(ctx, ref, leaveId, noteCtrl, reviewer),
    );
  }

  Widget _buildDialog(BuildContext ctx, WidgetRef ref, String leaveId, TextEditingController noteCtrl, String reviewer) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(RemixIcons.close_circle_line, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          const Text('Reject Leave'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Provide a reason for rejection (optional):',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. Project deadline, reschedule...',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () async {
            Navigator.pop(ctx);
            await ref
                .read(hrLeaveViewModelProvider.notifier)
                .rejectLeave(leaveId, reviewer, noteCtrl.text.trim());
          },
          child: const Text('Reject'),
        ),
      ],
    );
  }
}

// ─── Leave Card ───────────────────────────────────────────────────────────────

class _LeaveCard extends StatelessWidget {
  final LeaveRequestModel leave;
  final bool isPending;
  final bool isProcessing;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _LeaveCard({
    required this.leave,
    required this.isPending,
    required this.isProcessing,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(leave.status);
    final statusBg = _statusBg(leave.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.cardBorder,
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Employee + Status
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          leave.employeeName.substring(0, 1),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.employeeName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            leave.department,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        leave.statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Leave Details
                Row(
                  children: [
                    _DetailChip(
                      icon: RemixIcons.file_list_3_line,
                      text: leave.typeLabel,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    _DetailChip(
                      icon: RemixIcons.calendar_todo_line,
                      text: '${leave.daysCount} day(s)',
                      color: AppColors.info,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(RemixIcons.calendar_2_line,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${DateFormat('dd MMM').format(leave.fromDate)} → ${DateFormat('dd MMM yyyy').format(leave.toDate)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(RemixIcons.chat_3_line,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        leave.reason,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (leave.reviewNote != null &&
                    leave.status != LeaveStatus.pending) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          leave.status == LeaveStatus.approved
                              ? RemixIcons.checkbox_circle_line
                              : RemixIcons.information_line,
                          size: 13,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${leave.reviewedBy}: ${leave.reviewNote}',
                            style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Buttons (only for pending)
          if (onApprove != null || onReject != null) ...[
            const Divider(height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: Icon(RemixIcons.close_circle_line, size: 16),
                      label: const Text('Reject',
                          style: TextStyle(fontSize: 13)),
                      onPressed: isProcessing ? null : onReject,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: Icon(RemixIcons.checkbox_circle_line,
                          size: 16, color: Colors.white),
                      label: const Text('Approve',
                          style: TextStyle(
                              fontSize: 13, color: Colors.white)),
                      onPressed: isProcessing ? null : onApprove,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(LeaveStatus s) {
    switch (s) {
      case LeaveStatus.approved:
        return AppColors.success;
      case LeaveStatus.rejected:
        return AppColors.error;
      case LeaveStatus.pending:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _statusBg(LeaveStatus s) {
    switch (s) {
      case LeaveStatus.approved:
        return AppColors.successSurface;
      case LeaveStatus.rejected:
        return AppColors.errorSurface;
      case LeaveStatus.pending:
        return AppColors.warningSurface;
      default:
        return AppColors.background;
    }
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _DetailChip(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Apply Leave Bottom Sheet for HR ─────────────────────────────────────────────────

class _ApplyLeaveSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ApplyLeaveSheet> createState() => _ApplyLeaveSheetState();
}

class _ApplyLeaveSheetState extends ConsumerState<_ApplyLeaveSheet> {
  LeaveType _selectedType = LeaveType.casual;
  DateTime? _fromDate;
  DateTime? _toDate;
  final _reasonCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(picked)) _toDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select leave dates')),
      );
      return;
    }
    final user = ref.read(authViewModelProvider).currentUser!;
    await ref
        .read(leaveViewModelProvider.notifier)
        .applyLeave(
          user: user,
          type: _selectedType,
          fromDate: _fromDate!,
          toDate: _toDate!,
          reason: _reasonCtrl.text.trim(),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final leaveState = ref.watch(leaveViewModelProvider);
    final types = LeaveType.values;
    final typeLabels = {
      LeaveType.casual: 'Casual',
      LeaveType.sick: 'Sick',
      LeaveType.earned: 'Earned',
      LeaveType.maternity: 'Maternity',
      LeaveType.paternity: 'Paternity',
      LeaveType.unpaid: 'Unpaid',
    };

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            const Text(
              'Apply for Leave',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Leave Type
            const Text(
              'Leave Type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: types.map((t) {
                  final isSelected = _selectedType == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(typeLabels[t] ?? t.name),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      onSelected: (_) => setState(() => _selectedType = t),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // Date Range
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'From',
                    date: _fromDate,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateButton(
                    label: 'To',
                    date: _toDate,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Reason
            const Text(
              'Reason',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe the reason for your leave...',
              ),
              validator: (v) => (v == null || v.trim().length < 5)
                  ? 'Please enter a reason (min 5 characters)'
                  : null,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: leaveState.isSubmitting ? null : _submit,
              child: leaveState.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              RemixIcons.calendar_2_line,
              size: 16,
              color: date != null ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('dd MMM yyyy').format(date!)
                    : label,
                style: TextStyle(
                  fontSize: 13,
                  color: date != null ? AppColors.textPrimary : AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
