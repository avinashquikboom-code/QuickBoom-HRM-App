import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/features/payroll/presentation/providers/employee_payroll_viewmodel.dart';
import 'package:quickboom_hrm/features/payroll/presentation/widgets/pay_card_widget.dart';
import 'package:quickboom_hrm/features/profile/presentation/providers/profile_viewmodel.dart';

class EmployeePayrollView extends ConsumerStatefulWidget {
  const EmployeePayrollView({super.key});

  @override
  ConsumerState<EmployeePayrollView> createState() => _EmployeePayrollViewState();
}

class _EmployeePayrollViewState extends ConsumerState<EmployeePayrollView> {
  int? _downloadingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(employeePayrollViewModelProvider.notifier).fetchPayslips();
    });
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final payrollState = ref.watch(employeePayrollViewModelProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Salary History'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(employeePayrollViewModelProvider.notifier).fetchPayslips(),
        color: AppColors.primary,
        child: payrollState.isLoading && payrollState.payslips.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  // ─── Header Summary Card / PayCard ───
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: Builder(builder: (context) {
                        if (payrollState.payslips.isNotEmpty) {
                          final latest = payrollState.payslips.first;
                          return PayCard(
                            employeeName: latest.employeeName,
                            cardNumber: 'HK${latest.employeeCode}',
                            netSalary: latest.netSalary,
                            grossSalary: latest.baseSalary + latest.allowance,
                            commission: latest.commissionEarned ?? 0,
                            monthYear: '${_getMonthName(latest.month)} ${latest.year}',
                          );
                        }

                        final profileUser = ref.watch(profileViewModelProvider).user;
                        final name = (profileUser?.name.isNotEmpty == true)
                            ? profileUser!.name
                            : 'EMPLOYEE';
                        final code = (profileUser?.employeeId.isNotEmpty == true)
                            ? profileUser!.employeeId
                            : '001';
                        final net = profileUser?.salary ?? 15000.0;
                        final gross = net * 1.1;

                        return PayCard(
                          employeeName: name,
                          cardNumber: 'HK$code',
                          netSalary: net,
                          grossSalary: gross,
                          commission: 0,
                          monthYear: 'CURRENT PERIOD',
                        );
                      }).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
                    ),
                  ),

                  // ─── Payslips List ───
                  if (payrollState.errorMessage != null && payrollState.payslips.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(RemixIcons.error_warning_line, size: 48, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(
                              payrollState.errorMessage!,
                              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref
                                  .read(employeePayrollViewModelProvider.notifier)
                                  .fetchPayslips(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (payrollState.payslips.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(RemixIcons.file_history_line, size: 48, color: AppColors.textHint),
                            const SizedBox(height: 16),
                            Text(
                              'No payslips generated yet.',
                              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final slip = payrollState.payslips[index];
                            final isDownloading = _downloadingId == slip.id;
                            final formattedNet = NumberFormat('#,##,###').format(slip.netSalary);
                            final monthLabel = _getMonthName(slip.month);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : AppColors.cardBorder,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark ? Colors.black12 : AppColors.cardShadow,
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '$monthLabel ${slip.year}',
                                        style: TextStyle(
                                          color: cs.onSurface,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      _StatusChip(status: slip.status),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Divider(
                                    height: 1,
                                    color: isDark ? const Color(0xFF334155) : AppColors.cardBorder,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Builder(builder: (context) {
                                          final comm = slip.commissionEarned ?? 0;
                                          final totalPay = slip.netSalary + comm;
                                          final formattedTotalPay = NumberFormat('#,##,###').format(totalPay);
                                          final formattedCommStr = NumberFormat('#,##,###').format(comm);

                                          return Wrap(
                                            spacing: 12,
                                            runSpacing: 6,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'NET SALARY',
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      color: cs.onSurface.withValues(alpha: 0.55),
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '₹$formattedNet',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w800,
                                                      color: cs.onSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '+',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w900,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'COMMISSION',
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      color: AppColors.success,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '₹$formattedCommStr',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w800,
                                                      color: AppColors.success,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '=',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w900,
                                                  color: cs.onSurface.withValues(alpha: 0.55),
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'TOTAL SALARY',
                                                    style: TextStyle(
                                                      fontSize: 9.5,
                                                      color: AppColors.primary,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '₹$formattedTotalPay',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w900,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        }),
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          minimumSize: const Size(0, 36),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                        ),
                                        icon: isDownloading
                                            ? SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(RemixIcons.download_2_line, size: 14),
                                        label: Text(
                                          isDownloading ? 'Downloading...' : 'PDF Slip',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        onPressed: isDownloading
                                            ? null
                                            : () async {
                                                final messenger = ScaffoldMessenger.of(context);
                                                setState(() {
                                                  _downloadingId = slip.id;
                                                });
                                                final success = await ref
                                                    .read(employeePayrollViewModelProvider.notifier)
                                                    .downloadPayslip(slip.id);
                                                if (!mounted) return;
                                                setState(() {
                                                  _downloadingId = null;
                                                });
                                                if (!success) {
                                                  final errorMsg = ref.read(employeePayrollViewModelProvider).errorMessage;
                                                  messenger.showSnackBar(
                                                    SnackBar(
                                                      content: Text(errorMsg ?? 'Failed to download payslip PDF.'),
                                                      backgroundColor: AppColors.error,
                                                    ),
                                                  );
                                                }
                                              },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : AppColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _SalaryComponent(
                                              label: 'Base Pay',
                                              value: '₹${NumberFormat('#,##,###').format(slip.baseSalary)}',
                                            ),
                                            _SalaryComponent(
                                              label: 'Allowance',
                                              value: '₹${NumberFormat('#,##,###').format(slip.allowance)}',
                                            ),
                                            _SalaryComponent(
                                              label: 'Deductions',
                                              value: '₹${NumberFormat('#,##,###').format(slip.deductions)}',
                                            ),
                                          ],
                                        ),
                                        if (slip.commissionEarned != null) ...[
                                          const SizedBox(height: 8),
                                          Divider(
                                            height: 1,
                                            color: isDark ? const Color(0xFF334155) : AppColors.cardBorder,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              _SalaryComponent(
                                                label: 'Commission Earned',
                                                value: '₹${slip.commissionEarned!.toStringAsFixed(2)}',
                                                isCommission: true,
                                              ),
                                              if (slip.presentDays != null)
                                                _SalaryComponent(
                                                  label: 'Present Days',
                                                  value: '${slip.presentDays} Days',
                                                ),
                                            ],
                                          ),
                                        ],
                                        if ((slip.halfDays != null && slip.halfDays! > 0) || (slip.leaveDays != null && slip.leaveDays! > 0)) ...[
                                          const SizedBox(height: 8),
                                          Divider(
                                            height: 1,
                                            color: isDark ? const Color(0xFF334155) : AppColors.cardBorder,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (slip.halfDays != null && slip.halfDays! > 0)
                                                _SalaryComponent(
                                                  label: 'Half-days (${slip.halfDays})',
                                                  value: '-₹${(slip.halfDayDeduction ?? 0.0).toStringAsFixed(2)}',
                                                  isDeduction: true,
                                                ),
                                              if (slip.leaveDays != null && slip.leaveDays! > 0)
                                                _SalaryComponent(
                                                  label: 'Unplanned Leave (${slip.leaveDays})',
                                                  value: '-₹${(slip.leaveDeduction ?? 0.0).toStringAsFixed(2)}',
                                                  isDeduction: true,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ).animate(delay: (index * 80).ms).fadeIn(duration: 400.ms).slideY(
                                  begin: 0.08,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                );
                          },
                          childCount: payrollState.payslips.length,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    switch (status.toLowerCase()) {
      case 'approved':
      case 'paid':
        bg = AppColors.successSurface;
        text = AppColors.success;
        break;
      case 'pending approval':
      case 'pending':
      default:
        bg = Colors.amber.shade50;
        text = Colors.amber.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SalaryComponent extends StatelessWidget {
  final String label;
  final String value;
  final bool isCommission;
  final bool isDeduction;

  const _SalaryComponent({
    required this.label,
    required this.value,
    this.isCommission = false,
    this.isDeduction = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color valueColor = cs.onSurface;

    if (isCommission) {
      valueColor = AppColors.primary;
    } else if (isDeduction) {
      valueColor = AppColors.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            color: cs.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
