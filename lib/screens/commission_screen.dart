import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickboom_hrm/features/commission/data/models/commission_models.dart';
import 'package:quickboom_hrm/core/services/mobile_commission_service.dart';
import 'package:quickboom_hrm/screens/commission/commission_detail_screen.dart';

// ─── Period Config ─────────────────────────────────────────────────────────
class _PeriodOption {
  final String id;
  final String label;
  final String billPeriod; // sent to /bills API
  const _PeriodOption(this.id, this.label, this.billPeriod);
}

const List<_PeriodOption> _periods = [
  _PeriodOption('today',         'Today',       'today'),
  _PeriodOption('thisWeek',      'This Week',   'this_week'),
  _PeriodOption('thisMonth',     'This Month',  'current_month'),
  _PeriodOption('lastMonth',     'Last Month',  'previous_month'),
  _PeriodOption('lifetime',      'All Time',    'all_time'),
];

// ─── Screen ─────────────────────────────────────────────────────────────────
class CommissionScreen extends StatefulWidget {
  const CommissionScreen({super.key});

  @override
  State<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends State<CommissionScreen> {
  late Future<CommissionSummary> _futureSummary;
  late Future<CommissionResponse> _futureBills;

  String _selectedPeriodId = 'today'; // default = Today
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
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('My Commission',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<CommissionSummary>(
          future: _futureSummary,
          builder: (context, summSnap) {
            final summary = summSnap.data;
            return CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                // ── Period Filter Chips ──────────────────────────────
                SliverToBoxAdapter(child: _PeriodChips(
                  periods: _periods,
                  selectedId: _selectedPeriodId,
                  onSelect: _selectPeriod,
                )),

                // ── Summary Card ─────────────────────────────────────
                SliverToBoxAdapter(child: _SummaryCard(
                  summary: summary,
                  periodId: _selectedPeriodId,
                  loading: summSnap.connectionState == ConnectionState.waiting,
                )),

                // ── Search Box ───────────────────────────────────────
                SliverToBoxAdapter(child: _SearchBox(
                  controller: _searchCtrl,
                  onSearch: _onSearch,
                )),

                // ── Bills List ───────────────────────────────────────
                SliverToBoxAdapter(child: FutureBuilder<CommissionResponse>(
                  future: _futureBills,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        _allBills.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snap.hasError && _allBills.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text('${snap.error}',
                                textAlign: TextAlign.center,
                                style:
                                    const TextStyle(color: Colors.red)),
                          ]),
                        ),
                      );
                    }
                    if (snap.hasData && _allBills.isEmpty) {
                      _allBills = List.from(snap.data!.bills);
                    }
                    if (_allBills.isEmpty) {
                      return _EmptyState(label: _selectedPeriod.label);
                    }
                    return _BillsTable(
                      bills: _allBills,
                      hasMore: snap.data?.pagination.hasMore ?? false,
                      isLoadingMore: _isLoadingMore,
                      onTap: (bill) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CommissionDetailScreen(billId: bill.billId),
                        ),
                      ),
                    );
                  },
                )),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
  const _PeriodChips(
      {required this.periods,
      required this.selectedId,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: periods.map((p) {
            final selected = p.id == selectedId;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(p.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF3B82F6)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF3B82F6)
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    p.label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
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

// ─── Summary Card ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final CommissionSummary? summary;
  final String periodId;
  final bool loading;

  const _SummaryCard(
      {required this.summary,
      required this.periodId,
      required this.loading});

  Map<String, dynamic> _getPeriodData() {
    if (summary == null) return {};
    switch (periodId) {
      case 'today':
        return {
          'sales': summary!.today.totalSales,
          'commission': summary!.today.totalCommission,
          'bills': summary!.today.billCount,
          'label': summary!.today.label,
          'pending': 0.0,
          'paid': 0.0,
        };
      case 'thisWeek':
        return {
          'sales': summary!.thisWeek.totalSales,
          'commission': summary!.thisWeek.totalCommission,
          'bills': summary!.thisWeek.billCount,
          'label': summary!.thisWeek.label,
          'pending': 0.0,
          'paid': 0.0,
        };
      case 'thisMonth':
        return {
          'sales': summary!.thisMonth.totalSales,
          'commission': summary!.thisMonth.totalCommission,
          'bills': summary!.thisMonth.billCount,
          'label': summary!.thisMonth.label,
          'pending': summary!.thisMonth.pendingCommission,
          'paid': summary!.thisMonth.paidCommission,
        };
      case 'lastMonth':
        return {
          'sales': summary!.lastMonth.totalSales,
          'commission': summary!.lastMonth.totalCommission,
          'bills': summary!.lastMonth.billCount,
          'label': summary!.lastMonth.label,
          'pending': summary!.lastMonth.pendingCommission,
          'paid': summary!.lastMonth.paidCommission,
        };
      case 'lifetime':
        return {
          'sales': summary!.lifetime.totalSales,
          'commission': summary!.lifetime.totalCommission,
          'bills': summary!.lifetime.billCount,
          'label': summary!.lifetime.label,
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
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period label + bills count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$bills bill${bills == 1 ? '' : 's'}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Commission (big)
                  Text(
                    '₹${commission.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'Commission Earned',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12),
                  ),

                  const SizedBox(height: 16),
                  Divider(
                      color: Colors.white.withValues(alpha: 0.15),
                      height: 1),
                  const SizedBox(height: 16),

                  // Sales | Pending | Paid row
                  Row(
                    children: [
                      Expanded(
                          child: _MiniStat(
                              label: 'Sales',
                              value:
                                  '₹${_compact(sales)}',
                              color: const Color(0xFF60A5FA))),
                      if (pending > 0 || paid > 0) ...[
                        Expanded(
                            child: _MiniStat(
                                label: 'Pending',
                                value: '₹${pending.toStringAsFixed(0)}',
                                color: const Color(0xFFFBBF24))),
                        Expanded(
                            child: _MiniStat(
                                label: 'Paid',
                                value: '₹${paid.toStringAsFixed(0)}',
                                color: const Color(0xFF34D399))),
                      ] else
                        Expanded(
                            child: _MiniStat(
                                label: 'Rate',
                                value: 'Auto',
                                color: const Color(0xFF34D399))),
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

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
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
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search by Invoice / Bill ID…',
          hintStyle:
              TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onSearch();
                  },
                  child: const Icon(Icons.clear, size: 18))
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.grey.shade200)),
        ),
        onSubmitted: (_) => onSearch(),
        onChanged: (_) {},
      ),
    );
  }
}

