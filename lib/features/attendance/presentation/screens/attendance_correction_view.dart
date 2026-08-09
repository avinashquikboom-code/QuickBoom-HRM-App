import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:remixicon/remixicon.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/storage_service.dart';

class AttendanceCorrectionView extends StatefulWidget {
  const AttendanceCorrectionView({super.key});

  @override
  State<AttendanceCorrectionView> createState() => _AttendanceCorrectionViewState();
}

class _AttendanceCorrectionViewState extends State<AttendanceCorrectionView> {
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 1));
  final String _currentStatus = 'ABSENT';
  String _requestedStatus = 'PRESENT';
  final TextEditingController _reasonController = TextEditingController();

  XFile? _pickedFile;
  bool _isLoadingRequests = true;
  bool _isSubmitting = false;
  String _statusFilter = 'ALL';
  List<dynamic> _myRequests = [];
  String? _errorMessage;

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchMyRequests(showLoading: true);
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _fetchMyRequests(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyRequests({bool showLoading = true}) async {
    if (showLoading && _myRequests.isEmpty) {
      setState(() {
        _isLoadingRequests = true;
        _errorMessage = null;
      });
    }
    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final url = '${AppUrl.baseUrl}/api/mobile/attendance/my-corrections${_statusFilter != 'ALL' ? '?status=$_statusFilter' : ''}';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['success'] == true) {
          final newRequests = data['requests'] ?? data['data'] ?? [];
          if (mounted) {
            setState(() {
              _myRequests = newRequests is List ? List.from(newRequests) : [];
              _errorMessage = null;
            });
          }
        }
      } else if (response.statusCode == 403) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _errorMessage = (data is Map ? data['error'] : null) ?? 'Permission denied (403): HR must enable "Request Attendance Correction" permission.';
          });
        }
      } else if (response.statusCode == 500) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Server error (500): Failed to load correction requests.';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load correction requests (${response.statusCode}).';
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _errorMessage = 'Loading timed out (> 5s). Please check network and retry.';
        });
      }
    } catch (e) {
      debugPrint('Error fetching my correction requests: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading correction requests: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _pickDocument() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        setState(() {
          _pickedFile = file;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _submitRequest() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a mandatory reason for correction'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    // Validate 30 days limit
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    if (_selectedDate.isBefore(DateTime(thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance corrections can only be requested for dates within the past 30 days.'), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final token = await StorageService.getToken();

      String? supportingDocUrl;
      final file = _pickedFile;
      if (file != null) {
        final bytes = await file.readAsBytes();
        supportingDocUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      final response = await http.post(
        Uri.parse('${AppUrl.baseUrl}/api/mobile/attendance/correction-request'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'attendanceDate': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'currentStatus': _currentStatus,
          'requestedStatus': _requestedStatus,
          'reason': reason,
          'supportingDoc': supportingDocUrl,
        }),
      ).timeout(const Duration(seconds: 5));

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data is Map && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request submitted. HR will review within 24 hours.'), backgroundColor: AppColors.success),
          );
        }
        _reasonController.clear();
        setState(() => _pickedFile = null);
        _fetchMyRequests();
      } else {
        final errMsg = data is Map ? (data['error'] ?? data['message']) : null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errMsg ?? 'Failed to submit request'), backgroundColor: AppColors.error),
          );
        }
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission timed out (> 5s). Please check network and retry.'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting request: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDate() async {
    final DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: thirtyDaysAgo,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showDetailModal(dynamic req) {
    if (req == null || req is! Map) return;
    final status = req['status']?.toString() ?? 'PENDING';
    String dateStr = '';
    if (req['attendanceDate'] != null) {
      final parsed = DateTime.tryParse(req['attendanceDate'].toString());
      if (parsed != null) {
        dateStr = DateFormat('EEEE, dd MMM yyyy').format(parsed);
      }
    }

    String appliedDateStr = '';
    if (req['appliedOn'] != null) {
      final parsed = DateTime.tryParse(req['appliedOn'].toString());
      if (parsed != null) {
        appliedDateStr = DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
      }
    }

    final docUrl = req['supportingDoc']?.toString();
    final currentSt = req['currentStatus']?.toString() ?? 'ABSENT';
    final requestedSt = req['requestedStatus']?.toString() ?? 'PRESENT';
    final reasonText = req['reason']?.toString() ?? 'No reason provided';
    final reviewNoteText = req['reviewNote']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
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
                  Expanded(
                    child: Text(
                      'Correction Detail',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(RemixIcons.refresh_line),
                        tooltip: 'Refresh',
                        onPressed: () {
                          _fetchMyRequests(showLoading: false);
                          Navigator.pop(ctx);
                        },
                      ),
                      IconButton(icon: const Icon(RemixIcons.close_line), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ],
              ),
              const Divider(),

              Text('Date: $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Current Record: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Flexible(
                    child: Text(
                      currentSt,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Requested: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Flexible(
                    child: Text(
                      requestedSt,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Text(reasonText, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 14),

              if (docUrl != null && docUrl.isNotEmpty) ...[
                const Text('Supporting Document:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    try {
                      final uri = Uri.parse(docUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    } catch (e) {
                      debugPrint('Error launching doc url: $e');
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
                            docUrl.split('/').last,
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

              Text('Status: $status', style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(status))),
              const SizedBox(height: 2),
              Text('Applied On: $appliedDateStr', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),

              if (reviewNoteText != null && reviewNoteText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text('HR Review Note: $reviewNoteText', style: TextStyle(fontSize: 12, color: Colors.red.shade900)),
                ),
              ],

              const SizedBox(height: 20),

              if (status.toUpperCase() == 'REJECTED')
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    icon: const Icon(RemixIcons.refresh_line, color: Colors.white, size: 16),
                    label: const Text('Resubmit Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (req['attendanceDate'] != null) {
                        final parsed = DateTime.tryParse(req['attendanceDate'].toString());
                        if (parsed != null) {
                          setState(() => _selectedDate = parsed);
                        }
                      }
                      setState(() {
                        _reasonController.text = req['reason']?.toString() ?? '';
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  List<dynamic> get _filteredMyRequests {
    final list = _myRequests;
    if (_statusFilter == 'ALL') return list;
    return list.where((r) {
      if (r == null || r is! Map) return false;
      return r['status']?.toString().toUpperCase() == _statusFilter.toUpperCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentError = _errorMessage;
    final filteredList = _filteredMyRequests;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Attendance Correction',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(RemixIcons.refresh_line, color: AppColors.textPrimary),
            tooltip: 'Refresh',
            onPressed: () => _fetchMyRequests(showLoading: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _fetchMyRequests(showLoading: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // New Request Form Card
                      Card(
                        elevation: 2,
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(RemixIcons.edit_box_line, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Request Correction',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Screen 1: Date Picker Field
                              InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    border: Border.all(color: AppColors.inputBorder),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Select Date (Past 30 Days Only):',
                                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(RemixIcons.calendar_event_line, color: AppColors.primary),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Screen 2: Current Status & What to Correct to
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                                child: Row(
                                  children: [
                                    Text('Current Status: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Expanded(
                                      child: Text(
                                        _currentStatus,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              Text(
                                'What do you want to correct it to?',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Present (Full Day)'),
                                    selected: _requestedStatus == 'PRESENT',
                                    selectedColor: Colors.green.shade100,
                                    labelStyle: TextStyle(color: _requestedStatus == 'PRESENT' ? Colors.green.shade900 : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                                    onSelected: (val) {
                                      if (val) setState(() => _requestedStatus = 'PRESENT');
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Half Day'),
                                    selected: _requestedStatus == 'HALF_DAY',
                                    selectedColor: Colors.blue.shade100,
                                    labelStyle: TextStyle(color: _requestedStatus == 'HALF_DAY' ? Colors.blue.shade900 : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                                    onSelected: (val) {
                                      if (val) setState(() => _requestedStatus = 'HALF_DAY');
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Late'),
                                    selected: _requestedStatus == 'LATE',
                                    selectedColor: Colors.orange.shade100,
                                    labelStyle: TextStyle(color: _requestedStatus == 'LATE' ? Colors.orange.shade900 : AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                                    onSelected: (val) {
                                      if (val) setState(() => _requestedStatus = 'LATE');
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Reason Text Field (Mandatory)
                              TextField(
                                controller: _reasonController,
                                maxLines: 3,
                                style: TextStyle(color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Reason (mandatory)',
                                  labelStyle: TextStyle(color: AppColors.textSecondary),
                                  hintText: 'Was sick, attended from home. Doctor note attached.',
                                  hintStyle: TextStyle(color: AppColors.textHint),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Upload Supporting Doc
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text('Supporting Doc (optional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: _pickDocument,
                                    icon: const Icon(RemixIcons.attachment_line, size: 14),
                                    label: Text(_pickedFile != null ? 'Change Doc' : '+ Add Photo / Doc', style: const TextStyle(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  ),
                                ],
                              ),
                              if (_pickedFile != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    children: [
                                      Icon(RemixIcons.file_text_line, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(_pickedFile?.name ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
                                      IconButton(
                                        icon: const Icon(RemixIcons.close_circle_line, size: 16, color: Colors.red),
                                        onPressed: () => setState(() => _pickedFile = null),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 18),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submitRequest,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // My Correction Requests List & Filters
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('My Correction Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                          ),
                          const SizedBox(width: 8),
                          Text('${filteredList.length} Items', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Filter Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: ['ALL', 'PENDING', 'APPROVED', 'REJECTED'].map((st) {
                          final isSelected = _statusFilter == st;
                          return ChoiceChip(
                            label: Text(st, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold)),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            onSelected: (val) {
                              if (val) {
                                setState(() => _statusFilter = st);
                                _fetchMyRequests(showLoading: true);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              if (_isLoadingRequests)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (currentError != null && currentError.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      color: Colors.red.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(RemixIcons.error_warning_line, color: Colors.red.shade700, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              currentError,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _fetchMyRequests(showLoading: true),
                              icon: const Icon(RemixIcons.refresh_line, size: 16, color: Colors.white),
                              label: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else if (filteredList.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: Card(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(RemixIcons.inbox_line, size: 36, color: AppColors.textSecondary),
                              const SizedBox(height: 8),
                              Text(
                                'No corrections yet.',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Use the form above to submit an attendance correction request.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < 0 || index >= filteredList.length) return null;
                        final req = filteredList[index];
                        if (req == null || req is! Map) return const SizedBox.shrink();

                        final status = req['status']?.toString() ?? 'PENDING';
                        String dateStr = '';
                        if (req['attendanceDate'] != null) {
                          final parsed = DateTime.tryParse(req['attendanceDate'].toString());
                          if (parsed != null) {
                            dateStr = DateFormat('dd MMM yyyy').format(parsed);
                          }
                        }

                        final currentSt = req['currentStatus']?.toString() ?? 'ABSENT';
                        final requestedSt = req['requestedStatus']?.toString() ?? 'PRESENT';
                        final reasonText = req['reason']?.toString();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            onTap: () => _showDetailModal(req),
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(status).withValues(alpha: 0.15),
                              child: Icon(
                                status.toUpperCase() == 'APPROVED'
                                    ? RemixIcons.checkbox_circle_line
                                    : status.toUpperCase() == 'REJECTED'
                                        ? RemixIcons.close_circle_line
                                        : RemixIcons.time_line,
                                color: _getStatusColor(status),
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    dateStr,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '$currentSt → $requestedSt',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                                ),
                                if (reasonText != null && reasonText.isNotEmpty)
                                  Text(
                                    'Reason: $reasonText',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            trailing: Icon(RemixIcons.arrow_right_s_line, size: 18, color: AppColors.textSecondary),
                          ),
                        );
                      },
                      childCount: filteredList.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}
