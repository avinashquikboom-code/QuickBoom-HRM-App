import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/services/wallet_service.dart';
import 'package:quickboom_hrm/core/services/notification_service.dart';
import 'package:quickboom_hrm/features/wallet/presentation/widgets/active_advance_card.dart';


class RequestAdvanceView extends StatefulWidget {
  final double maxLimit;
  final Map<String, dynamic>? activeAdvance;
  final List<Map<String, dynamic>>? allAdvances;

  const RequestAdvanceView({
    super.key,
    required this.maxLimit,
    this.activeAdvance,
    this.allAdvances,
  });

  @override
  State<RequestAdvanceView> createState() => _RequestAdvanceViewState();
}

class _RequestAdvanceViewState extends State<RequestAdvanceView> {
  double _amount = 0.0;
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _scrollController = ScrollController();
  int _repaymentMonths = 1;
  bool _isSubmitting = false;
  bool _isLoadingData = false;
  String? _error;

  late double _maxLimit;
  Map<String, dynamic>? _activeAdvance;
  List<Map<String, dynamic>> _allAdvances = [];

  @override
  void initState() {
    super.initState();
    _maxLimit = widget.maxLimit;
    _activeAdvance = widget.activeAdvance;
    if (widget.allAdvances != null) {
      _allAdvances = List<Map<String, dynamic>>.from(widget.allAdvances!);
    }

    _repaymentMonths = 1;
    final defaultAmt = _maxLimit >= 10000.0 ? 10000.0 : _maxLimit;
    _amount = (defaultAmt / 1000).round() * 1000.0;
    if (_amount < 0.0) _amount = 0.0;
    _amountCtrl.text = _amount == 0.0 ? '' : NumberFormat('#,##,###').format(_amount);

    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    if (_allAdvances.isEmpty) {
      setState(() => _isLoadingData = true);
    }
    final wallet = await WalletService.fetchEmployeeWallet();
    if (!mounted) return;

    if (wallet != null) {
      setState(() {
        _maxLimit = (wallet['advanceLimit'] as num?)?.toDouble() ?? _maxLimit;
        _activeAdvance = wallet['activeAdvance'] as Map<String, dynamic>?;
        if (wallet['advances'] != null) {
          _allAdvances = (wallet['advances'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        _isLoadingData = false;
      });
    } else {
      setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String valStr) {
    final cleanStr = valStr.replaceAll(RegExp(r'[^\d]'), '');
    final val = double.tryParse(cleanStr) ?? 0.0;

    setState(() {
      if (val > _maxLimit) {
        _amount = _maxLimit;
      } else {
        _amount = val;
      }

      final formatted = _amount == 0 ? '' : NumberFormat('#,##,###').format(_amount);
      if (_amountCtrl.text != formatted) {
        _amountCtrl.text = formatted;
        _amountCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _amountCtrl.text.length),
        );
      }
    });
  }

  void _onSliderChanged(double val) {
    setState(() {
      _amount = val;
      final formatted = _amount == 0 ? '' : NumberFormat('#,##,###').format(_amount);
      _amountCtrl.text = formatted;
    });
  }

  Future<void> _submitRequest() async {
    setState(() => _error = null);
    final amt = _amount;
    if (amt <= 0) {
      setState(() => _error = 'Please select a valid amount');
      return;
    }
    if (amt > _maxLimit) {
      setState(
        () => _error = 'Amount exceeds your limit of ₹${NumberFormat('#,##,###').format(_maxLimit)}',
      );
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a reason for salary advance');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await WalletService.requestSalaryAdvance(
        amount: amt,
        months: _repaymentMonths,
        reason: _reasonCtrl.text.trim(),
      );

      if (!mounted) return;

      if (result != null && result['success'] == true) {
        NotificationService().showLocalNotification(
          title: 'Advance Request Submitted',
          body: 'Your salary advance request of ₹${NumberFormat('#,##,###').format(amt)} was submitted to HR.',
        );

        _reasonCtrl.clear();
        await _fetchWalletData();

        _showSuccessDialog(amt);
      } else {
        final msg = result?['message'] ?? 'Failed to submit advance request.';
        setState(() => _error = msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Network error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                RemixIcons.checkbox_circle_fill,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Request Submitted',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Your salary advance request of ₹${NumberFormat('#,##,###').format(amount)} has been sent to HR for approval.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context, true); // Return true to refresh wallet
                },
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = _maxLimit <= 0 ? 1000.0 : _maxLimit;
    final divisions = maxVal > 1000 ? (maxVal / 1000).floor() : 1;
    final monthlyEmiPreview = _repaymentMonths > 0 ? (_amount / _repaymentMonths) : _amount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(RemixIcons.arrow_left_line, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Request Salary Advance',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Advance EMI Plan Card
            if (_activeAdvance != null) ...[
              ActiveAdvanceCard(advance: _activeAdvance!),
              const SizedBox(height: 20),
            ],

            // Error Banner
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(RemixIcons.error_warning_line, color: AppColors.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Amount Input Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 16,
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
                        'DESIRED AMOUNT',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Max: ₹${NumberFormat('#,##,###').format(_maxLimit)}',
                        style: const TextStyle(
                          color: Color(0xFF9333EA),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '₹ ',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9333EA),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _amountCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            decoration: const InputDecoration(
                              hintText: '0',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            onChanged: _onAmountChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Slider
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFF9333EA),
                      inactiveTrackColor: const Color(0xFFE2E8F0),
                      thumbColor: const Color(0xFF9333EA),
                      overlayColor: const Color(0xFF9333EA).withValues(alpha: 0.2),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    ),
                    child: Slider(
                      value: _amount.clamp(0.0, maxVal),
                      min: 0.0,
                      max: maxVal,
                      divisions: divisions > 0 ? divisions : 1,
                      onChanged: _onSliderChanged,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('₹0', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                      Text('₹${NumberFormat('#,##,###').format(_maxLimit)}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Duration Selection Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REPAYMENT TENURE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [1, 2, 3, 4, 6].map((months) {
                      final isSelected = _repaymentMonths == months;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _repaymentMonths = months),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF9333EA) : AppColors.background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF9333EA) : AppColors.cardBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$months',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  months == 1 ? 'Month' : 'Months',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9333EA).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Estimated Monthly EMI:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${NumberFormat('#,##,###').format(monthlyEmiPreview.round())} / mo',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF9333EA)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Reason Input Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REASON FOR ADVANCE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonCtrl,
                    maxLines: 3,
                    style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. Medical emergency, house rent, home repair...',
                      hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF9333EA)),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFF9333EA).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(RemixIcons.send_plane_fill, size: 18),
                          SizedBox(width: 10),
                          Text(
                            'Submit Advance Request',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // ─── All Salary Advance Requests Section (History with Timestamps) ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Advance Requests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_allAdvances.length} Requests',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9333EA),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_isLoadingData)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: Color(0xFF9333EA)),
                ),
              )
            else if (_allAdvances.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Icon(RemixIcons.history_line, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                    const SizedBox(height: 10),
                    Text(
                      'No advance requests submitted yet',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _allAdvances.length,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final adv = _allAdvances[index];
                  return GestureDetector(
                    onTap: () => _showAdvanceDetailsSheet(context, adv),
                    child: _AdvanceHistoryCard(advance: adv),
                  );
                },
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showAdvanceDetailsSheet(BuildContext context, Map<String, dynamic> advance) {
    final double amount = (advance['amount'] as num?)?.toDouble() ?? 0.0;
    final int months = (advance['months'] as num?)?.toInt() ?? 1;
    final double monthlyEmi = (advance['monthlyEmi'] as num?)?.toDouble() ?? (months > 0 ? amount / months : amount);
    final String status = (advance['status'] as String?)?.toUpperCase() ?? 'PENDING';
    final String reason = (advance['reason'] as String?) ?? 'No reason provided';
    final String? requestedOn = advance['requestedOn'] as String?;
    final String? reviewNote = advance['reviewNote'] as String?;
    final double remaining = (advance['remainingAmount'] as num?)?.toDouble() ?? amount;
    
    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (status) {
      case 'APPROVED':
        statusColor = const Color(0xFF10B981);
        statusBg = const Color(0xFF10B981).withValues(alpha: 0.12);
        statusIcon = RemixIcons.checkbox_circle_fill;
        break;
      case 'REJECTED':
        statusColor = AppColors.error;
        statusBg = AppColors.error.withValues(alpha: 0.12);
        statusIcon = RemixIcons.close_circle_fill;
        break;
      case 'COMPLETED':
      case 'PAID_OFF':
        statusColor = const Color(0xFF3B82F6);
        statusBg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        statusIcon = RemixIcons.shield_check_fill;
        break;
      case 'PENDING':
      default:
        statusColor = AppColors.warning;
        statusBg = AppColors.warning.withValues(alpha: 0.12);
        statusIcon = RemixIcons.time_fill;
        break;
    }

    String formatTimestamp(String? isoStr) {
      if (isoStr == null || isoStr.isEmpty) return 'N/A';
      try {
        final dt = DateTime.parse(isoStr).toLocal();
        return DateFormat('dd MMM yyyy • hh:mm a').format(dt);
      } catch (_) {
        return isoStr;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Advance Request Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount Requested', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '₹${NumberFormat('#,##,###').format(amount.round())}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Monthly EMI', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '₹${NumberFormat('#,##,###').format(monthlyEmi.round())}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF9333EA)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: AppColors.cardBorder),
            const SizedBox(height: 16),
            Text('Reason', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Text(reason, style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            if (reviewNote != null && reviewNote.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('HR Note', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(RemixIcons.information_fill, color: statusColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reviewNote,
                        style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date Requested', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text(formatTimestamp(requestedOn), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            if (status == 'APPROVED') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Remaining Advance', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text('₹${NumberFormat('#,##,###').format(remaining.round())}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvanceHistoryCard extends StatelessWidget {
  final Map<String, dynamic> advance;

  const _AdvanceHistoryCard({required this.advance});

  String _formatTimestamp(String? isoStr) {
    if (isoStr == null || isoStr.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      return DateFormat('dd MMM yyyy • hh:mm a').format(dt);
    } catch (_) {
      return isoStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double amount = (advance['amount'] as num?)?.toDouble() ?? 0.0;
    final int months = (advance['months'] as num?)?.toInt() ?? 1;
    final double monthlyEmi = (advance['monthlyEmi'] as num?)?.toDouble() ?? (months > 0 ? amount / months : amount);
    final String status = (advance['status'] as String?)?.toUpperCase() ?? 'PENDING';
    final String reason = (advance['reason'] as String?) ?? 'No reason provided';
    final String? requestedOn = advance['requestedOn'] as String?;
    final String? reviewNote = advance['reviewNote'] as String?;

    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    switch (status) {
      case 'APPROVED':
        statusColor = const Color(0xFF10B981);
        statusBg = const Color(0xFF10B981).withValues(alpha: 0.12);
        statusIcon = RemixIcons.checkbox_circle_fill;
        break;
      case 'REJECTED':
        statusColor = AppColors.error;
        statusBg = AppColors.error.withValues(alpha: 0.12);
        statusIcon = RemixIcons.close_circle_fill;
        break;
      case 'COMPLETED':
      case 'PAID_OFF':
        statusColor = const Color(0xFF3B82F6);
        statusBg = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        statusIcon = RemixIcons.shield_check_fill;
        break;
      case 'PENDING':
      default:
        statusColor = AppColors.warning;
        statusBg = AppColors.warning.withValues(alpha: 0.12);
        statusIcon = RemixIcons.time_fill;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
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
          // Header: Amount & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(RemixIcons.bank_card_line, color: Color(0xFF9333EA), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${NumberFormat('#,##,###').format(amount.round())}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$months Month Tenure • ₹${NumberFormat('#,##,###').format(monthlyEmi.round())}/mo',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
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
              const SizedBox(width: 8),
              Flexible(
                flex: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 13),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Reason
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(RemixIcons.chat_quote_line, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  reason,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),

          if (reviewNote != null && reviewNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(RemixIcons.information_line, size: 14, color: statusColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'HR Note: $reviewNote',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Timestamp Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(RemixIcons.time_line, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Requested: ',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    Flexible(
                      child: Text(
                        _formatTimestamp(requestedOn),
                        style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
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
}
