import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/widgets/shimmer_loading.dart';
import 'package:quickboom_hrm/features/commission/data/commission_models.dart';
import 'package:quickboom_hrm/features/commission/presentation/providers/commission_viewmodel.dart';
import 'package:quickboom_hrm/core/services/invoice_service.dart';

class CommissionHistoryView extends ConsumerStatefulWidget {
  const CommissionHistoryView({super.key});

  @override
  ConsumerState<CommissionHistoryView> createState() => _CommissionHistoryViewState();
}

class _CommissionHistoryViewState extends ConsumerState<CommissionHistoryView> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  String? _selectedStatus;
  String? _searchQuery;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Filter by Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FilterOption(
              label: 'All',
              value: null,
              selected: _selectedStatus == null,
              onTap: () {
                setState(() => _selectedStatus = null);
                Navigator.pop(ctx);
                _loadHistory();
              },
            ),
            _FilterOption(
              label: 'Pending',
              value: 'Pending',
              selected: _selectedStatus == 'Pending',
              onTap: () {
                setState(() => _selectedStatus = 'Pending');
                Navigator.pop(ctx);
                _loadHistory();
              },
            ),
            _FilterOption(
              label: 'Paid',
              value: 'Paid',
              selected: _selectedStatus == 'Paid',
              onTap: () {
                setState(() => _selectedStatus = 'Paid');
                Navigator.pop(ctx);
                _loadHistory();
              },
            ),
          ],
        ),
      ),
    );
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
        actions: [
          IconButton(
            icon: Icon(RemixIcons.filter_3_line, color: AppColors.textPrimary),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.history!.transactions.length + (state.isLoadingHistory ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.history!.transactions.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final transaction = state.history!.transactions[index];
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(RemixIcons.file_download_line, size: 16),
              label: const Text(
                'Download Order Invoice (PDF)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                InvoiceService.downloadAndOpenInvoice(
                  context: context,
                  invoiceNumber: transaction.invoiceNumber.isNotEmpty
                      ? transaction.invoiceNumber
                      : 'INV-${transaction.id}',
                  orderId: 'ORD-${transaction.id}',
                  date: DateFormat('dd MMM yyyy').format(transaction.generatedDate),
                  customerName: transaction.customerName,
                  customerPhone: '',
                  customerAddress: 'HopKid Main Store',
                  totalAmount: transaction.billAmount,
                );
              },
            ),
          ),
        ],
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

class _FilterOption extends StatelessWidget {
  final String label;
  final String? value;
  final bool selected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (selected)
              Icon(RemixIcons.checkbox_circle_fill, color: AppColors.primary, size: 20)
            else
              Icon(RemixIcons.checkbox_blank_circle_line, color: AppColors.textHint, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
