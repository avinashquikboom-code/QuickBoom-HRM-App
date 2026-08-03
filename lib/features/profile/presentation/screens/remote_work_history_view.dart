import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';

class RemoteWorkHistoryView extends StatefulWidget {
  const RemoteWorkHistoryView({super.key});

  @override
  State<RemoteWorkHistoryView> createState() => _RemoteWorkHistoryViewState();
}

class _RemoteWorkHistoryViewState extends State<RemoteWorkHistoryView> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get('/api/mobile/remote-work/my-requests');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          setState(() {
            _requests = body['data'] as List<dynamic>;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load remote work history (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('ApiException: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'REJECTED':
        return AppColors.error;
      case 'REVOKED':
        return Colors.orange;
      default:
        return AppColors.textHint;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return RemixIcons.checkbox_circle_line;
      case 'PENDING':
        return RemixIcons.time_line;
      case 'REJECTED':
        return RemixIcons.close_circle_line;
      case 'REVOKED':
        return RemixIcons.error_warning_line;
      default:
        return RemixIcons.information_line;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Remote Work History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRequests,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(RemixIcons.error_warning_line, size: 48, color: AppColors.error),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _fetchRequests,
                            icon: const Icon(RemixIcons.refresh_line, size: 18),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(RemixIcons.global_line, size: 48, color: AppColors.info),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Remote Work Requests',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'You have not submitted any remote work requests yet.',
                              style: TextStyle(color: AppColors.textHint, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final req = _requests[index];
                          final status = req['status'] ?? 'PENDING';
                          final color = _getStatusColor(status);
                          final icon = _getStatusIcon(status);

                          DateTime? fromDt;
                          DateTime? toDt;
                          DateTime? createdDt;

                          try {
                            if (req['fromDate'] != null) fromDt = DateTime.parse(req['fromDate']);
                            if (req['toDate'] != null) toDt = DateTime.parse(req['toDate']);
                            if (req['createdAt'] != null) createdDt = DateTime.parse(req['createdAt']);
                          } catch (_) {}

                          // Determine if this APPROVED request is currently active
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final isActiveApproved = status.toUpperCase() == 'APPROVED' &&
                              fromDt != null &&
                              toDt != null &&
                              !today.isAfter(toDt);

                          return Column(
                            children: [
                              // Countdown banner for active approved remote work
                              if (isActiveApproved) ...[
                                _RemoteWorkCountdownBanner(
                                  fromDate: fromDt,
                                  toDate: toDt,
                                ),
                                const SizedBox(height: 10),
                              ],

                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActiveApproved
                                        ? AppColors.success.withValues(alpha: 0.4)
                                        : AppColors.cardBorder,
                                    width: isActiveApproved ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: color.withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(icon, size: 14, color: color),
                                              const SizedBox(width: 5),
                                              Text(
                                                status,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (createdDt != null)
                                          Text(
                                            DateFormat('dd MMM yyyy').format(createdDt),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textHint,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Icon(RemixIcons.calendar_event_line,
                                            size: 16, color: AppColors.info),
                                        const SizedBox(width: 8),
                                        Text(
                                          fromDt != null && toDt != null
                                              ? '${DateFormat('dd MMM yyyy').format(fromDt)}  →  ${DateFormat('dd MMM yyyy').format(toDt)}'
                                              : 'N/A',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (req['reason'] != null && req['reason'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        req['reason'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                    if (req['reviewNote'] != null && req['reviewNote'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.divider),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(RemixIcons.chat_1_line,
                                                size: 14, color: AppColors.textHint),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'HR Note: ${req['reviewNote']}',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppColors.textHint,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
      ),
    );
  }
}

// ─── Countdown Banner Widget ───────────────────────────────────────────────────

class _RemoteWorkCountdownBanner extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;

  const _RemoteWorkCountdownBanner({
    required this.fromDate,
    required this.toDate,
  });

  @override
  State<_RemoteWorkCountdownBanner> createState() => _RemoteWorkCountdownBannerState();
}

class _RemoteWorkCountdownBannerState extends State<_RemoteWorkCountdownBanner>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Duration _remaining = Duration.zero;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  void _updateCountdown() {
    final now = DateTime.now();
    // End of the toDate (end of day)
    final endOfRemote = DateTime(
      widget.toDate.year,
      widget.toDate.month,
      widget.toDate.day,
      23, 59, 59,
    );
    final startOfRemote = DateTime(
      widget.fromDate.year,
      widget.fromDate.month,
      widget.fromDate.day,
    );

    setState(() {
      _hasStarted = now.isAfter(startOfRemote);
      if (now.isBefore(endOfRemote)) {
        _remaining = endOfRemote.difference(now);
      } else {
        _remaining = Duration.zero;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    final isExpired = _remaining == Duration.zero;
    final isToday = DateTime.now().day == widget.toDate.day &&
        DateTime.now().month == widget.toDate.month &&
        DateTime.now().year == widget.toDate.year;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isExpired ? 1.0 : _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isExpired
                ? [const Color(0xFF94A3B8), const Color(0xFF64748B)]
                : isToday
                    ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                    : [const Color(0xFF10B981), const Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (isExpired
                  ? Colors.grey
                  : isToday
                      ? Colors.red
                      : AppColors.success)
                  .withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(RemixIcons.global_line, color: Colors.white, size: 16),
                const SizedBox(width: 7),
                Text(
                  isExpired
                      ? 'Remote Work Period Ended'
                      : _hasStarted
                          ? '🏠 Remote Work Active — Ends In'
                          : '🏠 Remote Work Starts Soon',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),

            if (!isExpired) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CountdownUnit(value: _pad(days), label: 'Days'),
                  _CountdownSep(),
                  _CountdownUnit(value: _pad(hours), label: 'Hours'),
                  _CountdownSep(),
                  _CountdownUnit(value: _pad(minutes), label: 'Mins'),
                  _CountdownSep(),
                  _CountdownUnit(value: _pad(seconds), label: 'Secs'),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isToday
                      ? '⚠️  Last day of remote work!'
                      : 'Until ${DateFormat('dd MMM yyyy').format(widget.toDate)} end of day',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  final String value;
  final String label;

  const _CountdownUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _CountdownSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
