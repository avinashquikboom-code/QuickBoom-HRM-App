import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/services/wallet_service.dart';

class RepayEmiSheet extends StatefulWidget {
  final Map<String, dynamic> advance;
  final VoidCallback onRepaySuccess;

  const RepayEmiSheet({
    super.key,
    required this.advance,
    required this.onRepaySuccess,
  });

  static Future<void> show(BuildContext context, Map<String, dynamic> advance, VoidCallback onRepaySuccess) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RepayEmiSheet(advance: advance, onRepaySuccess: onRepaySuccess),
    );
  }

  @override
  State<RepayEmiSheet> createState() => _RepayEmiSheetState();
}

class _RepayEmiSheetState extends State<RepayEmiSheet> {
  late TextEditingController _amountController;
  String _paymentMethod = 'UPI';
  bool _isLoading = false;
  
  late double _remainingAmount;
  late double _monthlyEmi;

  @override
  void initState() {
    super.initState();
    _remainingAmount = (widget.advance['remainingAmount'] as num?)?.toDouble() ?? 0.0;
    _monthlyEmi = (widget.advance['monthlyEmi'] as num?)?.toDouble() ?? 0.0;
    
    // Default to monthly EMI, unless remaining is less
    final defaultAmount = _remainingAmount < _monthlyEmi ? _remainingAmount : _monthlyEmi;
    _amountController = TextEditingController(text: defaultAmount.round().toString());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _processRepayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0 || amount > _remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final advanceId = widget.advance['id'] as int;
    final result = await WalletService.repaySalaryAdvance(
      advanceId: advanceId,
      amount: amount,
      paymentMethod: _paymentMethod,
    );

    setState(() {
      _isLoading = false;
    });

    if (result != null && result['success'] == true) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repayment successful!'), backgroundColor: Colors.green),
        );
        widget.onRepaySuccess();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result?['message'] ?? 'Failed to process repayment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Repay Advance EMI',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining Balance:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                Text(
                  '₹${NumberFormat('#,##,###').format(_remainingAmount.round())}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Amount to Repay',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.currency_rupee, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.cardBorder),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _paymentMethod,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                items: ['UPI', 'Bank Transfer', 'Wallet'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _paymentMethod = newValue!;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processRepayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Pay Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
