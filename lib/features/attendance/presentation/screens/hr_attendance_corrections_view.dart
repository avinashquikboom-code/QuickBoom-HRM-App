import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:remixicon/remixicon.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';

class HRAttendanceCorrectionsView extends StatefulWidget {
  const HRAttendanceCorrectionsView({super.key});

  @override
  State<HRAttendanceCorrectionsView> createState() => _HRAttendanceCorrectionsViewState();
}

class _HRAttendanceCorrectionsViewState extends State<HRAttendanceCorrectionsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isExporting = false;
  List<dynamic> _allRequests = [];

  String _statusFilter = 'ALL';
  String _searchQuery = '';
  final DateTimeRange? _selectedDateRange = null;

  final Set<String> _selectedRequestIds = {};
  bool _isBulkActionLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _fetchRequests();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchRequests() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) return;

      final queryParams = <String>[];
      if (_statusFilter != 'ALL') queryParams.add('status=$_statusFilter');
      if (_selectedDateRange != null) {
        queryParams.add('from=${DateFormat('yyyy-MM-dd').format(_selectedDateRange.start)}');
        queryParams.add('to=${DateFormat('yyyy-MM-dd').format(_selectedDateRange.end)}');
      }

      final urlStr = '${AppUrl.baseUrl}/api/hr/attendance/correction-requests${queryParams.isNotEmpty ? '?${queryParams.join('&')}' : ''}';
      final response = await http.get(
        Uri.parse(urlStr),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          setState(() {
            _allRequests = body['data'] ?? body['requests'] ?? [];
            _selectedRequestIds.clear();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching HR correction requests: $e');
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final token = await ApiService.getToken();
      if (token == null) return;

      final exportUrl = Uri.parse('${AppUrl.baseUrl}/api/hr/attendance/correction-requests/export?token=$token');
      if (await canLaunchUrl(exportUrl)) {
        await launchUrl(exportUrl, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exporting corrections CSV...')),
          );
        }
      } else {
        throw Exception('Could not open export URL.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  List<dynamic> get _filteredRequests {
    return _allRequests.where((r) {
      final matchesStatus = _statusFilter == 'ALL' || r['status'] == _statusFilter;
      final name = (r['employeeName'] ?? '').toString().toLowerCase();
      final code = (r['employeeId'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty || name.contains(query) || code.contains(query);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  Future<void> _showReviewModal(dynamic req) async {
    final status = req['status'] ?? 'PENDING';
    String decision = status == 'REJECTED' ? 'REJECTED' : 'APPROVED';
    final noteController = TextEditingController(text: req['reviewNote'] ?? '');
    DateTime effectDate = DateTime.now();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final docUrl = req['supportingDoc'];
          final dateStr = req['attendanceDate'] != null
              ? DateFormat('EEEE, dd MMM yyyy').format(DateTime.parse(req['attendanceDate']))
              : '';
          final appliedDateStr = req['appliedOn'] != null
              ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(req['appliedOn']))
              : '';

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(modalCtx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Correction Review',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(RemixIcons.close_line),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const Divider(),

                  Text('Employee: ${req['employeeName']} (${req['employeeId']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Date: $dateStr', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Current', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(req['currentStatus'] ?? 'ABSENT', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                        const Icon(RemixIcons.arrow_right_line, color: Colors.grey),
                        Column(
                          children: [
                            const Text('Requested', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(req['requestedStatus'] ?? 'PRESENT', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(req['reason'] ?? 'No reason provided', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 14),

                  if (docUrl != null && docUrl.toString().isNotEmpty) ...[
                    const Text('Supporting Document:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse(docUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(RemixIcons.file_text_line, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                docUrl.toString().split('/').last,
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(RemixIcons.external_link_line, size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  Text('Applied On: $appliedDateStr', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 16),

                  if (status == 'PENDING') ...[
                    const Text('Decision:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('APPROVE')),
                            selected: decision == 'APPROVED',
                            selectedColor: Colors.green.shade100,
                            labelStyle: TextStyle(color: decision == 'APPROVED' ? Colors.green.shade800 : Colors.black, fontWeight: FontWeight.bold),
                            onSelected: (val) {
                              if (val) setModalState(() => decision = 'APPROVED');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('REJECT')),
                            selected: decision == 'REJECTED',
                            selectedColor: Colors.red.shade100,
                            labelStyle: TextStyle(color: decision == 'REJECTED' ? Colors.red.shade800 : Colors.black, fontWeight: FontWeight.bold),
                            onSelected: (val) {
                              if (val) setModalState(() => decision = 'REJECTED');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Review Note (optional)',
                        hintText: decision == 'APPROVED' ? 'Valid doctor note / reason' : 'No document attached',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: decision == 'APPROVED' ? Colors.green : Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setModalState(() => isSubmitting = true);
                                try {
                                  final token = await ApiService.getToken();
                                  final res = await http.patch(
                                    Uri.parse('${AppUrl.baseUrl}/api/hr/attendance/correction-requests/${req['id']}'),
                                    headers: {
                                      'Authorization': 'Bearer $token',
                                      'Content-Type': 'application/json',
                                    },
                                    body: json.encode({
                                      'status': decision,
                                      'reviewNote': noteController.text.trim(),
                                      'approvalEffectDate': effectDate.toIso8601String(),
                                    }),
                                  );

                                  final body = json.decode(res.body);
                                  if (res.statusCode == 200 && body['success'] == true) {
                                    if (modalCtx.mounted) {
                                      Navigator.pop(modalCtx);
                                    }
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Correction $decision successfully!')),
                                      );
                                    }
                                    _loadData();
                                  } else {
                                    if (modalCtx.mounted) {
                                      ScaffoldMessenger.of(modalCtx).showSnackBar(
                                        SnackBar(content: Text(body['error'] ?? 'Review failed')),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  debugPrint('Error reviewing correction: $e');
                                } finally {
                                  if (modalCtx.mounted) setModalState(() => isSubmitting = false);
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('Submit $decision', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: status == 'APPROVED' ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reviewed Status: $status', style: TextStyle(fontWeight: FontWeight.bold, color: status == 'APPROVED' ? Colors.green.shade800 : Colors.red.shade800)),
                          if (req['reviewedBy'] != null) Text('Reviewed By: ${req['reviewedBy']}', style: const TextStyle(fontSize: 12)),
                          if (req['reviewNote'] != null) Text('Note: ${req['reviewNote']}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _performBulkReview(String status) async {
    if (_selectedRequestIds.isEmpty) return;

    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Bulk $status Requests'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to $status ${_selectedRequestIds.length} pending correction requests?'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Review Note for All (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: status == 'APPROVED' ? Colors.green : Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirm $status', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBulkActionLoading = true);
    try {
      final token = await ApiService.getToken();
      final res = await http.post(
        Uri.parse('${AppUrl.baseUrl}/api/hr/attendance/correction-requests/bulk-review'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'ids': _selectedRequestIds.toList(),
          'status': status,
          'reviewNote': noteController.text.trim(),
        }),
      );

      final body = json.decode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${body['processedCount']} requests $status successfully!')),
          );
        }
        _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(body['error'] ?? 'Bulk action failed'), backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
      debugPrint('Error performing bulk review: $e');
    } finally {
      if (mounted) setState(() => _isBulkActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _allRequests.where((r) => r['status'] == 'PENDING').length;
    final approvedCount = _allRequests.where((r) => r['status'] == 'APPROVED').length;
    final rejectedCount = _allRequests.where((r) => r['status'] == 'REJECTED').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance Corrections'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Icon(RemixIcons.file_excel_line, color: AppColors.primary),
            onPressed: _isExporting ? null : _exportCsv,
            tooltip: 'Export Report',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(text: 'Overview'),
            Tab(text: 'Requests (${_filteredRequests.length})'),
            const Tab(text: 'Audit Log'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // ── Tab 1: Dashboard Overview ─────────────────────────────
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppColors.heroGradient,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Attendance Corrections Dashboard',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: _StatBox(label: 'Total', count: _allRequests.length, color: Colors.white)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _StatBox(label: 'Pending', count: pendingCount, color: AppColors.warning)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _StatBox(label: 'Approved', count: approvedCount, color: AppColors.success)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _StatBox(label: 'Rejected', count: rejectedCount, color: AppColors.error)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text('Recent Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Resolution Rate', style: TextStyle(fontWeight: FontWeight.w600)),
                                    Text(
                                      '${_allRequests.isNotEmpty ? ((approvedCount + rejectedCount) * 100 / _allRequests.length).toStringAsFixed(1) : 0}%',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: _allRequests.isNotEmpty ? ((approvedCount + rejectedCount) / _allRequests.length) : 0.0,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Tab 2: Requests List & Bulk Actions ────────────────────
                Column(
                  children: [
                    // Search & Filters Header
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search by employee name or code...',
                              prefixIcon: const Icon(RemixIcons.search_line),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: ['ALL', 'PENDING', 'APPROVED', 'REJECTED'].map((st) {
                                      final isSelected = _statusFilter == st;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: ChoiceChip(
                                          label: Text(st, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                          selected: isSelected,
                                          selectedColor: AppColors.primary,
                                          onSelected: (val) {
                                            if (val) {
                                              setState(() => _statusFilter = st);
                                              _fetchRequests();
                                            }
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Bulk actions toolbar if items selected
                    if (_selectedRequestIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_selectedRequestIds.length} Selected', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                                  onPressed: _isBulkActionLoading ? null : () => _performBulkReview('APPROVED'),
                                  child: const Text('Approve Selected', style: TextStyle(fontSize: 12, color: Colors.white)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                                  onPressed: _isBulkActionLoading ? null : () => _performBulkReview('REJECTED'),
                                  child: const Text('Reject Selected', style: TextStyle(fontSize: 12, color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // Requests list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchRequests,
                        child: _filteredRequests.isEmpty
                            ? const Center(child: Text('No correction requests found.'))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                itemCount: _filteredRequests.length,
                                itemBuilder: (context, idx) {
                                  final req = _filteredRequests[idx];
                                  final reqId = req['id'].toString();
                                  final isPending = req['status'] == 'PENDING';
                                  final isChecked = _selectedRequestIds.contains(reqId);
                                  final dateStr = req['attendanceDate'] != null
                                      ? DateFormat('dd MMM yyyy').format(DateTime.parse(req['attendanceDate']))
                                      : '';

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      leading: isPending
                                          ? Checkbox(
                                              value: isChecked,
                                              onChanged: (val) {
                                                setState(() {
                                                  if (val == true) {
                                                    _selectedRequestIds.add(reqId);
                                                  } else {
                                                    _selectedRequestIds.remove(reqId);
                                                  }
                                                });
                                              },
                                            )
                                          : const Icon(RemixIcons.file_list_3_line, color: AppColors.primary),
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              req['employeeName'] ?? req['employeeId'],
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _StatusChip(status: req['status'] ?? 'PENDING'),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text('Date: $dateStr  •  ${req['currentStatus']} → ${req['requestedStatus']}', style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                                          if (req['reason'] != null) Text('Reason: ${req['reason']}', style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                      trailing: TextButton(
                                        onPressed: () => _showReviewModal(req),
                                        child: Text(isPending ? 'Review' : 'View'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),

                // ── Tab 3: History & Audit Log ────────────────────────────
                ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _allRequests.length,
                  itemBuilder: (context, idx) {
                    final req = _allRequests[idx];
                    final appliedDateStr = req['appliedOn'] != null
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(req['appliedOn']))
                        : '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${req['employeeName']} (${req['employeeId']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('Action: ${req['status']} by ${req['reviewedBy'] ?? 'System'} on $appliedDateStr\nNote: ${req['reviewNote'] ?? 'None'}', style: const TextStyle(fontSize: 11)),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBox({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.orange.shade100;
    Color fg = Colors.orange.shade900;
    if (status == 'APPROVED') {
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
    } else if (status == 'REJECTED') {
      bg = Colors.red.shade100;
      fg = Colors.red.shade900;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
