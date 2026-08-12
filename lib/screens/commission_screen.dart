import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickboom_hrm/features/commission/data/models/commission_models.dart';
import 'package:quickboom_hrm/core/services/mobile_commission_service.dart';
import 'package:quickboom_hrm/screens/commission/commission_detail_screen.dart';
import 'package:quickboom_hrm/features/commission/presentation/widgets/webhook_logs_widget.dart';

class CommissionScreen extends StatefulWidget {
  const CommissionScreen({super.key});

  @override
  State<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends State<CommissionScreen> {
  late Future<CommissionSummary> _futureSummary;
  late Future<CommissionResponse> _futureBills;

  String _searchBillId = '';
  List<CommissionBill> _allBills = [];
  bool _isLoadingMore = false;

  int _currentPage = 0;

  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _refresh();
    _scrollCtrl.addListener(_onScroll);
  }

  void _refresh() {
    setState(() {
      _futureSummary = MobileCommissionService.fetchSummary();
      _futureBills = MobileCommissionService.fetchBills(
        period: 'current_month',
        billId: _searchBillId.isNotEmpty ? _searchBillId : null,
      );
      _currentPage = 0;
      _allBills.clear();
    });
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels == _scrollCtrl.position.maxScrollExtent) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final resp = await MobileCommissionService.fetchBills(
        period: 'current_month',
        billId: _searchBillId.isNotEmpty ? _searchBillId : null,
        offset: (_currentPage + 1) * 20,
      );
      setState(() {
        _allBills.addAll(resp.bills);
        _currentPage++;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onSearch() {
    setState(() => _searchBillId = _searchCtrl.text.trim());
    _refresh();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF38BDF8), size: 24),
            SizedBox(width: 10),
            Text(
              'My Commission & Sales',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.2),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF38BDF8),
        onRefresh: () async => _refresh(),
        child: FutureBuilder<CommissionSummary>(
          future: _futureSummary,
          builder: (context, summSnap) {
            final summary = summSnap.data;
            return CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                // ── Executive Hero Card (Today's Earnings) ───────────
                SliverToBoxAdapter(
                  child: _HeroSummaryCard(
                    summary: summary,
                    loading: summSnap.connectionState == ConnectionState.waiting,
                  ),
                ),

                // ── Real-time Webhook Activity Logs ──────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: WebhookLogsWidget(itemsToShow: 10),
                  ),
                ),

