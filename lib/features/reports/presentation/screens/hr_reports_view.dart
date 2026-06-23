import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';

class HrReportsView extends StatelessWidget {
  const HrReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildChartCard(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(value: 65, title: '65%', color: AppColors.success, radius: 40),
                    PieChartSectionData(value: 20, title: '20%', color: AppColors.warning, radius: 35),
                    PieChartSectionData(value: 10, title: '10%', color: AppColors.error, radius: 30),
                    PieChartSectionData(value: 5, title: '5%', color: AppColors.info, radius: 25),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(color: AppColors.success, label: 'Present'),
                const SizedBox(width: 12),
                _Legend(color: AppColors.warning, label: 'Late'),
                const SizedBox(width: 12),
                _Legend(color: AppColors.error, label: 'Absent'),
                const SizedBox(width: 12),
                _Legend(color: AppColors.info, label: 'Leave'),
              ],
            ),
            const SizedBox(height: 30),

            Text(
              'Monthly Expense (₹)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildChartCard(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 20,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          const titles = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(titles[val.toInt()], style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _barGroup(0, 12, 4),
                    _barGroup(1, 15, 5),
                    _barGroup(2, 18, 2),
                    _barGroup(3, 10, 6),
                    _barGroup(4, 16, 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(color: AppColors.primary, label: 'Approved'),
                const SizedBox(width: 16),
                _Legend(color: AppColors.warning, label: 'Pending'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({required double height, required Widget child}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }

  BarChartGroupData _barGroup(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: AppColors.primary,
          width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: y2,
          color: AppColors.warning,
          width: 12,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
