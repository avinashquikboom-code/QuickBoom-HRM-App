import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/widgets/shimmer_loading.dart';
import 'package:quickboom_hrm/features/store/data/store_models.dart';
import 'package:quickboom_hrm/features/store/presentation/providers/store_dashboard_viewmodel.dart';

class StoreDashboardView extends ConsumerStatefulWidget {
  const StoreDashboardView({super.key});

  @override
  ConsumerState<StoreDashboardView> createState() => _StoreDashboardViewState();
}

class _StoreDashboardViewState extends ConsumerState<StoreDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDashboard();
      }
    });
  }

  Future<void> _loadDashboard() async {
    await ref.read(storeDashboardViewModelProvider.notifier).fetchDashboard();
  }

  Future<void> _onRefresh() async {
    await _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeDashboardViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Store Dashboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(StoreDashboardState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                RemixIcons.store_2_line,
                size: 64,
                color: AppColors.primary,
              ),
            ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOut),
            const SizedBox(height: 32),
            Text(
              'Store Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 12),
            Text(
              'This feature will be available in the next version update. Stay tuned!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(RemixIcons.code_box_line, size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Text(
                    'Feature Coming Soon',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyOld(StoreDashboardState state) {
    if (state.dashboard == null) return const SizedBox.shrink();
    final dashboard = state.dashboard!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Header Card
          _StoreHeaderCard(
            storeName: dashboard.storeName,
            performance: dashboard.storePerformance,
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Today's Stats
          Text(
            'Today\'s Overview',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Today\'s Sales',
                  value: '₹${dashboard.todaySales.toStringAsFixed(0)}',
                  icon: RemixIcons.money_dollar_box_line,
                  color: AppColors.success,
                ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1, end: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Revenue',
                  value: '₹${dashboard.todayRevenue.toStringAsFixed(0)}',
                  icon: RemixIcons.line_chart_line,
                  color: AppColors.primary,
                ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.1, end: 0),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Present',
                  value: '${dashboard.presentEmployees}/${dashboard.totalEmployees}',
                  icon: RemixIcons.checkbox_circle_line,
                  color: AppColors.success,
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Absent',
                  value: dashboard.absentEmployees.toString(),
                  icon: RemixIcons.close_circle_line,
                  color: AppColors.error,
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Late',
                  value: dashboard.lateEmployees.toString(),
                  icon: RemixIcons.time_line,
                  color: AppColors.warning,
                ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1, end: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Pending Leaves',
                  value: dashboard.pendingLeaves.toString(),
                  icon: RemixIcons.calendar_check_line,
                  color: AppColors.info,
                ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.1, end: 0),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Monthly Overview
          Text(
            'Monthly Overview',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Monthly Sales',
                  value: '₹${dashboard.monthlySales.toStringAsFixed(0)}',
                  icon: RemixIcons.bar_chart_box_line,
                  color: AppColors.primary,
                ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.1, end: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Monthly Revenue',
                  value: '₹${dashboard.monthlyRevenue.toStringAsFixed(0)}',
                  icon: RemixIcons.funds_box_line,
                  color: AppColors.success,
                ).animate().fadeIn(delay: 350.ms).slideX(begin: 0.1, end: 0),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pending Actions
          Text(
            'Pending Actions',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 12),
          _PendingActionsCard(
            pendingLeaves: dashboard.pendingLeaves,
            pendingExpenses: dashboard.pendingExpenses,
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Daily Sales Summary
          if (dashboard.dailySalesSummary.isNotEmpty) ...[
            Text(
              'Daily Sales Summary',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dashboard.dailySalesSummary.length,
                itemBuilder: (context, index) {
                  final summary = dashboard.dailySalesSummary[index];
                  return _DailySalesCard(summary: summary)
                      .animate()
                      .fadeIn(delay: (500 + index * 50).ms)
                      .slideX(begin: 0.1, end: 0);
                },
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ShimmerLoading(
          height: 100,
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
            onPressed: _loadDashboard,
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
          Icon(RemixIcons.store_2_line, size: 48, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'No store data available',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _StoreHeaderCard extends StatelessWidget {
  final String storeName;
  final double performance;

  const _StoreHeaderCard({
    required this.storeName,
    required this.performance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(RemixIcons.store_2_line, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Store Performance',
                      style: TextStyle(
                        color: AppColors.primaryLight.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: performance / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${performance.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingActionsCard extends StatelessWidget {
  final int pendingLeaves;
  final int pendingExpenses;

  const _PendingActionsCard({
    required this.pendingLeaves,
    required this.pendingExpenses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PendingActionItem(
              label: 'Pending Leaves',
              count: pendingLeaves,
              icon: RemixIcons.calendar_check_line,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PendingActionItem(
              label: 'Pending Expenses',
              count: pendingExpenses,
              icon: RemixIcons.receipt_line,
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingActionItem extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _PendingActionItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailySalesCard extends StatelessWidget {
  final StoreSalesSummary summary;

  const _DailySalesCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.date,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${summary.sales.toStringAsFixed(0)}',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.billsGenerated} bills',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
