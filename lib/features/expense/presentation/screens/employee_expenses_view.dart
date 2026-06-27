import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/features/expense/data/models/expense_model.dart';
import 'package:quickboom_hrm/features/auth/presentation/providers/auth_viewmodel.dart';
import 'package:quickboom_hrm/features/expense/presentation/providers/expense_viewmodel.dart';
import 'package:quickboom_hrm/core/widgets/shimmer_loading.dart';

class EmployeeExpensesView extends ConsumerStatefulWidget {
  const EmployeeExpensesView({super.key});

  @override
  ConsumerState<EmployeeExpensesView> createState() =>
      _EmployeeExpensesViewState();
}

class _EmployeeExpensesViewState extends ConsumerState<EmployeeExpensesView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseViewModelProvider);

    ref.listen<ExpenseState>(expenseViewModelProvider, (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.primary,
          ),
        );
        ref.read(expenseViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'My Expenses',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseSheet(context),
        backgroundColor: AppColors.primary,
        icon: Icon(RemixIcons.add_line, color: Colors.white),
        label: const Text('Claim Expense',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Summary Cards ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Approved',
                        amount: state.totalApproved,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Pending',
                        amount: state.totalPending,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ─── Expense History ───────────────────────────────────────
                Text(
                  'Recent Claims',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                if (state.isLoading)
                  Column(
                    children: [
                      ShimmerLoading(
                        height: 80,
                        width: double.infinity,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 12),
                      ShimmerLoading(
                        height: 80,
                        width: double.infinity,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 12),
                      ShimmerLoading(
                        height: 80,
                        width: double.infinity,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  )
                else if (state.myExpenses.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('No expenses found.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                else
                  ...state.myExpenses.map(
                    (expense) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ExpenseCard(expense: expense),
                    ),
                  ),

                const SizedBox(height: 80), // Fab spacing
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddExpenseSheet(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
  });

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
          Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${NumberFormat('#,##,###').format(amount)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(expense.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_categoryIcon(expense.category),
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    expense.categoryLabel,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                ],
              ),
              Text(
                '₹${NumberFormat('#,##,###').format(expense.amount)}',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            expense.description,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy').format(expense.date),
                style:
                    TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
              Row(
                children: [
                  if (expense.hasReceipt) ...[
                    Icon(RemixIcons.bill_line,
                        size: 14, color: AppColors.info),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      expense.statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(ExpenseStatus s) {
    switch (s) {
      case ExpenseStatus.pending:
        return AppColors.warning;
      case ExpenseStatus.approved:
        return AppColors.success;
      case ExpenseStatus.reimbursed:
        return AppColors.primary;
      case ExpenseStatus.rejected:
        return AppColors.error;
    }
  }

  IconData _categoryIcon(ExpenseCategory c) {
    switch (c) {
      case ExpenseCategory.travel:
        return RemixIcons.plane_line;
      case ExpenseCategory.food:
        return RemixIcons.restaurant_line;
      case ExpenseCategory.accommodation:
        return RemixIcons.hotel_bed_line;
      case ExpenseCategory.stationery:
        return RemixIcons.edit_box_line;
      case ExpenseCategory.medical:
        return RemixIcons.first_aid_kit_line;
      case ExpenseCategory.other:
        return RemixIcons.bill_line;
    }
  }
}

// ─── Add Expense Sheet ────────────────────────────────────────────────────────

class _AddExpenseSheet extends ConsumerStatefulWidget {
  const _AddExpenseSheet();

  @override
  ConsumerState<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<_AddExpenseSheet> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.travel;
  DateTime _date = DateTime.now();
  bool _hasReceipt = false;

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0 || _descCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid amount and description')),
      );
      return;
    }

    final user = ref.read(authViewModelProvider).currentUser!;
    await ref.read(expenseViewModelProvider.notifier).submitExpense(
          user: user,
          category: _category,
          amount: amount,
          description: _descCtrl.text.trim(),
          date: _date,
          hasReceipt: _hasReceipt,
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseViewModelProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
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
              'Claim Expense',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),

            // Category
            const Text('Category',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(isDense: true),
              items: ExpenseCategory.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 16),

            // Amount
            const Text('Amount (₹)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '0.00'),
            ),
            const SizedBox(height: 16),

            // Description
            const Text('Description',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Brief details...'),
            ),
            const SizedBox(height: 16),

            // Date
            Row(
              children: [
                Icon(RemixIcons.calendar_event_line, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(DateFormat('dd MMM yyyy').format(_date)),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  child: const Text('Change'),
                ),
              ],
            ),

            // Receipt
            Row(
              children: [
                Checkbox(
                  value: _hasReceipt,
                  onChanged: (v) => setState(() => _hasReceipt = v ?? false),
                  activeColor: AppColors.primary,
                ),
                const Text('Attach Receipt'),
              ],
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isSubmitting ? null : _submit,
                child: state.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Claim'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
