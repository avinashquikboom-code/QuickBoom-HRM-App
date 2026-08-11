import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickboom_hrm/features/commission/data/models/commission_models.dart';
import 'package:quickboom_hrm/core/services/mobile_commission_service.dart';
import 'package:quickboom_hrm/screens/commission/commission_detail_screen.dart';

// ─── Period Config ─────────────────────────────────────────────────────────
class _PeriodOption {
  final String id;
  final String label;
  final IconData icon;
  final String billPeriod;
  const _PeriodOption(this.id, this.label, this.icon, this.billPeriod);
}

const List<_PeriodOption> _periods = [
  _PeriodOption('today', 'Today', Icons.today_rounded, 'today'),
  _PeriodOption('thisWeek', 'This Week', Icons.date_range_rounded, 'this_week'),
  _PeriodOption('thisMonth', 'This Month', Icons.calendar_month_rounded, 'current_month'),
  _PeriodOption('lastMonth', 'Last Month', Icons.history_rounded, 'previous_month'),
  _PeriodOption('lifetime', 'All Time', Icons.all_inclusive_rounded, 'all_time'),
];

class CommissionScreen extends StatefulWidget {
  const CommissionScreen({super.key});

  @override
  State<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends State<CommissionScreen> {
  late Future<CommissionSummary> _futureSummary;
  late Future<CommissionResponse> _futureBills;

  String _selectedPeriodId = 'today';
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

  _PeriodOption get _selectedPeriod =>
      _periods.firstWhere((p) => p.id == _selectedPeriodId);

  void _refresh() {
    setState(() {
      _futureSummary = MobileCommissionService.fetchSummary();
      _futureBills = MobileCommissionService.fetchBills(
        period: _selectedPeriod.billPeriod,
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
        period: _selectedPeriod.billPeriod,
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

  void _selectPeriod(String id) {
    setState(() => _selectedPeriodId = id);
    _refresh();
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
              'My Commission',
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
                // ── Header Filter Chips ──────────────────────────────
                SliverToBoxAdapter(
                  child: _PeriodChips(
                    periods: _periods,
                    selectedId: _selectedPeriodId,
                    onSelect: _selectPeriod,
                  ),
                ),

                // ── Executive Hero Card ─────────────────────────────
                SliverToBoxAdapter(
                  child: _HeroSummaryCard(
                    summary: summary,
                    periodId: _selectedPeriodId,
                    loading: summSnap.connectionState == ConnectionState.waiting,
                  ),
                ),

                // ── Search & Filter Section Header ──────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transactions Breakdown',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          _selectedPeriod.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade600,
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
                        return _EmptyState(label: _selectedPeriod.label);
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

// ─── Period Chips ────────────────────────────────────────────────────────────
class _PeriodChips extends StatelessWidget {
  final List<_PeriodOption> periods;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _PeriodChips({
    required this.periods,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: periods.map((p) {
            final selected = p.id == selectedId;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => onSelect(p.id),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF38BDF8)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF38BDF8)
                          : Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        p.icon,
                        size: 14,
                        color: selected ? const Color(0xFF0F172A) : Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        p.label,
                        style: TextStyle(
                          color: selected ? const Color(0xFF0F172A) : Colors.white70,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Hero Summary Card ────────────────────────────────────────────────────────
class _HeroSummaryCard extends StatelessWidget {
  final CommissionSummary? summary;
  final String periodId;
  final bool loading;

  const _HeroSummaryCard({
    required this.summary,
    required this.periodId,
    required this.loading,
  });

  Map<String, dynamic> _getPeriodData() {
    if (summary == null) return {};
    switch (periodId) {
      case 'today':
        return {
          'sales': summary!.today.totalSales,
          'commission': summary!.today.totalCommission,
          'bills': summary!.today.billCount,
          'label': "Today's Commission",
          'pending': 0.0,
          'paid': 0.0,
        };
      case 'thisWeek':
        return {
          'sales': summary!.thisWeek.totalSales,
          'commission': summary!.thisWeek.totalCommission,
          'bills': summary!.thisWeek.billCount,
          'label': "This Week's Commission",
          'pending': 0.0,
          'paid': 0.0,
        };
      case 'thisMonth':
        return {
          'sales': summary!.thisMonth.totalSales,
          'commission': summary!.thisMonth.totalCommission,
          'bills': summary!.thisMonth.billCount,
          'label': summary!.thisMonth.label.isNotEmpty ? "${summary!.thisMonth.label} Commission" : "This Month's Commission",
          'pending': summary!.thisMonth.pendingCommission,
          'paid': summary!.thisMonth.paidCommission,
        };
      case 'lastMonth':
        return {
          'sales': summary!.lastMonth.totalSales,
          'commission': summary!.lastMonth.totalCommission,
          'bills': summary!.lastMonth.billCount,
          'label': summary!.lastMonth.label.isNotEmpty ? "${summary!.lastMonth.label} Commission" : "Last Month's Commission",
          'pending': summary!.lastMonth.pendingCommission,
          'paid': summary!.lastMonth.paidCommission,
        };
      case 'lifetime':
        return {
          'sales': summary!.lifetime.totalSales,
          'commission': summary!.lifetime.totalCommission,
          'bills': summary!.lifetime.billCount,
          'label': "All-Time Commission",
          'pending': summary!.pendingCommission,
          'paid': summary!.paidCommission,
        };
      default:
        return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _getPeriodData();
    final commission = (data['commission'] ?? 0.0) as double;
    final sales = (data['sales'] ?? 0.0) as double;
    final bills = (data['bills'] ?? 0) as int;
    final label = (data['label'] ?? '') as String;
    final pending = (data['pending'] ?? 0.0) as double;
    final paid = (data['paid'] ?? 0.0) as double;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: loading
            ? const SizedBox(
                height: 140,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label & Bill Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_rounded, size: 12, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 4),
                            Text(
                              '$bills ${bills == 1 ? 'Bill' : 'Bills'}',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Main Commission Amount
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        '₹',
                        style: TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        commission.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Net Commission Earned',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                  ),

                  const SizedBox(height: 18),
                  Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                  const SizedBox(height: 16),

                  // Breakdown Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: _MetricItem(
                          icon: Icons.shopping_bag_outlined,
                          label: 'Net Sales',
                          value: '₹${_compact(sales)}',
                          color: const Color(0xFF38BDF8),
                        ),
                      ),
                      if (pending > 0 || paid > 0) ...[
                        Expanded(
                          child: _MetricItem(
                            icon: Icons.pending_actions_rounded,
                            label: 'Pending',
                            value: '₹${pending.toStringAsFixed(0)}',
                            color: const Color(0xFFFBBF24),
                          ),
                        ),
                        Expanded(
                          child: _MetricItem(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Paid Out',
                            value: '₹${paid.toStringAsFixed(0)}',
                            color: const Color(0xFF34D399),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: _MetricItem(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Rate',
                            value: 'Auto (1%)',
                            color: const Color(0xFFA78BFA),
                          ),
                        ),
                        Expanded(
                          child: _MetricItem(
                            icon: Icons.verified_rounded,
                            label: 'Status',
                            value: 'Verified',
                            color: const Color(0xFF34D399),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  String _compact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
  final String label;
  const _EmptyState({required this.label});

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
          Text(
            'No sales recorded for $label',
            style: const TextStyle(
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