// ─── Bills Table ──────────────────────────────────────────────────────────────
class _BillsTable extends StatelessWidget {
  final List<CommissionBill> bills;
  final bool hasMore;
  final bool isLoadingMore;
  final Function(CommissionBill) onTap;
  const _BillsTable(
      {required this.bills,
      required this.hasMore,
      required this.isLoadingMore,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              const Expanded(
                  flex: 3,
                  child: Text('Invoice',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.black54))),
              const Expanded(
                  flex: 2,
                  child: Text('Date',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.black54))),
              const Expanded(
                  flex: 2,
                  child: Text('Amount',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.black54))),
              Expanded(
                  flex: 2,
                  child: Text('Commssn',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey.shade600))),
            ]),
          ),
          Divider(height: 1, color: Colors.grey.shade200),

          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bills.length + (hasMore || isLoadingMore ? 1 : 0),
            separatorBuilder: (_, _) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (ctx, i) {
              if (i == bills.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: isLoadingMore
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox.shrink(),
                );
              }
              final bill = bills[i];
              return InkWell(
                onTap: () => onTap(bill),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bill.billId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                            const SizedBox(height: 2),
                            _StatusBadge(bill.status),
                          ]),
                    ),
                    Expanded(
                        flex: 2,
                        child: Text(
                            DateFormat('dd MMM').format(bill.date),
                            style: const TextStyle(fontSize: 12))),
                    Expanded(
                        flex: 2,
                        child: Text(
                            '₹${bill.saleAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                    Expanded(
                        flex: 2,
                        child: Text(
                            '₹${bill.commission.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A)))),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final s = status.toUpperCase();
    Color bg;
    Color fg;
    String label;
    if (s == 'PAID') {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF16A34A);
      label = 'Paid';
    } else if (s == 'APPROVED') {
      bg = const Color(0xFFDBEAFE);
      fg = const Color(0xFF2563EB);
      label = 'Approved';
    } else {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
      label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child:
          Text(label, style: TextStyle(fontSize: 9, color: fg, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No bills for $label',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 6),
          Text(
            'Your sales will appear here once processed.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
