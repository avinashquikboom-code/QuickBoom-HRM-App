import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/storage_service.dart';
import 'package:quickboom_hrm/core/services/notification_service.dart';

class HRBankEditRequestsView extends StatefulWidget {
  const HRBankEditRequestsView({super.key});

  @override
  State<HRBankEditRequestsView> createState() => _HRBankEditRequestsViewState();
}

class _HRBankEditRequestsViewState extends State<HRBankEditRequestsView> {
  bool _isLoading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final res = await http.get(
        Uri.parse('${AppUrl.baseUrl}/api/admin/bank-edit-requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            _requests = data['requests'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching bank edit requests: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _decideRequest(int requestId, String action) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final res = await http.post(
        Uri.parse('${AppUrl.baseUrl}/api/admin/bank-edit-requests/$requestId/action'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'action': action}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Request updated successfully.'),
              backgroundColor: action == 'APPROVED' ? AppColors.success : AppColors.error,
            ),
          );
          NotificationService().showLocalNotification(
            title: 'Bank Edit Request ${action == 'APPROVED' ? 'Approved' : 'Rejected'}',
            body: 'Action completed for bank account edit request.',
          );
          _fetchRequests();
        }
      }
    } catch (e) {
      debugPrint('Error deciding request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Edit Requests'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _requests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(RemixIcons.bank_card_line, size: 48, color: cs.onSurface.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'No bank edit requests found',
                        style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final item = _requests[index];
                      final status = item['status'] ?? 'PENDING';
                      final isPending = status == 'PENDING';

                      Color statusColor = const Color(0xFFF59E0B);
                      if (status == 'APPROVED' || status == 'COMPLETED') statusColor = AppColors.success;
                      if (status == 'REJECTED') statusColor = AppColors.error;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        color: cs.surfaceContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['employeeName'] ?? 'Employee',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item['employeeCode']} • ${item['department']}',
                                style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
                              ),
                              if (item['reason'] != null && item['reason'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Reason: ${item['reason']}',
                                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: cs.onSurface.withValues(alpha: 0.8)),
                                ),
                              ],
                              const SizedBox(height: 12),
                              if (isPending) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _decideRequest(item['id'], 'REJECTED'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: const BorderSide(color: AppColors.error),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _decideRequest(item['id'], 'APPROVED'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Approve', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
