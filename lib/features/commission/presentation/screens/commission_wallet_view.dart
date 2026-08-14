import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/services/commission_service.dart';
import 'package:quickboom_hrm/features/commission/data/commission_models.dart';
import 'package:quickboom_hrm/features/commission/presentation/screens/commission_history_view.dart';
import 'package:quickboom_hrm/features/commission/presentation/screens/commission_details_view.dart';
import 'package:quickboom_hrm/screens/commission/commission_detail_screen.dart';
import 'package:quickboom_hrm/core/services/websocket_service.dart';
import 'package:quickboom_hrm/features/commission/presentation/widgets/webhook_logs_widget.dart';
import 'package:quickboom_hrm/core/utils/ist_date_utils.dart';

class CommissionWalletView extends ConsumerStatefulWidget {
  final bool embedMode;
  const CommissionWalletView({super.key, this.embedMode = false});

  @override
  ConsumerState<CommissionWalletView> createState() => _CommissionWalletViewState();
}

class _CommissionWalletViewState extends ConsumerState<CommissionWalletView> with WidgetsBindingObserver {
  CommissionWallet? _walletData;
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  Timer? _timer;
  DateTime? _lastUpdated;
  StreamSubscription? _commissionSub;
  int _currentCardPage = 0;
  String _selectedPeriodFilter = 'All';
  final PageController _cardPageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCommissionWallet();
    // Auto-refresh wallet every 60 seconds
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _silentRefresh());
    // Listen for WebSocket events to update wallet immediately
    _commissionSub = WebSocketService().commissionUpdates.listen((_) {
      debugPrint('⚡ WebSocket: Commission update received. Reloading wallet state...');
      _silentRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('⚡ App resumed: Refreshing CommissionWalletView...');
      _silentRefresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _commissionSub?.cancel();
    _cardPageController.dispose();
    super.dispose();
  }

  /// Silent background refresh — updates data without full skeleton reload.
  Future<void> _silentRefresh() async {
    if (!mounted) return;
    final data = await CommissionService.fetchCommissionWallet();
    if (mounted && data != null) {
      setState(() {
        _walletData = data;
        _isError = false;
        _lastUpdated = DateTime.now();
      });
    }
  }

  Future<void> _loadCommissionWallet() async {
    if (_walletData == null) {
      setState(() {
        _isLoading = true;
        _isError = false;
      });
    }

    final data = await CommissionService.fetchCommissionWallet();

    if (mounted) {
      setState(() {
        if (data != null) {
          _walletData = data;
          _isError = false;
          _lastUpdated = DateTime.now();
        } else if (_walletData == null) {
          _isError = true;
          _errorMessage = 'Failed to load commission data';
        }
        _isLoading = false;
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
      appBar: widget.embedMode
          ? null
          : AppBar(
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
          // Auto-refresh status chip
          if (_lastUpdated != null)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Live',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: Icon(RemixIcons.history_line, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CommissionHistoryView()),
              );
            },
          ),
          IconButton(
            icon: Icon(RemixIcons.bar_chart_box_line, color: AppColors.textPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CommissionDetailsView()),
              );
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

    // Filter transactions based on selected period chip in IST
    final txns = _walletData!.recentTransactions;

    final filteredTxns = txns.where((tx) {
      if (_selectedPeriodFilter == 'Today') {
        return IstDateUtils.isToday(tx.generatedDate);
      } else if (_selectedPeriodFilter == 'This Week') {
        return IstDateUtils.isLast7Days(tx.generatedDate);
      } else if (_selectedPeriodFilter == 'This Month') {
        return IstDateUtils.isCurrentMonth(tx.generatedDate);
      }
      return true;
    }).toList();

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
                const SizedBox(height: 16),

                // ─── Sliding Performance Carousel ───
                _buildPerformanceCarousel()
                    .animate().fadeIn(duration: 400.ms).scaleXY(begin: 0.98, end: 1.0),

                // ─── Real-Time Webhook Activity Stream ───
                const WebhookLogsWidget(itemsToShow: 5),

                const SizedBox(height: 20),

                // ─── Choice Chips for Period Filters ───
                _buildPeriodFilterChips(),

                // ─── Recent Transactions Header ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'INVOICE COMMISSION HISTORY',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CommissionHistoryView()),
                        );
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
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 12),
              ]),
            ),
          ),

          // ─── Recent Transactions List ───
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            sliver: filteredTxns.isEmpty
                ? SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder, width: 1),
                      ),
                      child: Column(
                        children: [
                          Icon(RemixIcons.receipt_line, color: AppColors.textSecondary, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'No sales recorded in this period',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Submit sales to start tracking commission',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tx = filteredTxns[index];
                        return _CommissionTransactionCard(
                          transaction: tx,
                        ).animate(delay: (100 + index * 50).ms).fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
                      },
                      childCount: filteredTxns.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView(
            controller: _cardPageController,
            onPageChanged: (index) {
              setState(() {
                _currentCardPage = index;
              });
            },
            children: [
              _buildPerformanceCard(
                title: "TODAY'S PERFORMANCE",
                sales: _walletData!.todaySales,
                commission: _walletData!.todayCommission,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3BA38B), Color(0xFF2D8A74)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: RemixIcons.calendar_event_line,
              ),
              _buildPerformanceCard(
                title: "THIS WEEK'S PERFORMANCE",
                sales: _walletData!.thisWeekSales,
                commission: _walletData!.thisWeekCommission,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: RemixIcons.bar_chart_line,
              ),
              _buildPerformanceCard(
                title: "THIS MONTH'S PERFORMANCE",
                sales: _walletData!.thisMonthSales,
                commission: _walletData!.thisMonthCommission,
                gradient: const LinearGradient(
                  colors: [Color(0xFF065F46), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: RemixIcons.bar_chart_2_line,
              ),
              _buildSingleAmountCard(
                title: "PENDING COMMISSION",
                amount: _walletData!.pendingCommission,
                label: "Awaiting approval or payout settlement",
                gradient: const LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFB45309)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: RemixIcons.time_line,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentCardPage == index ? 18 : 6,
              decoration: BoxDecoration(
                color: _currentCardPage == index ? AppColors.primary : AppColors.textHint.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard({
    required String title,
    required double sales,
    required double commission,
    required Gradient gradient,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              Icon(icon, color: Colors.white70, size: 18),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Net Sales',
                      style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${NumberFormat('#,##,##0.00').format(sales)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Commission',
                      style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${NumberFormat('#,##,##0.00').format(commission)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleAmountCard({
    required String title,
    required double amount,
    required String label,
    required Gradient gradient,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              Icon(icon, color: Colors.white70, size: 18),
            ],
          ),
          const Spacer(),
          Text(
            '₹${NumberFormat('#,##,##0.00').format(amount)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilterChips() {
    final periods = ['All', 'Today', 'This Week', 'This Month'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          margin: const EdgeInsets.only(top: 8, bottom: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: periods.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final p = periods[index];
              final isSelected = _selectedPeriodFilter == p;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(p),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPeriodFilter = p;
                      });
                      if (_cardPageController.hasClients) {
                        if (p == 'Today') {
                          _cardPageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        } else if (p == 'This Week') {
                          _cardPageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        } else if (p == 'This Month') {
                          _cardPageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      }
                    }
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                  elevation: isSelected ? 2 : 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : AppColors.cardBorder,
                      width: 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _buildPeriodSummaryCard(),
      ],
    );
  }

  Widget _buildPeriodSummaryCard() {
    String label = 'All Transactions';
    double sales = 0.0;
    double commission = 0.0;

    if (_selectedPeriodFilter == 'Today') {
      label = "Today's Performance";
      sales = _walletData?.todaySales ?? 0.0;
      commission = _walletData?.todayCommission ?? 0.0;
    } else if (_selectedPeriodFilter == 'This Week') {
      label = "This Week's Performance";
      sales = _walletData?.thisWeekSales ?? 0.0;
      commission = _walletData?.thisWeekCommission ?? 0.0;
    } else if (_selectedPeriodFilter == 'This Month') {
      label = "This Month's Performance";
      sales = _walletData?.thisMonthSales ?? 0.0;
      commission = _walletData?.thisMonthCommission ?? 0.0;
    } else {
      sales = _walletData?.recentTransactions.fold(0.0, (sum, tx) => sum! + tx.billAmount) ?? 0.0;
      commission = _walletData?.recentTransactions.fold(0.0, (sum, tx) => sum! + tx.commissionEarned) ?? 0.0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Net Sales: ',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    '₹${NumberFormat('#,##,###.00').format(sales)}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'COMMISSION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${NumberFormat('#,##,###.00').format(commission)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.success),
              ),
            ],
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
  final double netSalary;
  final double totalBalance;
  final double currentMonth;
  final double lastMonth;

  const _CommissionBalanceCard({
    required this.netSalary,
    required this.totalBalance,
    required this.currentMonth,
    required this.lastMonth,
  });

  @override
  Widget build(BuildContext context) {
    final totalEarnings = netSalary + totalBalance;
    final formattedTotal = NumberFormat('#,##,###.00').format(totalEarnings);
    final formattedSalary = NumberFormat('#,##,###.00').format(netSalary);
    final formattedCommission = NumberFormat('#,##,###.00').format(totalBalance);
    final formattedCurrent = NumberFormat('#,##,###.00').format(currentMonth);
    final formattedLast = NumberFormat('#,##,###.00').format(lastMonth);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E5B4F), Color(0xFF0F3830)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3830).withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(RemixIcons.wallet_3_line, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'TOTAL PAYOUT',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '₹$formattedTotal',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),

              // ─── Formula Banner: Net Salary + Commission = Total ───
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    // 1. Net Salary
                    Expanded(
                      flex: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Net Salary',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '₹$formattedSalary',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // + Badge
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                    ),

                    // 2. Commission
                    Expanded(
                      flex: 10,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Commission',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '₹$formattedCommission',
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // = Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '=',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    // 3. Total
                    Expanded(
                      flex: 10,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '₹$formattedTotal',
                                style: const TextStyle(
                                  color: Color(0xFFFDE047),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _BalanceStat(
                      label: 'This Month Comm.',
                      value: '₹$formattedCurrent',
                      icon: RemixIcons.calendar_line,
                    ),
                  ),
                  Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.2)),
                  Expanded(
                    child: _BalanceStat(
                      label: 'Last Month Comm.',
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommissionDetailScreen(billId: transaction.invoiceNumber),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
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
          ),
        ),
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
      case 'reversed':
        bg = const Color(0xFFFFF1F2);
        text = const Color(0xFFE11D48);
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
