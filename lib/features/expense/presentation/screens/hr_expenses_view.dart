import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/features/expense/data/models/expense_model.dart';
import 'package:quickboom_hrm/features/expense/presentation/providers/hr_expense_viewmodel.dart';
import 'package:quickboom_hrm/features/auth/presentation/providers/auth_viewmodel.dart';
import 'package:quickboom_hrm/core/widgets/shimmer_loading.dart';

class HrExpensesView extends ConsumerWidget {
  const HrExpensesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hrExpenseViewModelProvider);

    ref.listen<HrExpenseState>(hrExpenseViewModelProvider, (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!), backgroundColor: AppColors.primary),
        );
        ref.read(hrExpenseViewModelProvider.notifier).clearMessage();
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
          'Expense Approval',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Analytics
                Row(
                  children: [
                    Expanded(child: _SummaryCard(label: 'Pending Amount', amount: state.totalPendingAmount, color: AppColors.warning)),
                    const SizedBox(width: 10),
                    Expanded(child: _SummaryCard(label: 'Approved/Reimbursed', amount: state.totalApprovedAmount, color: AppColors.success)),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  'Pending Approvals',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),

                if (state.isProcessing && state.pendingExpenses.isEmpty)
                  Column(
                    children: [
                      ShimmerLoading(
                        height: 80,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 12),
                      ShimmerLoading(
                        height: 80,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  )
                else if (state.pendingExpenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('No pending expenses.', style: TextStyle(color: AppColors.textSecondary))),
                  )
                else
                  ...state.pendingExpenses.map(
                    (expense) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HrExpenseCard(expense: expense, isPending: true),
                    ),
                  ),

                const SizedBox(height: 20),
                const Text(
                  'Review History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),

                if (state.reviewedExpenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('No reviewed expenses.', style: TextStyle(color: AppColors.textSecondary))),
                  )
                else
                  ...state.reviewedExpenses.map(
                    (expense) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HrExpenseCard(expense: expense, isPending: false),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryCard({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 6),
          Text('₹${NumberFormat('#,##,###').format(amount)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _HrExpenseCard extends ConsumerWidget {
  final ExpenseModel expense;
  final bool isPending;

  const _HrExpenseCard({required this.expense, required this.isPending});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(expense.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                expense.employeeName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
              ),
              Text(
                '₹${NumberFormat('#,##,###').format(expense.amount)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${expense.department} • ${expense.categoryLabel}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            expense.description,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Submitted: ${DateFormat('dd MMM').format(expense.date)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
              if (isPending)
                Row(
                  children: [
                    _ActionButton(
                      icon: RemixIcons.close_line,
                      color: AppColors.error,
                      onTap: () => _reject(context, ref),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: RemixIcons.check_line,
                      color: AppColors.success,
                      onTap: () {
                        final hrName = ref.read(authViewModelProvider).currentUser!.name;
                        ref.read(hrExpenseViewModelProvider.notifier).approveExpense(expense.id, hrName);
                      },
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    expense.statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _reject(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Expense', style: TextStyle(fontSize: 16)),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Reason for rejection (Optional)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                final hrName = ref.read(authViewModelProvider).currentUser!.name;
                ref.read(hrExpenseViewModelProvider.notifier).rejectExpense(expense.id, hrName, ctrl.text);
                Navigator.pop(ctx);
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  Color _statusColor(ExpenseStatus s) {
    switch (s) {
      case ExpenseStatus.pending: return AppColors.warning;
      case ExpenseStatus.approved: return AppColors.success;
      case ExpenseStatus.reimbursed: return AppColors.primary;
      case ExpenseStatus.rejected: return AppColors.error;
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
