import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/widgets/shimmer_loading.dart';
import 'package:quickboom_hrm/features/commission/data/commission_models.dart';
import 'package:quickboom_hrm/features/commission/presentation/providers/commission_viewmodel.dart';
import 'package:quickboom_hrm/core/utils/ist_date_utils.dart';
import 'package:quickboom_hrm/screens/commission/commission_detail_screen.dart';
import 'package:quickboom_hrm/core/services/websocket_service.dart';

class CommissionHistoryView extends ConsumerStatefulWidget {
  const CommissionHistoryView({super.key});

  @override
  ConsumerState<CommissionHistoryView> createState() => _CommissionHistoryViewState();
}

class _CommissionHistoryViewState extends ConsumerState<CommissionHistoryView> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  String? _selectedStatus;
  String _selectedPeriodFilter = 'All';
  String? _searchQuery;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription? _commissionSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHistory();
    _scrollController.addListener(_onScroll);

    // Auto-refresh history on WebSocket updates
    _commissionSub = WebSocketService().commissionUpdates.listen((_) {
      debugPrint('⚡ WebSocket: Real-time update in CommissionHistoryView');
      if (mounted) _loadHistory();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('⚡ App resumed: Refreshing CommissionHistoryView');
      _loadHistory();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _commissionSub?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final state = ref.read(commissionViewModelProvider);
      if (state.history != null && _currentPage < state.history!.totalPages) {
        _loadMore();
      }
    }
  }

  Future<void> _loadHistory() async {
    _currentPage = 1;
    await ref.read(commissionViewModelProvider.notifier).fetchHistory(
      page: _currentPage,
      status: _selectedStatus,
    );
  }

  Future<void> _loadMore() async {
    _currentPage++;
    await ref.read(commissionViewModelProvider.notifier).fetchHistory(
      page: _currentPage,
      status: _selectedStatus,
    );
  }

  Future<void> _onRefresh() async {
    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commissionViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Commission History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by invoice or customer...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  prefixIcon: Icon(RemixIcons.search_line, color: AppColors.textSecondary),
                  suffixIcon: _searchQuery != null
                      ? IconButton(
                          icon: Icon(RemixIcons.close_line, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = null);
                            _loadHistory();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.isEmpty ? null : value);
                },
                onSubmitted: (_) => _loadHistory(),
              ),
            ),
          ),
          // Period Choice Chips
          Container(
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'Today', 'This Week', 'This Month'].map((p) {
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
                      }
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
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
              }).toList(),
            ),
          ),
          // History List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: _buildHistoryList(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(CommissionState state) {
    if (state.isLoadingHistory && state.history == null) {
      return _buildLoadingState();
    }

    if (state.errorMessage != null && state.history == null) {
      return _buildErrorState(state.errorMessage!);
    }

    if (state.history == null || state.history!.transactions.isEmpty) {
      return _buildEmptyState();
    }

    final allTxns = state.history!.transactions;

    final filteredTxns = allTxns.where((tx) {
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        final q = _searchQuery!.toLowerCase();
        final matchInvoice = tx.invoiceNumber.toLowerCase().contains(q);
        final matchCustomer = tx.customerName.toLowerCase().contains(q);
        if (!matchInvoice && !matchCustomer) return false;
      }

      if (_selectedPeriodFilter == 'Today') {
        return IstDateUtils.isToday(tx.generatedDate);
      } else if (_selectedPeriodFilter == 'This Week') {
        return IstDateUtils.isLast7Days(tx.generatedDate);
      } else if (_selectedPeriodFilter == 'This Month') {
        return IstDateUtils.isCurrentMonth(tx.generatedDate);
      }
      return true;
    }).toList();

    if (filteredTxns.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredTxns.length + (state.isLoadingHistory ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredTxns.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final transaction = filteredTxns[index];
        return _CommissionTransactionTile(transaction: transaction)
            .animate()
            .fadeIn(delay: (index * 50).ms)
            .slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerLoading(
          height: 80,
          width: double.infinity,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(RemixIcons.error_warning_line, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadHistory,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(RemixIcons.file_list_3_line, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'No commission history found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _CommissionTransactionTile extends StatelessWidget {
  final CommissionTransaction transaction;

  const _CommissionTransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPaid = transaction.status.toLowerCase() == 'paid';
    final statusColor = isPaid ? AppColors.success : AppColors.warning;

    final billIdToPass = transaction.invoiceNumber.isNotEmpty
        ? transaction.invoiceNumber
        : 'TXN-${transaction.id}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommissionDetailScreen(billId: billIdToPass),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.invoiceNumber,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            transaction.customerName,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transaction.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(
                        label: 'Bill Amount',
                        value: '₹${transaction.billAmount.toStringAsFixed(2)}',
                        icon: RemixIcons.money_dollar_box_line,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _InfoRow(
                        label: 'Commission',
                        value: '₹${transaction.commissionEarned.toStringAsFixed(2)}',
                        icon: RemixIcons.percent_line,
                        valueColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(
                        label: 'Commission %',
                        value: '${transaction.commissionPercentage.toStringAsFixed(1)}%',
                        icon: RemixIcons.pie_chart_line,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _InfoRow(
                        label: 'Generated',
                        value: DateFormat('dd MMM yyyy').format(transaction.generatedDate),
                        icon: RemixIcons.calendar_line,
                      ),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
