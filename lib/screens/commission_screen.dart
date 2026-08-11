import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickboom_hrm/features/commission/data/models/commission_models.dart';
import 'package:quickboom_hrm/core/services/mobile_commission_service.dart';
import 'package:quickboom_hrm/screens/commission/commission_detail_screen.dart';

class CommissionScreen extends StatefulWidget {
  const CommissionScreen({super.key});

  @override
  State<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends State<CommissionScreen> {
  late Future<CommissionSummary> futureSummary;
  late Future<CommissionResponse> futureBills;

  String selectedPeriod = 'current_month';
  String searchBillId = '';
  int currentPage = 0;
  bool isLoadingMore = false;
  List<CommissionBill> allBills = [];

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshData();
    _scrollController.addListener(_onScroll);
  }

  void _refreshData() {
    setState(() {
      futureSummary = MobileCommissionService.fetchSummary();
      futureBills = MobileCommissionService.fetchBills(
        period: selectedPeriod,
        billId: searchBillId.isNotEmpty ? searchBillId : null,
      );
      currentPage = 0;
      allBills.clear();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMore();
    }
  }

  void _loadMore() async {
    if (isLoadingMore) return;

    setState(() => isLoadingMore = true);

    try {
      final response = await MobileCommissionService.fetchBills(
        period: selectedPeriod,
        billId: searchBillId.isNotEmpty ? searchBillId : null,
        offset: (currentPage + 1) * 20,
      );

      setState(() {
        allBills.addAll(response.bills);
        currentPage++;
      });
    } catch (e) {
      debugPrint('Error loading more: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingMore = false);
      }
    }
  }

  void _onPeriodChanged(String? value) {
    if (value != null) {
      setState(() => selectedPeriod = value);
      _refreshData();
    }
  }

  void _onSearch() {
    setState(() => searchBillId = _searchController.text.trim());
    _refreshData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Commission'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            children: [
              // Summary Cards
              FutureBuilder<CommissionSummary>(
                future: futureSummary,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final summary = snapshot.data!;
                    return _SummaryCards(summary: summary);
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 16),

              // Filter and Search Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Period Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPeriod,
                          isExpanded: true,
                          onChanged: _onPeriodChanged,
                          items: const [
                            DropdownMenuItem(
                              value: 'current_month',
                              child: Text('Current Month'),
                            ),
                            DropdownMenuItem(
                              value: 'previous_month',
                              child: Text('Previous Month'),
                            ),
                            DropdownMenuItem(
                              value: 'custom_range',
                              child: Text('Custom Range'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Search Box
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by Invoice Number...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  _onSearch();
                                },
                                child: const Icon(Icons.clear),
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _onSearch(),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bills List
              FutureBuilder<CommissionResponse>(
                future: futureBills,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && allBills.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError && allBills.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }

                  final response = snapshot.data;
                  if (response != null && allBills.isEmpty && response.bills.isNotEmpty) {
                    allBills = List.from(response.bills);
                  }

                  if (allBills.isEmpty) {
                    return _EmptyState();
                  }

                  return _BillsList(
                    bills: allBills,
                    hasMore: response?.pagination.hasMore ?? false,
                    isLoadingMore: isLoadingMore,
                    onBillTap: (bill) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CommissionDetailScreen(billId: bill.billId),
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final CommissionSummary summary;

  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Total Sales & Commission Row
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total Sales',
                  value: '₹${summary.totalSales.toStringAsFixed(0)}',
                  icon: Icons.shopping_cart,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Commission Earned',
                  value: '₹${summary.totalCommissionEarned.toStringAsFixed(2)}',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Pending & Paid Row
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Pending',
                  value: '₹${summary.pendingCommission.toStringAsFixed(2)}',
                  icon: Icons.schedule,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Paid',
                  value: '₹${summary.paidCommission.toStringAsFixed(2)}',
                  icon: Icons.check_circle,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillsList extends StatelessWidget {
  final List<CommissionBill> bills;
  final bool hasMore;
  final bool isLoadingMore;
  final Function(CommissionBill) onBillTap;

  const _BillsList({
    required this.bills,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onBillTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey.shade100,
          child: const Row(
            children: [
              Expanded(child: Text('Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(child: Text('Commission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
        ),
        
        Divider(height: 1, color: Colors.grey.shade300),

        // Bills List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bills.length + (hasMore || isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == bills.length) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: isLoadingMore
                    ? const Center(child: CircularProgressIndicator())
                    : const SizedBox.shrink(),
              );
            }

            final bill = bills[index];
            return GestureDetector(
              onTap: () => onBillTap(bill),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.billId,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          Text(
                            bill.status,
                            style: TextStyle(
                              fontSize: 10,
                              color: bill.status == 'PAID'
                                  ? Colors.teal
                                  : bill.status == 'APPROVED'
                                      ? Colors.green
                                      : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat('dd MMM').format(bill.date),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '₹${bill.saleAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '₹${bill.commission.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No commission earned yet.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your commissions will appear here when you make sales.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
