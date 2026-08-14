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
import 'package:quickboom_hrm/screens/commission/commission_detail_screen.dart';

class WebhookLogsScreen extends StatefulWidget {
  const WebhookLogsScreen({super.key});

  @override
  State<WebhookLogsScreen> createState() => _WebhookLogsScreenState();
}

class _WebhookLogsScreenState extends State<WebhookLogsScreen> with WidgetsBindingObserver {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedFilter = 'All';

  Timer? _timer;
  StreamSubscription? _commissionSub;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchLogs();
    // Auto refresh every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _silentRefresh());
    // Auto refresh on WebSocket events
    _commissionSub = WebSocketService().commissionUpdates.listen((_) {
      _silentRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _silentRefresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _commissionSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final token = await StorageService.getToken();
      if (token == null) return;
      final response = await http
          .get(
            Uri.parse('${AppUrl.baseUrl}${AppUrl.mobileWebhookLogs}?limit=50'),
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
      dev.log('Webhook silent refresh error: $e', name: 'WebhookLogsScreen');
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
        if (mounted) {
          setState(() {
            _loading = false;
            _hasError = true;
            _errorMessage = 'Authentication token not found';
          });
        }
        return;
      }
      final response = await http
          .get(
            Uri.parse('${AppUrl.baseUrl}${AppUrl.mobileWebhookLogs}?limit=50'),
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
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Server error (${response.statusCode})';
        });
      }
    } catch (e) {
      dev.log('Fetch webhook logs exception: $e', name: 'WebhookLogsScreen');
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Failed to load webhook logs';
        });
      }
    }
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _logs.where((log) {
      final billId = (log['billId'] ?? '').toString().toLowerCase();
      final invoiceNo = (log['invoiceNo'] ?? '').toString().toLowerCase();
      final customer = (log['customerName'] ?? '').toString().toLowerCase();
      final eventType = (log['eventType'] ?? '').toString().toUpperCase();

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = billId.contains(q) || invoiceNo.contains(q) || customer.contains(q) || eventType.contains(q);
        if (!match) return false;
      }

      if (_selectedFilter == 'INVOICE' && !eventType.contains('INVOICE')) {
        return false;
      }
      if (_selectedFilter == 'CREDIT NOTE' && !eventType.contains('CREDIT_NOTE')) {
        return false;
      }
      if (_selectedFilter == 'EXCHANGE' && !eventType.contains('EXCHANGE')) {
        return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Webhook Activity Logs',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(RemixIcons.refresh_line, color: AppColors.textPrimary),
            onPressed: _fetchLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by bill, invoice, or customer...',
                  hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                  prefixIcon: Icon(RemixIcons.search_line, color: AppColors.textSecondary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(RemixIcons.close_line, color: AppColors.textSecondary, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),
          ),

          // Filter Chips
          Container(
            height: 38,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'INVOICE', 'CREDIT NOTE', 'EXCHANGE'].map((f) {
                final isSelected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = f);
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 12,
                    ),
                    elevation: isSelected ? 2 : 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : AppColors.cardBorder,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Logs List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchLogs,
              color: AppColors.primary,
              child: _buildBody(filteredLogs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> logs) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(RemixIcons.error_warning_line, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(_errorMessage, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchLogs,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(RemixIcons.webhook_line, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              'No webhook events match your filter',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final eventType = (log['eventType'] ?? 'INVOICE_CREATED').toString();
        final billId = (log['billId'] ?? '—').toString();
        final invoiceNo = (log['invoiceNo'] ?? '').toString();
        final customer = (log['customerName'] ?? '—').toString();
        final amount = (log['amount'] as num?)?.toDouble() ?? 0.0;
        final commission = (log['commissionAmount'] as num?)?.toDouble() ?? 0.0;
        final createdAt = _formatTime(log['createdAt'] as String?);
        final status = (log['status'] ?? 'SUCCESS').toString();

        final isCreditNote = eventType.toUpperCase().contains('CREDIT_NOTE');
        final isExchange = eventType.toUpperCase().contains('EXCHANGE');

        Color cardBg = AppColors.surface;
        Color badgeColor = AppColors.primary;
        if (isCreditNote) {
          badgeColor = AppColors.error;
        } else if (isExchange) {
          badgeColor = Colors.purple;
        }

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
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      eventType,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'SUCCESS'
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: status == 'SUCCESS' ? AppColors.success : AppColors.error,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bill ID: $billId',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (invoiceNo.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Invoice: $invoiceNo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          'Customer: $customer',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${NumberFormat('#,##,###.00').format(amount)}',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCreditNote
                            ? '-₹${NumberFormat('#,##,###.00').format(commission.abs())}'
                            : '+₹${NumberFormat('#,##,###.00').format(commission)}',
                        style: TextStyle(
                          color: isCreditNote ? AppColors.error : AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: AppColors.cardBorder, height: 1),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(RemixIcons.time_line, size: 12, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        createdAt,
                        style: TextStyle(color: AppColors.textHint, fontSize: 10.5),
                      ),
                    ],
                  ),
                  Text(
                    'Live POS Stream',
                    style: TextStyle(color: AppColors.primary, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        ).animate(delay: (index * 40).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
      },
    );
  }
}
