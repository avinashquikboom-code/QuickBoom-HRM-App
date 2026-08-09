import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/services/wallet_service.dart';
import 'package:quickboom_hrm/core/services/notification_service.dart';

class HrSalaryAdvancesView extends StatefulWidget {
  const HrSalaryAdvancesView({super.key});

  @override
  State<HrSalaryAdvancesView> createState() => _HrSalaryAdvancesViewState();
}

class _HrSalaryAdvancesViewState extends State<HrSalaryAdvancesView> {
  List<dynamic> _advances = [];
  bool _isLoading = true;
  String _selectedStatus = 'ALL'; // ALL, PENDING, APPROVED, REJECTED
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchAdvances();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAdvances() async {
    setState(() => _isLoading = true);
    final data = await WalletService.fetchAdminSalaryAdvances(
      status: _selectedStatus,
    );
    if (mounted) {
      setState(() {
        _advances = data ?? [];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredAdvances {
    return _advances.where((adv) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final empName = (adv['employeeName'] ?? '').toString().toLowerCase();
      final empCode = (adv['employeeCode'] ?? '').toString().toLowerCase();
      final dept = (adv['department'] ?? '').toString().toLowerCase();
      final reason = (adv['reason'] ?? '').toString().toLowerCase();
      return empName.contains(query) ||
          empCode.contains(query) ||
          dept.contains(query) ||
          reason.contains(query);
    }).toList();
  }

  int get _pendingCount => _advances
      .where((a) => (a['status'] ?? '').toString().toUpperCase() == 'PENDING')
      .length;

  int get _approvedCount => _advances
      .where((a) => (a['status'] ?? '').toString().toUpperCase() == 'APPROVED')
      .length;

  double get _totalRequestedAmount => _advances.fold<double>(
        0.0,
        (sum, a) => sum + ((a['amount'] as num?)?.toDouble() ?? 0.0),
      );

  void _showApproveDialog(Map<String, dynamic> advance) {
    final int advanceId = (advance['id'] as num).toInt();
    final double amount = (advance['amount'] as num?)?.toDouble() ?? 0.0;
    final int currentMonths = (advance['months'] as num?)?.toInt() ?? 1;
    final String empName = advance['employeeName'] ?? 'Employee';

    final monthsCtrl = TextEditingController(text: currentMonths.toString());
    final noteCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final int monthsVal = int.tryParse(monthsCtrl.text.trim()) ?? 1;
          final double calculatedEmi = monthsVal > 0
              ? (amount / monthsVal)
              : amount;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    RemixIcons.checkbox_circle_line,
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Approve Advance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          empName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Requested: ₹${NumberFormat('#,##,###').format(amount)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'EMI Tenure (Months)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: monthsCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: 'e.g., 3',
                      suffixText: 'Months',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Calculated EMI: ₹${NumberFormat('#,##,###').format(calculatedEmi)} / month',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Approval Remarks / Note',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g., Approved by HR with 3 months EMI',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        final monthsFinal =
                            int.tryParse(monthsCtrl.text.trim()) ?? currentMonths;

                        final res = await WalletService.reviewSalaryAdvance(
                          advanceId: advanceId,
                          action: 'APPROVE',
                          months: monthsFinal,
                          reviewNote: noteCtrl.text.trim().isNotEmpty
                              ? noteCtrl.text.trim()
                              : 'Approved with $monthsFinal EMI installments',
                        );

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          if (res?['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Salary advance approved for $empName!',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            NotificationService().showLocalNotification(
                              title: 'Salary Advance Approved',
                              body:
                                  'Advance request of ₹${NumberFormat('#,##,###').format(amount)} approved for $empName.',
                            );
                            _fetchAdvances();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res?['message'] ?? 'Failed to approve advance.',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirm Approve',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> advance) {
    final int advanceId = (advance['id'] as num).toInt();
    final String empName = advance['employeeName'] ?? 'Employee';
    final double amount = (advance['amount'] as num?)?.toDouble() ?? 0.0;
    final noteCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    RemixIcons.close_circle_line,
                    color: AppColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Reject Advance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to reject the salary advance request of ₹${NumberFormat('#,##,###').format(amount)} for $empName?',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Reason for Rejection',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g., Advance limit exceeded / Policy restriction',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);

                        final res = await WalletService.reviewSalaryAdvance(
                          advanceId: advanceId,
                          action: 'REJECT',
                          reviewNote: noteCtrl.text.trim().isNotEmpty
                              ? noteCtrl.text.trim()
                              : 'Rejected by HR',
                        );

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          if (res?['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Salary advance request rejected for $empName.',
                                ),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            _fetchAdvances();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res?['message'] ?? 'Failed to reject advance.',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Reject Request',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredAdvances;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Salary Advance Requests',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          // ─── Search & Status Filters ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search employee, department, reason...',
                prefixIcon: const Icon(RemixIcons.search_line),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(RemixIcons.close_line),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                isDense: true,
              ),
            ),
          ),

          // Status chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _StatusChip(
                  label: 'All',
                  isSelected: _selectedStatus == 'ALL',
                  onTap: () {
                    setState(() => _selectedStatus = 'ALL');
                    _fetchAdvances();
                  },
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Pending ($_pendingCount)',
                  isSelected: _selectedStatus == 'PENDING',
                  badgeColor: const Color(0xFFF59E0B),
                  onTap: () {
                    setState(() => _selectedStatus = 'PENDING');
                    _fetchAdvances();
                  },
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Approved ($_approvedCount)',
                  isSelected: _selectedStatus == 'APPROVED',
                  badgeColor: const Color(0xFF10B981),
                  onTap: () {
                    setState(() => _selectedStatus = 'APPROVED');
                    _fetchAdvances();
                  },
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: 'Rejected',
                  isSelected: _selectedStatus == 'REJECTED',
                  badgeColor: const Color(0xFFEF4444),
                  onTap: () {
                    setState(() => _selectedStatus = 'REJECTED');
                    _fetchAdvances();
                  },
                ),
              ],
            ),
          ),

          // ─── Summary Header Banner ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Advance Volume',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${NumberFormat('#,##,###').format(_totalRequestedAmount)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      _StatBadge(
                        label: 'Pending',
                        count: _pendingCount,
                        color: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      _StatBadge(
                        label: 'Approved',
                        count: _approvedCount,
                        color: const Color(0xFF10B981),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Main List View ───────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchAdvances,
                    child: list.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  RemixIcons.hand_coin_line,
                                  size: 48,
                                  color: AppColors.textHint,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No salary advance requests found',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                            itemCount: list.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final adv = list[index];
                              final String status =
                                  (adv['status'] ?? '').toString().toUpperCase();
                              final bool isPending = status == 'PENDING';

                              return _AdvanceRequestCard(
                                advance: adv,
                                isPending: isPending,
                                onApprove: () => _showApproveDialog(adv),
                                onReject: () => _showRejectDialog(adv),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (badgeColor ?? AppColors.primary)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (badgeColor ?? AppColors.primary)
                : AppColors.inputBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvanceRequestCard extends StatelessWidget {
  final Map<String, dynamic> advance;
  final bool isPending;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _AdvanceRequestCard({
    required this.advance,
    required this.isPending,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final empName = advance['employeeName'] ?? 'Employee';
    final empCode = advance['employeeCode'] ?? '';
    final dept = advance['department'] ?? 'General';
    final desig = advance['designation'] ?? 'Staff';
    final double amount = (advance['amount'] as num?)?.toDouble() ?? 0.0;
    final int months = (advance['months'] as num?)?.toInt() ?? 1;
    final double monthlyEmi = (advance['monthlyEmi'] as num?)?.toDouble() ??
        (months > 0 ? (amount / months) : amount);
    final String reason = advance['reason'] ?? 'Salary Advance Request';
    final String status = (advance['status'] ?? 'PENDING').toString().toUpperCase();
    final String? reviewNote = advance['reviewNote'];
    final String? requestedOnStr = advance['requestedOn'];

    DateTime? requestedDate;
    if (requestedOnStr != null) {
      try {
        requestedDate = DateTime.parse(requestedOnStr);
      } catch (_) {}
    }

    Color statusColor = const Color(0xFFF59E0B);
    IconData statusIcon = RemixIcons.time_line;

    if (status == 'APPROVED') {
      statusColor = const Color(0xFF10B981);
      statusIcon = RemixIcons.checkbox_circle_fill;
    } else if (status == 'REJECTED') {
      statusColor = const Color(0xFFEF4444);
      statusIcon = RemixIcons.close_circle_fill;
    }

    final initials = empName.isNotEmpty
        ? empName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'E';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: User Avatar + Details + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initials.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$desig · $dept ($empCode)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
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
          Divider(height: 1, thickness: 1, color: AppColors.divider),
          const SizedBox(height: 14),

          // Amount & EMI Breakdown Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REQUESTED AMOUNT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${NumberFormat('#,##,###').format(amount)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'EMI PLAN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${NumberFormat('#,##,###').format(monthlyEmi)} / mo ($months mos)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Reason & Date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                RemixIcons.information_line,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),

          if (requestedDate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  RemixIcons.time_line,
                  size: 12,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Text(
                  'Requested on ${DateFormat('dd MMM yyyy, hh:mm a').format(requestedDate)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],

          if (reviewNote != null && reviewNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(RemixIcons.feedback_line, size: 14, color: statusColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Remark: $reviewNote',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons for PENDING requests
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(
                      RemixIcons.close_line,
                      size: 16,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Reject',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(
                      RemixIcons.check_line,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Approve',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
