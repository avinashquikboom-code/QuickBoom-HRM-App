import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/widgets/shimmer_loading.dart';

class MonthlyWorkScheduleView extends ConsumerStatefulWidget {
  const MonthlyWorkScheduleView({super.key});

  @override
  ConsumerState<MonthlyWorkScheduleView> createState() => _MonthlyWorkScheduleViewState();
}

class _MonthlyWorkScheduleViewState extends ConsumerState<MonthlyWorkScheduleView> {
  DateTime _selectedMonth = DateTime.now();
  List<Map<String, dynamic>> _schedule = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final month = _selectedMonth.month;
      final year = _selectedMonth.year;
      final res = await ApiService.get('${AppUrl.mobileMonthlyWorkSchedule}?month=$month&year=$year');
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _schedule = List<Map<String, dynamic>>.from(data['data']['schedule']);
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load schedule';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadSchedule();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
    _loadSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Work Schedule',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          // Month selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: Icon(RemixIcons.arrow_left_s_line, color: AppColors.primary),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedMonth),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: Icon(RemixIcons.arrow_right_s_line, color: AppColors.primary),
                ),
              ],
            ),
          ),
          
          // Schedule list
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _errorMessage != null
                    ? _buildError()
                    : _buildSchedule(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerLoading(
          height: 80,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(RemixIcons.error_warning_line, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'An error occurred',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSchedule,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedule() {
    if (_schedule.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(RemixIcons.calendar_line, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              'No schedule available',
              style: TextStyle(color: AppColors.textHint),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schedule.length,
      itemBuilder: (context, index) {
        final day = _schedule[index];
        return _ScheduleDayCard(day: day);
      },
    );
  }
}

class _ScheduleDayCard extends StatelessWidget {
  final Map<String, dynamic> day;

  const _ScheduleDayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final isWeekend = day['isWeekend'] ?? false;
    final shift = day['shift'];
    final office = day['office'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isWeekend 
                      ? AppColors.errorSurface 
                      : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getDayName(day['dayOfWeek']),
                  style: TextStyle(
                    color: isWeekend ? AppColors.error : AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('dd MMM, yyyy').format(DateTime.parse(day['date'])),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (isWeekend)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Weekend',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (!isWeekend && shift != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(RemixIcons.time_line, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${shift['startTime']} - ${shift['endTime']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(RemixIcons.briefcase_line, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  shift['name'] ?? 'No shift assigned',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          if (office != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(RemixIcons.building_line, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    office['name'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getDayName(int dayOfWeek) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[dayOfWeek];
  }
}
