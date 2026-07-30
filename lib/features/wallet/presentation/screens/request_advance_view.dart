import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/services/wallet_service.dart';
import 'package:quickboom_hrm/core/services/notification_service.dart';

class RequestAdvanceView extends StatefulWidget {
  final double maxLimit;
  final Map<String, dynamic>? activeAdvance;

  const RequestAdvanceView({
    super.key,
    required this.maxLimit,
    this.activeAdvance,
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _repaymentMonths = 1;
    final defaultAmt = widget.maxLimit >= 10000.0 ? 10000.0 : widget.maxLimit;
    _amount = (defaultAmt / 1000).round() * 1000.0;
    if (_amount < 0.0) _amount = 0.0;
    _amountCtrl.text = _amount == 0.0 ? '' : NumberFormat('#,##,###').format(_amount);
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
      if (val > widget.maxLimit) {
        _amount = widget.maxLimit;
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
    if (amt > widget.maxLimit) {
      setState(
        () => _error = 'Amount exceeds your limit of ₹${NumberFormat('#,##,###').format(widget.maxLimit)}',
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
                  'Back to Wallet',
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
    final maxVal = widget.maxLimit <= 0 ? 1000.0 : widget.maxLimit;
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
            if (widget.activeAdvance != null) ...[
              _ActiveAdvanceCard(advance: widget.activeAdvance!),
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
                        'Max: ₹${NumberFormat('#,##,###').format(widget.maxLimit)}',
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
                      Text('₹${NumberFormat('#,##,###').format(widget.maxLimit)}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
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
                        const Text(
                          'Estimated Monthly EMI:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        Text(
                          '₹${NumberFormat('#,##,###').format(monthlyEmiPreview.round())} / mo',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF9333EA)),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        icon: const Icon(RemixIcons.file_add_line, color: Colors.white),
        label: const Text(
          'Request Form',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF9333EA),
      ),
    );
  }
}

class _ActiveAdvanceCard extends StatelessWidget {
  final Map<String, dynamic> advance;

  const _ActiveAdvanceCard({required this.advance});

  @override
  Widget build(BuildContext context) {
    final double amount = (advance['amount'] as num?)?.toDouble() ?? 0.0;
    final double monthlyEmi = (advance['monthlyEmi'] as num?)?.toDouble() ?? 0.0;
    final double remaining = (advance['remainingAmount'] as num?)?.toDouble() ?? amount;
    final double paidAmount = (advance['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final int paidEmis = (advance['paidEmis'] as num?)?.toInt() ?? 0;
    final int totalEmis = (advance['months'] as num?)?.toInt() ?? 1;
    final int pendingEmis = (advance['pendingEmis'] as num?)?.toInt() ?? totalEmis;
    final String status = (advance['status'] as String?) ?? 'PENDING';
    final double progress = totalEmis > 0 ? (paidEmis / totalEmis).clamp(0.0, 1.0) : 0.0;

    final isApproved = status == 'APPROVED';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isApproved
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFF451A03), const Color(0xFF78350F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isApproved ? Colors.black : Colors.amber).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isApproved ? const Color(0xFF334155) : const Color(0xFFB45309),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isApproved ? const Color(0xFF10B981) : AppColors.warning).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isApproved ? RemixIcons.check_double_line : RemixIcons.time_line,
                      color: isApproved ? const Color(0xFF10B981) : AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Salary Advance EMI Plan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isApproved ? 'Active • Automatic Monthly Deduction' : 'Pending HR Approval',
                        style: TextStyle(
                          color: isApproved ? const Color(0xFF94A3B8) : const Color(0xFFFDE68A),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved ? const Color(0xFF059669).withValues(alpha: 0.2) : const Color(0xFFD97706).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isApproved ? const Color(0xFF059669) : const Color(0xFFD97706),
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isApproved ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Remaining Advance',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${NumberFormat('#,##,###').format(remaining.round())}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Monthly EMI',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${NumberFormat('#,##,###').format(monthlyEmi.round())} / mo',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isApproved) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: const Color(0xFF334155),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Repaid: ₹${NumberFormat('#,##,###').format(paidAmount.round())} ($paidEmis of $totalEmis EMIs)',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$pendingEmis Pending EMIs',
                  style: const TextStyle(
                    color: Color(0xFFF59E0B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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
