import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/features/reports/presentation/providers/hr_reports_viewmodel.dart';

class HrReportsView extends ConsumerWidget {
  const HrReportsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsState = ref.watch(hrReportsViewModelProvider);
    final attendanceSummary = ref.watch(hrReportsViewModelProvider.notifier).getAttendanceSummary();
    final monthlyExpenseData = ref.watch(hrReportsViewModelProvider.notifier).getMonthlyExpenseData();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(hrReportsViewModelProvider.notifier).fetchReportsData(),
          ),
        ],
      ),
      body: reportsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        sections: _buildAttendancePieSections(attendanceSummary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Legend(color: AppColors.success, label: 'Present (${attendanceSummary['present']})'),
                      const SizedBox(width: 12),
                      _Legend(color: AppColors.warning, label: 'Late (${attendanceSummary['late']})'),
                      const SizedBox(width: 12),
                      _Legend(color: AppColors.error, label: 'Absent (${attendanceSummary['absent']})'),
                      const SizedBox(width: 12),
                      _Legend(color: AppColors.info, label: 'Leave (${attendanceSummary['leave']})'),
                    ],
                  ),
                  const SizedBox(height: 30),

                  Text(
                    'Monthly Expense Claims',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _buildChartCard(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxExpenseCount(monthlyExpenseData),
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                final months = monthlyExpenseData.keys.toList();
                                if (val.toInt() >= 0 && val.toInt() < months.length) {
                                  final monthKey = months[val.toInt()];
                                  final parts = monthKey.split('-');
                                  final monthNum = int.parse(parts[1]);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      DateFormat('MMM').format(DateTime(2000, monthNum)),
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: _buildExpenseBarGroups(monthlyExpenseData),
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

  List<PieChartSectionData> _buildAttendancePieSections(Map<String, int> summary) {
    final total = summary.values.reduce((a, b) => a + b);
    if (total == 0) {
      return [
        PieChartSectionData(value: 1, title: 'No Data', color: AppColors.textHint, radius: 40),
      ];
    }

    final present = summary['present'] ?? 0;
    final late = summary['late'] ?? 0;
    final absent = summary['absent'] ?? 0;
    final leave = summary['leave'] ?? 0;

    return [
      if (present > 0)
        PieChartSectionData(
          value: present.toDouble(),
          title: '${((present / total) * 100).toStringAsFixed(0)}%',
          color: AppColors.success,
          radius: 40,
        ),
      if (late > 0)
        PieChartSectionData(
          value: late.toDouble(),
          title: '${((late / total) * 100).toStringAsFixed(0)}%',
          color: AppColors.warning,
          radius: 35,
        ),
      if (absent > 0)
        PieChartSectionData(
          value: absent.toDouble(),
          title: '${((absent / total) * 100).toStringAsFixed(0)}%',
          color: AppColors.error,
          radius: 30,
        ),
      if (leave > 0)
        PieChartSectionData(
          value: leave.toDouble(),
          title: '${((leave / total) * 100).toStringAsFixed(0)}%',
          color: AppColors.info,
          radius: 25,
        ),
    ];
  }

  double _getMaxExpenseCount(Map<String, Map<String, int>> monthlyData) {
    double maxCount = 0;
    for (var monthData in monthlyData.values) {
      final total = (monthData['approved'] ?? 0) + (monthData['pending'] ?? 0);
      if (total > maxCount) maxCount = total.toDouble();
    }
    return maxCount > 0 ? maxCount + 5 : 20;
  }

  List<BarChartGroupData> _buildExpenseBarGroups(Map<String, Map<String, int>> monthlyData) {
    final months = monthlyData.keys.toList();
    return months.asMap().entries.map((entry) {
      final index = entry.key;
      final monthKey = entry.value;
      final data = monthlyData[monthKey]!;
      return _barGroup(index, (data['approved'] ?? 0).toDouble(), (data['pending'] ?? 0).toDouble());
    }).toList();
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
