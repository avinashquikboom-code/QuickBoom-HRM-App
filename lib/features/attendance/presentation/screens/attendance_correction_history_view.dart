import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';

// ─── Color helpers (kept local so this file has no coupling to parent) ────────

/// Parses a raw JSON date value to a local DateTime.
/// Handles:
///   • ISO 8601 strings  ("2024-01-15T00:00:00.000Z", "2024-01-15T05:30:00+05:30")
///   • Date-only strings ("2024-01-15")
///   • Unix ms integers  (1705276800000)
///   • Returns null for any unparseable value — never throws.
DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw).toLocal();
  }
  final str = raw.toString().trim();
  if (str.isEmpty) return null;
  // Try full ISO parse first
  final dt = DateTime.tryParse(str);
  if (dt != null) return dt.toLocal();
  // Fallback: strip any trailing timezone garbage and retry
  final stripped = str.replaceAll(RegExp(r'[Z+].*$'), '');
  final dt2 = DateTime.tryParse(stripped);
  return dt2?.toLocal();
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'APPROVED':
      return AppColors.success;
    case 'REJECTED':
      return AppColors.error;
    default:
      return AppColors.warning;
  }
}

IconData _statusIcon(String status) {
  switch (status.toUpperCase()) {
    case 'APPROVED':
      return RemixIcons.checkbox_circle_fill;
    case 'REJECTED':
      return RemixIcons.close_circle_fill;
    default:
      return RemixIcons.time_fill;
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AttendanceCorrectionHistoryView extends StatefulWidget {
  final List<dynamic> requests;
  final Future<void> Function() onRefresh;
  final void Function(dynamic req) onShowDetail;

  const AttendanceCorrectionHistoryView({
    super.key,
    required this.requests,
    required this.onRefresh,
    required this.onShowDetail,
  });

  @override
  State<AttendanceCorrectionHistoryView> createState() =>
      _AttendanceCorrectionHistoryViewState();
}

class _AttendanceCorrectionHistoryViewState
    extends State<AttendanceCorrectionHistoryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<dynamic> _requests;
  bool _refreshing = false;

  static const _tabs = ['ALL', 'PENDING', 'APPROVED', 'REJECTED'];

  @override
  void initState() {
    super.initState();
    _requests = List.from(widget.requests);
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _filtered(String status) {
    if (status == 'ALL') return _requests;
    return _requests
        .where((r) =>
            r is Map &&
            r['status']?.toString().toUpperCase() == status.toUpperCase())
        .toList();
  }

  int _count(String status) => _filtered(status).length;

  Future<void> _doRefresh() async {
    setState(() => _refreshing = true);
    await widget.onRefresh();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [_buildAppBar()],
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map((tab) => _TabPage(
                status: tab,
                items: _filtered(tab),
                onRefresh: _doRefresh,
                onShowDetail: widget.onShowDetail,
              )).toList(),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(RemixIcons.history_line,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Correction History',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              Text('${_requests.length} total request(s)',
                  style: TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
      actions: [
        _refreshing
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                icon: Icon(RemixIcons.refresh_line,
                    color: AppColors.textSecondary, size: 20),
                onPressed: _doRefresh,
              ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800),
            unselectedLabelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            dividerColor: AppColors.divider,
            padding:
                const EdgeInsets.symmetric(horizontal: 8),
            tabs: _tabs.map((t) {
              final color =
                  t == 'ALL' ? AppColors.primary : _statusColor(t);
              final cnt = _count(t);
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$cnt',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Tab page ─────────────────────────────────────────────────────────────────

class _TabPage extends StatelessWidget {
  final String status;
  final List<dynamic> items;
  final Future<void> Function() onRefresh;
  final void Function(dynamic req) onShowDetail;

  const _TabPage({
    required this.status,
    required this.items,
    required this.onRefresh,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            _EmptyState(filter: status),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final req = items[index];
          if (req == null || req is! Map) {
            return const SizedBox.shrink();
          }
          return _HistoryTile(
            req: req,
            index: index,
            onTap: () => onShowDetail(req),
          );
        },
      ),
    );
  }
}

// ─── History tile ─────────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  final Map req;
  final int index;
  final VoidCallback onTap;

  const _HistoryTile({
    required this.req,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = req['status']?.toString() ?? 'PENDING';
    final color = _statusColor(status);

    String dateStr = '';
    String appliedStr = '';
    if (req['attendanceDate'] != null) {
      final parsed = _parseDate(req['attendanceDate']);
      if (parsed != null) {
        dateStr = DateFormat('dd MMM yyyy').format(parsed);
      }
    }
    if (req['appliedOn'] != null) {
      final parsed = _parseDate(req['appliedOn']);
      if (parsed != null) {
        appliedStr = DateFormat('dd MMM, hh:mm a').format(parsed);
      }
    }

    final currentSt = req['currentStatus']?.toString() ?? 'ABSENT';
    final requestedSt = req['requestedStatus']?.toString() ?? 'PRESENT';
    final reason = req['reason']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: date + status badge
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  // Status icon circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_statusIcon(status),
                        color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        if (appliedStr.isNotEmpty)
                          Text('Applied: $appliedStr',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: color),
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            Divider(
                height: 1,
                color: AppColors.divider,
                indent: 14,
                endIndent: 14),

            // Bottom row: correction summary
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Correction arrow
                  Row(
                    children: [
                      _MiniStatusBadge(
                          label: currentSt,
                          color: AppColors.error),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(RemixIcons.arrow_right_line,
                            size: 12,
                            color: AppColors.textHint),
                      ),
                      _MiniStatusBadge(
                          label: requestedSt,
                          color: AppColors.success),
                    ],
                  ),
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(RemixIcons.double_quotes_l,
                            size: 12,
                            color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniStatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(RemixIcons.inbox_2_line,
                size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            filter == 'ALL'
                ? 'No requests yet'
                : 'No $filter requests',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh, or go back\nto submit a new correction request.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6),
          ),
        ],
      ),
    );
  }
}
