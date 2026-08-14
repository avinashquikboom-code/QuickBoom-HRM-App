import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';

import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/storage_service.dart';
import 'package:quickboom_hrm/core/services/websocket_service.dart';
import 'package:quickboom_hrm/features/commission/presentation/screens/webhook_logs_screen.dart';
import 'package:quickboom_hrm/screens/commission/commission_detail_screen.dart';

class WebhookLogsWidget extends StatefulWidget {
  final int itemsToShow;
  const WebhookLogsWidget({super.key, this.itemsToShow = 5});

  @override
  State<WebhookLogsWidget> createState() => _WebhookLogsWidgetState();
}

class _WebhookLogsWidgetState extends State<WebhookLogsWidget> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  bool _hasError = false;
  Timer? _timer;
  StreamSubscription? _commissionSub;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    // Auto-refresh every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _silentRefresh());
    // Auto-refresh on real-time webhook updates
    _commissionSub = WebSocketService().commissionUpdates.listen((_) {
      _silentRefresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _commissionSub?.cancel();
    super.dispose();
  }

  /// Refresh without showing the skeleton spinner (avoids UI flicker).
  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final token = await StorageService.getToken();
      if (token == null) return;
      final response = await http
          .get(
            Uri.parse('${AppUrl.baseUrl}${AppUrl.mobileWebhookLogs}?limit=10'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        setState(() {
          _logs = List<Map<String, dynamic>>.from(data is List ? data : []);
          _hasError = false;
        });
      }
    } catch (e) {
      dev.log('Webhook silent refresh: $e', name: 'WebhookLogsWidget');
    }
  }

  Future<void> _fetchLogs() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        if (mounted) setState(() { _loading = false; _hasError = true; });
        return;
      }
      final response = await http
          .get(
            Uri.parse('${AppUrl.baseUrl}${AppUrl.mobileWebhookLogs}?limit=10'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];
        setState(() {
          _logs = List<Map<String, dynamic>>.from(data is List ? data : []);
          _loading = false;
        });
      } else {
        dev.log('Webhook logs HTTP ${response.statusCode}', name: 'WebhookLogsWidget');
        setState(() { _loading = false; _hasError = true; });
      }
    } catch (e) {
      dev.log('Webhook logs exception: $e', name: 'WebhookLogsWidget');
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      return DateFormat('dd MMM, hh:mm a').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return '—';
    }
  }

  _StatusTheme _statusTheme(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'SUCCESS':
        return _StatusTheme('SUCCESS', AppColors.success, AppColors.successSurface, RemixIcons.checkbox_circle_fill);
      case 'FAILED':
        return _StatusTheme('FAILED', AppColors.error, AppColors.errorSurface, RemixIcons.close_circle_fill);
      default:
        return _StatusTheme('PROCESSING', AppColors.warning, AppColors.warningSurface, RemixIcons.time_fill);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (_loading) _buildSkeleton()
          else if (_hasError) _buildError()
          else if (_logs.isEmpty) _buildEmpty()
          else _buildList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(RemixIcons.webhook_line, color: Color(0xFF6366F1), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'WEBHOOK ACTIVITY',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        GestureDetector(
          onTap: _fetchLogs,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(RemixIcons.refresh_line, size: 16, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(16),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(RemixIcons.error_warning_line, color: AppColors.error, size: 30),
            const SizedBox(height: 8),
            Text(
              'Failed to load webhook events',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _fetchLogs,
              child: Text(
                'Tap to retry',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(RemixIcons.webhook_line, color: AppColors.textHint, size: 32),
            const SizedBox(height: 10),
            Text(
              'No webhook events yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'POS sales events will appear here',
              style: TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final visible = _logs.take(widget.itemsToShow).toList();
    final hasMore = _logs.length > widget.itemsToShow;
    return Column(
      children: [
        ...visible.asMap().entries.map(
          (e) => _LogRow(
            log: e.value,
            formatTime: _formatTime,
            statusTheme: _statusTheme,
          )
              .animate(delay: (e.key * 60).ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05, end: 0),
        ),
        if (hasMore) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.07),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WebhookLogsScreen()),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View All ${_logs.length} Webhook Events',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 14),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── _LogRow ───────────────────────────────────────────────────────────────────

class _LogRow extends StatelessWidget {
  final Map<String, dynamic> log;
  final String Function(String?) formatTime;
  final _StatusTheme Function(String?) statusTheme;

  const _LogRow({
    required this.log,
    required this.formatTime,
    required this.statusTheme,
  });

  Map<String, dynamic> _getBadgeStyle(String eventType) {
    final upper = eventType.toUpperCase();
    if (upper.contains('CREDIT_NOTE')) {
      return {
        'bg': const Color(0xFFFFF1F2),
        'color': const Color(0xFFE11D48),
        'border': const Color(0xFFFECDD3),
      };
    }
    if (upper.contains('EXCHANGE')) {
      return {
        'bg': const Color(0xFFF3E8FF),
        'color': const Color(0xFF9333EA),
        'border': const Color(0xFFE9D5FF),
      };
    }
    if (upper.contains('INVOICE')) {
      return {
        'bg': const Color(0xFFECFDF5),
        'color': const Color(0xFF059669),
        'border': const Color(0xFFA7F3D0),
      };
    }
    return {
      'bg': const Color(0xFFEEF2FF),
      'color': const Color(0xFF4F46E5),
      'border': const Color(0xFFC7D2FE),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = statusTheme(log['status'] as String?);
    final billId = (log['billId'] ?? '—').toString();
    final invoiceNo = (log['invoiceNo'] ?? '').toString();
    final amount = log['amount'];
    final amountStr = amount == null
        ? '—'
        : '₹${NumberFormat('#,##,###').format((amount as num).toDouble())}';
    final commRaw = log['commissionAmount'];
    final commAmt = commRaw != null ? (commRaw as num).toDouble() : 0.0;
    final eventType = (log['eventType'] ?? '—').toString();
    final time = formatTime(log['createdAt'] as String?);
    final badge = _getBadgeStyle(eventType);

    final isReversal = commAmt < 0 || eventType.toUpperCase().contains('CREDIT_NOTE');
    final isPositiveComm = commAmt > 0;

    final idToPass = invoiceNo.isNotEmpty ? invoiceNo : billId;

    return GestureDetector(
      onTap: () {
        if (idToPass.isNotEmpty && idToPass != '—') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommissionDetailScreen(billId: idToPass),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBorder.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badge['bg'] as Color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badge['border'] as Color),
                ),
                child: Text(
                  eventType,
                  style: TextStyle(
                    color: badge['color'] as Color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(theme.icon, color: theme.color, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      theme.label,
                      style: TextStyle(
                        color: theme.color,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2: Bill ID | Sale Amount | Time
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _InfoChip(
                  icon: RemixIcons.receipt_line,
                  label: invoiceNo.isNotEmpty ? 'CN / Inv' : 'Bill ID',
                  value: invoiceNo.isNotEmpty
                      ? '$billId\nInv: $invoiceNo'
                      : (billId.length > 14 ? '${billId.substring(0, 14)}…' : billId),
                  mono: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _InfoChip(
                  icon: RemixIcons.money_rupee_circle_line,
                  label: 'Amount',
                  value: amountStr,
                  valueColor: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _InfoChip(
                  icon: RemixIcons.time_line,
                  label: 'Time',
                  value: time,
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          // Row 3: Commission Chip (Earned or Reversed)
          if (isPositiveComm || isReversal) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isReversal
                    ? const Color(0xFFFFF1F2)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isReversal
                      ? const Color(0xFFFECDD3)
                      : AppColors.success.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isReversal ? RemixIcons.subtract_line : RemixIcons.coin_line,
                    color: isReversal ? const Color(0xFFE11D48) : AppColors.success,
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isReversal ? 'Commission Reversed' : 'Commission Earned',
                    style: TextStyle(
                      color: isReversal ? const Color(0xFFE11D48) : AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isReversal
                        ? '-₹${NumberFormat('#,##,###.##').format(commAmt.abs())}'
                        : '+₹${NumberFormat('#,##,###.##').format(commAmt)}',
                    style: TextStyle(
                      color: isReversal ? const Color(0xFFE11D48) : AppColors.success,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
);
  }
}

// ── _InfoChip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool mono;
  final CrossAxisAlignment align;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.mono = false,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final rowAlign = align == CrossAxisAlignment.end
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Row(
          mainAxisAlignment: rowAlign,
          children: [
            Icon(icon, size: 10, color: AppColors.textHint),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            fontFamily: mono ? 'monospace' : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── _StatusTheme ──────────────────────────────────────────────────────────────

class _StatusTheme {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatusTheme(this.label, this.color, this.bg, this.icon);
}
