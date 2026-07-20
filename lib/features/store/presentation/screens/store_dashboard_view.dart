import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:remixicon/remixicon.dart';
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
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(RemixIcons.refresh_line, color: AppColors.textSecondary),
            onPressed: _onRefresh,
          ),
        ],
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
    if (state.isLoadingDashboard && state.dashboard == null) {
      return _buildLoadingState();
    }

    if (state.errorMessage != null && state.dashboard == null) {
      return _buildErrorState(state.errorMessage!);
    }

    if (state.dashboard == null) {
      return _buildEmptyState();
    }

    return _buildDashboard(state.dashboard!);
  }

  Widget _buildDashboard(StoreDashboard dashboard) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Store Hero Card ─────────────────────────────────────
          _StoreHeroCard(
            storeName: dashboard.storeName,
            performance: dashboard.storePerformance,
            totalEmployees: dashboard.totalEmployees,
          ).animate().fadeIn().slideY(begin: 0.08, end: 0),

          const SizedBox(height: 24),

          // ── Today's Attendance Strip ─────────────────────────────
          Text(
            "TODAY'S OVERVIEW",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _AttendanceChip(
                  label: 'Present',
                  value: dashboard.presentEmployees,
                  color: const Color(0xFF22C55E),
                  icon: RemixIcons.user_follow_line,
                ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.08, end: 0),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AttendanceChip(
                  label: 'Absent',
                  value: dashboard.absentEmployees,
                  color: const Color(0xFFEF4444),
                  icon: RemixIcons.user_unfollow_line,
                ).animate().fadeIn(delay: 200.ms),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AttendanceChip(
                  label: 'Late',
                  value: dashboard.lateEmployees,
                  color: const Color(0xFFF59E0B),
                  icon: RemixIcons.time_line,
                ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.08, end: 0),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Sales Overview ────────────────────────────────────────
          Text(
            "SALES OVERVIEW",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _SalesCard(
                  label: "Today's Sales",
                  value: '₹${_formatNumber(dashboard.todaySales)}',
                  subtitle: 'Transactions today',
                  color: AppColors.primary,
                  icon: RemixIcons.shopping_bag_line,
                ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.08, end: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SalesCard(
                  label: "Today's Commission",
                  value: '₹${_formatNumber(dashboard.todayRevenue)}',
                  subtitle: 'Earnings today',
                  color: const Color(0xFF8B5CF6),
                  icon: RemixIcons.percent_line,
                ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.08, end: 0),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _SalesCard(
                  label: 'Monthly Sales',
                  value: '₹${_formatNumber(dashboard.monthlySales)}',
                  subtitle: 'Last 30 days',
                  color: const Color(0xFF06B6D4),
                  icon: RemixIcons.bar_chart_2_line,
                ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.08, end: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SalesCard(
                  label: 'Monthly Commission',
                  value: '₹${_formatNumber(dashboard.monthlyRevenue)}',
                  subtitle: 'Last 30 days',
                  color: const Color(0xFF10B981),
                  icon: RemixIcons.funds_line,
                ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.08, end: 0),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Pending Actions ───────────────────────────────────────
          Text(
            "PENDING ACTIONS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ).animate().fadeIn(delay: 550.ms),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _PendingCard(
                  label: 'Leave Requests',
                  count: dashboard.pendingLeaves,
                  icon: RemixIcons.calendar_check_line,
                  color: const Color(0xFFF59E0B),
                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.08, end: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PendingCard(
                  label: 'Expense Claims',
                  count: dashboard.pendingExpenses,
                  icon: RemixIcons.receipt_line,
                  color: const Color(0xFF6366F1),
                ).animate().fadeIn(delay: 650.ms).slideX(begin: 0.08, end: 0),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(height: 160, width: double.infinity, borderRadius: BorderRadius.circular(24)),
          const SizedBox(height: 24),
          Row(
            children: List.generate(3, (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                child: ShimmerLoading(height: 80, width: double.infinity, borderRadius: BorderRadius.circular(16)),
              ),
            )),
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(2, (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 0 ? 12 : 0),
                child: ShimmerLoading(height: 100, width: double.infinity, borderRadius: BorderRadius.circular(16)),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(RemixIcons.error_warning_line, size: 48, color: AppColors.error),
          ),
          const SizedBox(height: 20),
          Text(
            'Failed to load dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDashboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(RemixIcons.refresh_line, size: 16),
            label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(RemixIcons.store_2_line, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('No Store Assigned', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'You are not assigned to any store.\nPlease contact your administrator.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

// ─── Store Hero Card ─────────────────────────────────────────────────────────

class _StoreHeroCard extends StatelessWidget {
  final String storeName;
  final double performance;
  final int totalEmployees;

  const _StoreHeroCard({
    required this.storeName,
    required this.performance,
    required this.totalEmployees,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4338CA).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(RemixIcons.store_2_line, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
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
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalEmployees Active Employees',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(RemixIcons.checkbox_circle_fill, color: Colors.white, size: 11),
                    SizedBox(width: 4),
                    Text('Active', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'ATTENDANCE RATE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (performance / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '${performance.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Attendance Chip ──────────────────────────────────────────────────────────

class _AttendanceChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _AttendanceChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sales Card ───────────────────────────────────────────────────────────────

class _SalesCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _SalesCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
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

// ─── Pending Card ─────────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _PendingCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: count > 0 ? color : AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Action',
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
              ),
            ),
        ],
      ),
    );
  }
}