                // ── Search & Filter Section Header ──────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's Transactions",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          'Live Sales',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Search Box ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SearchBox(
                    controller: _searchCtrl,
                    onSearch: _onSearch,
                  ),
                ),

                // ── Bills List Cards ─────────────────────────────────
                SliverToBoxAdapter(
                  child: FutureBuilder<CommissionResponse>(
                    future: _futureBills,
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting && _allBills.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFF0F172A)),
                          ),
                        );
                      }

                      if (snap.hasError && _allBills.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                                const SizedBox(height: 12),
                                Text(
                                  '${snap.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (snap.hasData && _allBills.isEmpty) {
                        _allBills = List.from(snap.data!.bills);
                      }

                      if (_allBills.isEmpty) {
                        return const _EmptyState();
                      }

                      return _BillsListSection(
                        bills: _allBills,
                        hasMore: snap.data?.pagination.hasMore ?? false,
                        isLoadingMore: _isLoadingMore,
                        onTap: (bill) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommissionDetailScreen(billId: bill.billId),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Hero Summary Card ────────────────────────────────────────────────────────
class _HeroSummaryCard extends StatelessWidget {
  final CommissionSummary? summary;
  final bool loading;

  const _HeroSummaryCard({
    required this.summary,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F172A)),
        ),
      );
    }

    final today = summary?.today;
    final thisMonth = summary?.thisMonth;
    final latest = summary?.latestSale;

    final todaySales = today?.totalSales ?? 0.0;
    final todayComm = today?.totalCommission ?? 0.0;
    final todayBills = today?.billCount ?? 0;

    final monthSales = thisMonth?.totalSales ?? 0.0;
    final monthComm = thisMonth?.totalCommission ?? 0.0;
    final monthBills = thisMonth?.billCount ?? 0;

    // Calculate progress percentage
    double progressPercent = 0.0;
    if (monthSales > 0) {
      progressPercent = (todaySales / monthSales) * 100;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═════════════════════════════════════════════════════════
          // TODAY'S PERFORMANCE CARD
          // ═════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Performance",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$todayBills ${todayBills == 1 ? 'bill' : 'bills'} today',
                        style: const TextStyle(
                          color: Color(0xFF0369A1),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (today != null && today.date.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    today.date,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _PerformanceMetric(
                        label: 'Net Sales Today',
                        value: '₹${NumberFormat('#,##,###').format(todaySales)}',
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _PerformanceMetric(
                        label: 'Commission Today',
                        value: '₹${NumberFormat('#,##,###.00').format(todayComm)}',
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ═════════════════════════════════════════════════════════
          // THIS MONTH'S PERFORMANCE CARD
          // ═════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "This Month's Performance",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$monthBills ${monthBills == 1 ? 'bill' : 'bills'} total',
                        style: const TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (thisMonth != null && thisMonth.month.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    thisMonth.month,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _PerformanceMetric(
                        label: 'Total Net Sales',
                        value: '₹${NumberFormat('#,##,###').format(monthSales)}',
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _PerformanceMetric(
                        label: 'Total Commission',
                        value: '₹${NumberFormat('#,##,###.00').format(monthComm)}',
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ═════════════════════════════════════════════════════════
          // MONTHLY PROGRESS BAR
          // ═════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Monthly Progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF78350F),
                      ),
                    ),
                    Text(
                      '${progressPercent.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (progressPercent / 100).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: const Color(0xFFFEF3C7),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Today is ${progressPercent.toStringAsFixed(1)}% of your monthly total sales target.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ═════════════════════════════════════════════════════════
          // LATEST TRANSACTION SECTION
          // ═════════════════════════════════════════════════════════
          if (latest != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Latest Transaction',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bill ID: ${latest.billId}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${latest.displayDate} at ${latest.displayTime}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${NumberFormat('#,##,###').format(latest.netAmount)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Commission: ₹${NumberFormat('#,##,###.00').format(latest.commission)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PerformanceMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}



// ─── Search Box ───────────────────────────────────────────────────────────────
class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;

  const _SearchBox({required this.controller, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Search by Invoice No. (e.g. LL-I-35709)…',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel_rounded, size: 18, color: Colors.grey),
                    onPressed: () {
                      controller.clear();
                      onSearch();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
            ),
          ),
          onSubmitted: (_) => onSearch(),
        ),
      ),
    );
  }
}

// ─── Bills Card List ──────────────────────────────────────────────────────────
class _BillsListSection extends StatelessWidget {
  final List<CommissionBill> bills;
  final bool hasMore;
  final bool isLoadingMore;
  final Function(CommissionBill) onTap;

  const _BillsListSection({
    required this.bills,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bills.length + (hasMore || isLoadingMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == bills.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: isLoadingMore
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
                      : const SizedBox.shrink(),
                );
              }
              final bill = bills[i];
              return _BillCardItem(bill: bill, onTap: () => onTap(bill));
            },
          ),
        ],
      ),
    );
  }
}

class _BillCardItem extends StatelessWidget {
  final CommissionBill bill;
  final VoidCallback onTap;

  const _BillCardItem({required this.bill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Left Icon Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF0F172A),
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              // Middle: Bill ID + Date + Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.billId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(bill.date),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(bill.status),
                      ],
                    ),
                  ],
                ),
              ),

              // Right: Sale Amount & Commission
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${bill.commission.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sale: ₹${bill.saleAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    Color bg;
    Color fg;
    String label;

    if (s == 'PAID') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
      label = 'Paid';
    } else if (s == 'APPROVED') {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0369A1);
      label = 'Approved';
    } else {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
      label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.point_of_sale_rounded, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          const Text(
            'No sales recorded today yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your HopKid POS bills and earned commissions will appear here automatically.',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
