import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';

class ActiveAdvanceCard extends StatelessWidget {
  final Map<String, dynamic> advance;
  final VoidCallback? onRepay;

  const ActiveAdvanceCard({super.key, required this.advance, this.onRepay});

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
      margin: const EdgeInsets.only(bottom: 16),
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
            color: (isApproved ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                .withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isApproved
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : const Color(0xFFF59E0B).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isApproved ? const Color(0xFF10B981) : AppColors.warning)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isApproved ? RemixIcons.check_double_line : RemixIcons.time_line,
                        color: isApproved ? const Color(0xFF10B981) : AppColors.warning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
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
                            isApproved
                                ? 'Active • Automatic Monthly Deduction'
                                : 'Pending HR Approval',
                            style: TextStyle(
                              color: isApproved ? const Color(0xFF94A3B8) : const Color(0xFFFDE68A),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isApproved
                      ? const Color(0xFF059669).withValues(alpha: 0.2)
                      : const Color(0xFFD97706).withValues(alpha: 0.2),
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
                      fontWeight: FontWeight.w900,
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

          if (isApproved && remaining > 0 && onRepay != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRepay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFF34D399),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF10B981), width: 1),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(RemixIcons.bank_card_line, size: 18),
                    SizedBox(width: 8),
                    Text('Repay EMI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
