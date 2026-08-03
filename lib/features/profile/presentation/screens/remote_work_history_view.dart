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

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.cardBorder),
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
                                    const Icon(RemixIcons.calendar_event_line, size: 16, color: AppColors.info),
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
                                        Icon(RemixIcons.chat_1_line, size: 14, color: AppColors.textHint),
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
                          );
                        },
                      ),
      ),
    );
  }
}
