import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';

class PayCard extends StatelessWidget {
  final String employeeName;
  final String cardNumber;
  final double netSalary;
  final double grossSalary;
  final double? commission;
  final String? monthYear;

  const PayCard({
    super.key,
    required this.employeeName,
    required this.cardNumber,
    required this.netSalary,
    required this.grossSalary,
    this.commission = 0,
    this.monthYear,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[PayCard DEBUG] Commission: $commission, NetSalary: $netSalary',
    );

    final commVal = commission ?? 0;
    final hasCommission = commVal > 0;
    final totalSalary = netSalary + commVal;

    final formattedNet = NumberFormat('#,##,###').format(netSalary);
    final formattedComm = hasCommission
        ? '+₹${NumberFormat('#,##,###').format(commVal)}'
        : '₹0';
    final formattedTotal = NumberFormat('#,##,###').format(totalSalary);
    final formattedGross = NumberFormat('#,##,###').format(grossSalary);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16A085), Color(0xFF1E8449)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E8449).withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: PAY CARD + Month/Year + Diamond Icon ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'PAY CARD',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  if (monthYear != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        monthYear!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  RemixIcons.vip_diamond_line,
                  color: Colors.amberAccent,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─── 1. Employee Name at Top ───
          Text(
            employeeName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),

          // ─── 2. NET SALARY Section ───
          _buildSalaryBlock(
            label: 'NET SALARY',
            value: '₹$formattedNet',
            labelColor: Colors.white.withValues(alpha: 0.8),
            valueColor: Colors.white,
            valueFontSize: 17,
          ),
          const SizedBox(height: 14),

          // ─── 2 & 5 & 7. + COMMISSION Section (Gold/Yellow) ───
          _buildSalaryBlock(
            label: '+ COMMISSION',
            value: formattedComm,
            labelColor: const Color(0xFFFDE047),
            valueColor: const Color(0xFFFDE047),
            valueFontSize: 17,
          ),
          const SizedBox(height: 14),

          // ─── Divider ───
          Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 14),

          // ─── 2 & 4. TOTAL SALARY Section (Largest & Boldest) ───
          _buildSalaryBlock(
            label: 'TOTAL SALARY=',
            value: '₹$formattedTotal',
            labelColor: Colors.white.withValues(alpha: 0.95),
            valueColor: Colors.white,
            isBold: true,
            valueFontSize: 26,
          ),

          const SizedBox(height: 20),

          // ─── 6. Bottom Footer: Gross Salary + Card No ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GROSS SALARY',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹$formattedGross',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'CARD NO',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cardNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryBlock({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
    required double valueFontSize,
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: isBold ? 11.5 : 10,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: valueFontSize,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
