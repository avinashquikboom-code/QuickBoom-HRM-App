import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/services/commission_service.dart';
import 'package:quickboom_hrm/features/commission/data/commission_models.dart';
// import 'package:quickboom_hrm/features/commission/presentation/screens/commission_history_view.dart';
// import 'package:quickboom_hrm/features/commission/presentation/screens/commission_details_view.dart';

class CommissionWalletView extends ConsumerStatefulWidget {
  const CommissionWalletView({super.key});

  @override
  ConsumerState<CommissionWalletView> createState() => _CommissionWalletViewState();
}

class _CommissionWalletViewState extends ConsumerState<CommissionWalletView> {
  CommissionWallet? _walletData;
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCommissionWallet();
  }

  Future<void> _loadCommissionWallet() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    final data = await CommissionService.fetchCommissionWallet();

    if (mounted) {
      setState(() {
        _walletData = data;
        _isLoading = false;
        _isError = data == null;
        _errorMessage = data == null ? 'Failed to load commission data' : '';
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadCommissionWallet();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Commission Wallet',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(RemixIcons.history_line, color: AppColors.textPrimary),
            onPressed: () {
              // TODO: Navigate to Commission History when screen is created
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const CommissionHistoryView()),
              // );
            },
          ),
          IconButton(
            icon: Icon(RemixIcons.bar_chart_box_line, color: AppColors.textPrimary),
            onPressed: () {
              // TODO: Navigate to Commission Details when screen is created
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const CommissionDetailsView()),
              // );
            },
          ),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return _buildSkeletonLoader();
    }

    if (_isError) {
      return _buildErrorState();
    }

    if (_walletData == null) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // ─── Total Commission Balance Card ───
                _CommissionBalanceCard(
                  totalBalance: _walletData!.totalCommissionBalance,
                  currentMonth: _walletData!.currentMonthCommission,
                  lastMonth: _walletData!.lastMonthCommission,
                ).animate().fadeIn(duration: 400.ms).scaleXY(begin: 0.95, end: 1.0),

                const SizedBox(height: 20),

                // ─── Commission Stats Grid ───
                _CommissionStatsGrid(
                  lifetimeCommission: _walletData!.lifetimeCommission,
                  pendingCommission: _walletData!.pendingCommission,
                  paidCommission: _walletData!.paidCommission,
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // ─── Monthly Commission Summary ───
                _MonthlyCommissionSummary(
                  summary: _walletData!.monthlySummary,
                ).animate(delay: 150.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // ─── Commission Statistics ───
                _CommissionStatisticsCard(
                  statistics: _walletData!.statistics,
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // ─── Recent Transactions Header ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECENT TRANSACTIONS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigate to Commission History when screen is created
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(builder: (_) => const CommissionHistoryView()),
                        // );
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 250.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 12),
              ]),
            ),
          ),

          // ─── Recent Transactions List ───
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tx = _walletData!.recentTransactions[index];
                  return _CommissionTransactionCard(
                    transaction: tx,
                  ).animate(delay: (250 + index * 50).ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
                },
                childCount: _walletData!.recentTransactions.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              _SkeletonCard(height: 200),
              const SizedBox(height: 20),
              _SkeletonCard(height: 120),
              const SizedBox(height: 24),
              _SkeletonCard(height: 150),
              const SizedBox(height: 24),
              _SkeletonCard(height: 100),
              const SizedBox(height: 24),
              Text(
                'RECENT TRANSACTIONS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _SkeletonCard(height: 80),
              childCount: 5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(RemixIcons.error_warning_line, color: AppColors.error, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Data',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Failed to load commission data. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _onRefresh,
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.infoSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(RemixIcons.inbox_line, color: AppColors.info, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'No Commission Data',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any commission records yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _onRefresh,
              child: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommissionBalanceCard extends StatelessWidget {
  final double totalBalance;
  final double currentMonth;
  final double lastMonth;

  const _CommissionBalanceCard({
    required this.totalBalance,
    required this.currentMonth,
    required this.lastMonth,
  });

  @override
  Widget build(BuildContext context) {
    final formattedBalance = NumberFormat('#,##,###.00').format(totalBalance);
    final formattedCurrent = NumberFormat('#,##,###.00').format(currentMonth);
    final formattedLast = NumberFormat('#,##,###.00').format(lastMonth);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF3BA38B), Color(0xFF1E6B5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E6B5A).withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(RemixIcons.wallet_3_line, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'TOTAL COMMISSION',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '₹$formattedBalance',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _BalanceStat(
                      label: 'This Month',
                      value: '₹$formattedCurrent',
                      icon: RemixIcons.calendar_line,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
                  Expanded(
                    child: _BalanceStat(
                      label: 'Last Month',
                      value: '₹$formattedLast',
                      icon: RemixIcons.history_line,
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
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _BalanceStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CommissionStatsGrid extends StatelessWidget {
  final double lifetimeCommission;
  final double pendingCommission;
  final double paidCommission;

  const _CommissionStatsGrid({
    required this.lifetimeCommission,
    required this.pendingCommission,
    required this.paidCommission,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Lifetime',
            value: '₹${NumberFormat('#,##,###').format(lifetimeCommission)}',
            icon: RemixIcons.trophy_line,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Pending',
            value: '₹${NumberFormat('#,##,###').format(pendingCommission)}',
            icon: RemixIcons.time_line,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Paid',
            value: '₹${NumberFormat('#,##,###').format(paidCommission)}',
            icon: RemixIcons.check_double_line,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyCommissionSummary extends StatelessWidget {
  final MonthlyCommissionSummary summary;

  const _MonthlyCommissionSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(RemixIcons.calendar_check_line, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'MONTHLY SUMMARY',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Total Bills',
                  value: summary.totalBills.toStringAsFixed(0),
                  icon: RemixIcons.file_list_3_line,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _SummaryItem(
                  label: 'Sales Amount',
                  value: '₹${NumberFormat('#,##,###').format(summary.totalSalesAmount)}',
                  icon: RemixIcons.money_dollar_circle_line,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Commission Earned',
                  value: '₹${NumberFormat('#,##,###').format(summary.totalCommissionEarned)}',
                  icon: RemixIcons.percent_line,
                  color: AppColors.success,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _SummaryItem(
                  label: 'Paid',
                  value: '₹${NumberFormat('#,##,###').format(summary.paidCommission)}',
                  icon: RemixIcons.check_line,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppColors.textHint, size: 16),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CommissionStatisticsCard extends StatelessWidget {
  final CommissionStatistics statistics;

  const _CommissionStatisticsCard({required this.statistics});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(RemixIcons.bar_chart_line, color: AppColors.info, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'COMMISSION STATISTICS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatRow(
                  label: 'Total Bills',
                  value: statistics.totalBillsGenerated.toString(),
                ),
              ),
              Expanded(
                child: _StatRow(
                  label: 'Total Customers',
                  value: statistics.totalCustomers.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _StatRow(
            label: 'Average Commission/Bill',
            value: '₹${NumberFormat('#,##,###.00').format(statistics.averageCommissionPerBill)}',
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CommissionTransactionCard extends StatelessWidget {
  final CommissionTransaction transaction;

  const _CommissionTransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final formattedAmount = NumberFormat('#,##,###.00').format(transaction.commissionEarned);
    final formattedBillAmount = NumberFormat('#,##,###.00').format(transaction.billAmount);
    final isPaid = transaction.status == 'Paid';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isPaid ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPaid ? RemixIcons.check_line : RemixIcons.time_line,
                  color: isPaid ? AppColors.success : AppColors.warning,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.invoiceNumber,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      transaction.customerName,
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹$formattedAmount',
                    style: TextStyle(
                      color: isPaid ? AppColors.success : AppColors.warning,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _CommissionStatusBadge(status: transaction.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TransactionDetail(
                label: 'Bill Amount',
                value: '₹$formattedBillAmount',
              ),
              _TransactionDetail(
                label: 'Commission',
                value: '${transaction.commissionPercentage.toStringAsFixed(1)}%',
              ),
              _TransactionDetail(
                label: 'Date',
                value: DateFormat('dd MMM yyyy').format(transaction.generatedDate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionDetail extends StatelessWidget {
  final String label;
  final String value;

  const _TransactionDetail({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CommissionStatusBadge extends StatelessWidget {
  final String status;

  const _CommissionStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;

    switch (status.toLowerCase()) {
      case 'paid':
        bg = AppColors.successSurface;
        text = AppColors.success;
        break;
      case 'pending':
      default:
        bg = AppColors.warningSurface;
        text = AppColors.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;

  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardBorder,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
