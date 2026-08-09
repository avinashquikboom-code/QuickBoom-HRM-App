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
import 'package:quickboom_hrm/features/attendance/presentation/screens/attendance_correction_history_view.dart';

// ─── Color helpers ────────────────────────────────────────────────────────────

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

// ─── Robust date parser ───────────────────────────────────────────────────────

/// Parses any JSON date value to local DateTime.
/// Handles: ISO 8601 with/without TZ, date-only strings, Unix ms ints.
/// Never throws; returns null for unparseable input.
DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw).toLocal();
  final str = raw.toString().trim();
  if (str.isEmpty) return null;
  final dt = DateTime.tryParse(str);
  if (dt != null) return dt.toLocal();
  // Fallback: strip trailing timezone and retry
  final stripped = str.replaceAll(RegExp(r'[Z+].*$'), '');
  return DateTime.tryParse(stripped)?.toLocal();
}

// ─── Main Widget ──────────────────────────────────────────────────────────────

class AttendanceCorrectionView extends StatefulWidget {
  const AttendanceCorrectionView({super.key});

  @override
  State<AttendanceCorrectionView> createState() =>
      _AttendanceCorrectionViewState();
}

class _AttendanceCorrectionViewState extends State<AttendanceCorrectionView>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate =
      DateTime.now().subtract(const Duration(days: 1));
  final String _currentStatus = 'ABSENT';
  String _requestedStatus = 'PRESENT';
  final TextEditingController _reasonController = TextEditingController();

  XFile? _pickedFile;
  bool _isLoadingRequests = true;
  bool _isSubmitting = false;
  List<dynamic> _myRequests = [];

  Timer? _pollingTimer;
  late final AnimationController _formAnimCtrl;
  late final Animation<double> _formFade;

  @override
  void initState() {
    super.initState();
    _formAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _formFade = CurvedAnimation(parent: _formAnimCtrl, curve: Curves.easeOut);
    _formAnimCtrl.forward();

    _fetchMyRequests(showLoading: true);
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _fetchMyRequests(showLoading: false);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _reasonController.dispose();
    _formAnimCtrl.dispose();
    super.dispose();
  }

  // ─── Network ────────────────────────────────────────────────────────────────

  Future<void> _fetchMyRequests({bool showLoading = true}) async {
    if (showLoading && _myRequests.isEmpty) {
      setState(() => _isLoadingRequests = true);
    }
    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final url =
          '${AppUrl.baseUrl}/api/mobile/attendance/my-corrections';
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
              _myRequests =
                  newRequests is List ? List.from(newRequests) : [];
            });
          }
        }
      } else if (response.statusCode == 403) {
        final data = json.decode(response.body);
        _showSnack(
          (data is Map ? data['error'] : null) ??
              'Permission denied: HR must enable correction requests.',
          isError: true,
        );
      } else {
        _showSnack(
            'Failed to load requests (${response.statusCode}).',
            isError: true);
      }
    } on TimeoutException {
      _showSnack('Loading timed out. Please retry.', isError: true);
    } catch (e) {
      debugPrint('Error fetching correction requests: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _pickDocument() async {
    try {
      final picker = ImagePicker();
      final XFile? file =
          await picker.pickImage(source: ImageSource.gallery);
      if (file != null) setState(() => _pickedFile = file);
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _submitRequest() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      _showSnack('Please enter a mandatory reason for correction',
          isError: true);
      return;
    }
    final thirtyDaysAgo =
        DateTime.now().subtract(const Duration(days: 30));
    if (_selectedDate.isBefore(DateTime(
        thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day))) {
      _showSnack(
          'Corrections can only be requested within the past 30 days.',
          isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final token = await StorageService.getToken();
      String? supportingDocUrl;
      final file = _pickedFile;
      if (file != null) {
        final bytes = await file.readAsBytes();
        supportingDocUrl =
            'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      final response = await http
          .post(
            Uri.parse(
                '${AppUrl.baseUrl}/api/mobile/attendance/correction-request'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'attendanceDate':
                  DateFormat('yyyy-MM-dd').format(_selectedDate),
              'currentStatus': _currentStatus,
              'requestedStatus': _requestedStatus,
              'reason': reason,
              'supportingDoc': supportingDocUrl,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = json.decode(response.body);
      if (response.statusCode == 200 &&
          data is Map &&
          data['success'] == true) {
        _showSnack('Request submitted! HR will review within 24 hours.');
        _reasonController.clear();
        setState(() => _pickedFile = null);
        _fetchMyRequests();
      } else {
        final errMsg =
            data is Map ? (data['error'] ?? data['message']) : null;
        _showSnack(errMsg ?? 'Failed to submit request', isError: true);
      }
    } on TimeoutException {
      _showSnack('Submission timed out. Please retry.', isError: true);
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDate() async {
    final thirtyDaysAgo =
        DateTime.now().subtract(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: thirtyDaysAgo,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

  // ─── Detail Modal ────────────────────────────────────────────────────────────

  void _showDetailModal(dynamic req) {
    if (req == null || req is! Map) return;
    final status = req['status']?.toString() ?? 'PENDING';
    String dateStr = '';
    if (req['attendanceDate'] != null) {
      final parsed = _parseDate(req['attendanceDate']);
      if (parsed != null) {
        dateStr = DateFormat('EEEE, dd MMM yyyy').format(parsed);
      }
    }
    String appliedDateStr = '';
    if (req['appliedOn'] != null) {
      final parsed = _parseDate(req['appliedOn']);
      if (parsed != null) {
        appliedDateStr = DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
      }
    }

    final docUrl = req['supportingDoc']?.toString();
    final currentSt = req['currentStatus']?.toString() ?? 'ABSENT';
    final requestedSt = req['requestedStatus']?.toString() ?? 'PRESENT';
    final reasonText = req['reason']?.toString() ?? 'No reason provided';
    final reviewNoteText = req['reviewNote']?.toString();
    final color = _statusColor(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Status banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(_statusIcon(status), color: color, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(status,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: color)),
                          Text('Applied: $appliedDateStr',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(RemixIcons.refresh_line,
                              color: AppColors.textSecondary, size: 18),
                          onPressed: () {
                            _fetchMyRequests(showLoading: false);
                            Navigator.pop(ctx);
                          },
                        ),
                        IconButton(
                          icon: Icon(RemixIcons.close_line,
                              color: AppColors.textSecondary, size: 18),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Date
              _DetailRow(
                  icon: RemixIcons.calendar_2_line,
                  label: 'Date',
                  value: dateStr),
              const SizedBox(height: 12),

              // Current → Requested
              Row(
                children: [
                  Expanded(
                    child: _StatusPill(
                        label: 'Current',
                        value: currentSt,
                        color: AppColors.error),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(RemixIcons.arrow_right_line,
                        color: AppColors.textHint, size: 18),
                  ),
                  Expanded(
                    child: _StatusPill(
                        label: 'Requested',
                        value: requestedSt,
                        color: AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reason
              Text('Reason',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(reasonText,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textPrimary)),
              ),

              // Doc
              if (docUrl != null && docUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Supporting Document',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    try {
                      final uri = Uri.parse(docUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    } catch (e) {
                      debugPrint('Error: $e');
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(RemixIcons.file_text_line,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            docUrl.split('/').last,
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(RemixIcons.external_link_line,
                            size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],

              // HR Review note
              if (reviewNoteText != null &&
                  reviewNoteText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(RemixIcons.information_line,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('HR Note: $reviewNoteText',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              if (status.toUpperCase() == 'REJECTED')
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(RemixIcons.refresh_line,
                        color: Colors.white, size: 16),
                    label: const Text('Resubmit Request',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (req['attendanceDate'] != null) {
                        final parsed = DateTime.tryParse(
                            req['attendanceDate'].toString());
                        if (parsed != null) {
                          setState(() => _selectedDate = parsed);
                        }
                      }
                      setState(() {
                        _reasonController.text =
                            req['reason']?.toString() ?? '';
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

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(),
        ],
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _fetchMyRequests(showLoading: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── My Requests Summary Card ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _MyRequestsSummaryCard(
                    requests: _myRequests,
                    isLoading: _isLoadingRequests,
                    onViewAll: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AttendanceCorrectionHistoryView(
                          requests: _myRequests,
                          onRefresh: () => _fetchMyRequests(showLoading: true),
                          onShowDetail: _showDetailModal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── New Correction Request Form ───────────────────────────────
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _formFade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: _buildFormCard(),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(RemixIcons.calendar_check_line,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Attendance Correction',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              Text('Request & track corrections',
                  style: TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(RemixIcons.refresh_line,
              color: AppColors.textSecondary, size: 20),
          tooltip: 'Refresh',
          onPressed: () => _fetchMyRequests(showLoading: true),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.06),
                  AppColors.primary.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(RemixIcons.edit_box_line,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('New Correction Request',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      Text('Past 30 days only',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date picker
                _SectionLabel(label: 'Date'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                              RemixIcons.calendar_event_line,
                              color: AppColors.primary,
                              size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Selected date',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          AppColors.textSecondary,
                                      fontWeight:
                                          FontWeight.w600)),
                              Text(
                                DateFormat('EEE, dd MMM yyyy')
                                    .format(_selectedDate),
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                        Icon(RemixIcons.arrow_down_s_line,
                            color: AppColors.textSecondary, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Current status
                _SectionLabel(label: 'Current Record'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                            AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(RemixIcons.close_circle_fill,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_currentStatus,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Correct to
                _SectionLabel(label: 'Correct To'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CorrectToChip(
                      label: 'Full Day',
                      icon: RemixIcons.sun_line,
                      value: 'PRESENT',
                      selected: _requestedStatus == 'PRESENT',
                      selectedColor: AppColors.success,
                      onTap: () =>
                          setState(() => _requestedStatus = 'PRESENT'),
                    ),
                    _CorrectToChip(
                      label: 'Half Day',
                      icon: RemixIcons.contrast_line,
                      value: 'HALF_DAY',
                      selected: _requestedStatus == 'HALF_DAY',
                      selectedColor: AppColors.info,
                      onTap: () => setState(
                          () => _requestedStatus = 'HALF_DAY'),
                    ),
                    _CorrectToChip(
                      label: 'Late',
                      icon: RemixIcons.time_line,
                      value: 'LATE',
                      selected: _requestedStatus == 'LATE',
                      selectedColor: AppColors.warning,
                      onTap: () =>
                          setState(() => _requestedStatus = 'LATE'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Reason
                _SectionLabel(label: 'Reason *'),
                const SizedBox(height: 6),
                TextField(
                  controller: _reasonController,
                  maxLines: 3,
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Was sick, attended from home. Doctor note attached.',
                    hintStyle: TextStyle(
                        color: AppColors.textHint, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Supporting doc
                _SectionLabel(label: 'Supporting Document (optional)'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickDocument,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _pickedFile != null
                          ? AppColors.primarySurface
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _pickedFile != null
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _pickedFile != null
                              ? RemixIcons.checkbox_circle_fill
                              : RemixIcons.attachment_2,
                          color: _pickedFile != null
                              ? AppColors.primary
                              : AppColors.textHint,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _pickedFile != null
                                ? _pickedFile!.name
                                : 'Tap to attach photo / document',
                            style: TextStyle(
                                fontSize: 12,
                                color: _pickedFile != null
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: _pickedFile != null
                                    ? FontWeight.w600
                                    : FontWeight.normal),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_pickedFile != null)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _pickedFile = null),
                            child: Icon(Icons.close,
                                size: 16,
                                color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _isSubmitting
                          ? null
                          : AppColors.primaryGradient,
                      color: _isSubmitting
                          ? AppColors.divider
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _isSubmitting
                          ? []
                          : [
                              BoxShadow(
                                color: AppColors.primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      onPressed:
                          _isSubmitting ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(RemixIcons.send_plane_fill,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Text('Submit Request',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: Colors.white)),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

/// Summary card shown on the main form screen below the submit button.
/// Displays live counts per status + a "View All" button that navigates
/// to [AttendanceCorrectionHistoryView].
class _MyRequestsSummaryCard extends StatelessWidget {
  final List<dynamic> requests;
  final bool isLoading;
  final VoidCallback onViewAll;

  const _MyRequestsSummaryCard({
    required this.requests,
    required this.isLoading,
    required this.onViewAll,
  });

  int _count(String status) => requests
      .where((r) =>
          r is Map && r['status']?.toString().toUpperCase() == status)
      .length;

  @override
  Widget build(BuildContext context) {
    final pending = _count('PENDING');
    final approved = _count('APPROVED');
    final rejected = _count('REJECTED');
    final total = requests.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(RemixIcons.history_line,
                      color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Requests',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      Text(
                        isLoading
                            ? 'Fetching...'
                            : '$total request${total == 1 ? '' : 's'} total',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.08),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      const SizedBox(width: 4),
                      Icon(RemixIcons.arrow_right_s_line,
                          size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.divider),

          // Stat chips row
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: 'Pending',
                      count: pending,
                      icon: RemixIcons.time_fill,
                      color: AppColors.warning,
                      onTap: onViewAll,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      label: 'Approved',
                      count: approved,
                      icon: RemixIcons.checkbox_circle_fill,
                      color: AppColors.success,
                      onTap: onViewAll,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      label: 'Rejected',
                      count: rejected,
                      icon: RemixIcons.close_circle_fill,
                      color: AppColors.error,
                      onTap: onViewAll,
                    ),
                  ),
                ],
              ),
            ),

          // CTA footer
          if (!isLoading) ...[
            Divider(height: 1, color: AppColors.divider),
            InkWell(
              onTap: onViewAll,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(RemixIcons.list_check,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'View Full History',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: 4),
                    Icon(RemixIcons.arrow_right_line,
                        size: 13, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.4),
      );
}

class _CorrectToChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _CorrectToChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.12)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? selectedColor.withValues(alpha: 0.5)
                : AppColors.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? selectedColor : AppColors.textHint),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? selectedColor : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatusPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
