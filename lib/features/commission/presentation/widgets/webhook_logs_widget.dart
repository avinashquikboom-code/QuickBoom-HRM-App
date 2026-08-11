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

  @override
  void initState() {
    super.initState();
    _fetchLogs();
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
            Uri.parse('${AppUrl.baseUrl}${AppUrl.webhookLogs}?limit=10'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Full webhook logs available in the Admin Panel'),
                    behavior: SnackBarBehavior.floating,
                  ),
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

  @override
  Widget build(BuildContext context) {
    final theme = statusTheme(log['status'] as String?);
    final billId = (log['billId'] ?? '—').toString();
    final amount = log['amount'];
    final amountStr = amount == null
        ? '—'
        : '₹${NumberFormat('#,##,###').format((amount as num).toDouble())}';
    final eventType = (log['eventType'] ?? '—').toString();
    final time = formatTime(log['createdAt'] as String?);

    return Container(
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
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  eventType,
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
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
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _InfoChip(
                  icon: RemixIcons.receipt_line,
                  label: 'Bill ID',
                  value: billId.length > 14 ? '${billId.substring(0, 14)}…' : billId,
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
                  valueColor: AppColors.success,
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
        ],
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
