import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quickboom_hrm/services/distanceService.dart';
import 'package:quickboom_hrm/widgets/custom_loading_widget.dart';
import 'package:quickboom_hrm/widgets/custom_error_widget.dart';

class DistanceTrackingScreen extends ConsumerStatefulWidget {
  const DistanceTrackingScreen({super.key});

  @override
  ConsumerState<DistanceTrackingScreen> createState() => _DistanceTrackingScreenState();
}

class _DistanceTrackingScreenState extends ConsumerState<DistanceTrackingScreen> {
  DistanceData? _currentDistance;
  OfficeInfo? _officeInfo;
  List<DistanceHistoryRecord> _history = [];
  DistanceHistorySummary? _summary;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Get office info
    final officeResult = await DistanceTrackingService.getOfficeInfo();
    if (officeResult['success']) {
      setState(() {
        _officeInfo = OfficeInfo.fromJson(officeResult['data']);
      });
    }

    // Get distance history
    final historyResult = await DistanceTrackingService.getDistanceHistory(limit: 30);
    if (historyResult['success']) {
      setState(() {
        _history = (historyResult['data']['history'] as List)
            .map((item) => DistanceHistoryRecord.fromJson(item))
            .toList();
        _summary = DistanceHistorySummary.fromJson(historyResult['data']['summary']);
      });
    }

    // Get current location and distance
    await _getCurrentDistance();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getCurrentDistance() async {
    setState(() {
      _isGettingLocation = true;
    });

    // Get current position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Get distance from office
    final result = await DistanceTrackingService.getCurrentDistance(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    if (result['success']) {
      setState(() {
        _currentDistance = DistanceData.fromJson(result['data']);
      });
    }

    setState(() {
      _isGettingLocation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Distance Tracking'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const CustomLoadingWidget(message: 'Loading distance data...');
    }

    if (_error != null) {
      return CustomErrorWidget(
        error: _error!,
        onRetry: _loadData,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentDistanceCard(),
            const SizedBox(height: 16),
            _buildOfficeInfoCard(),
            const SizedBox(height: 16),
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildHistoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentDistanceCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Distance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isGettingLocation)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _getCurrentDistance,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentDistance != null) ...[
              Row(
                children: [
                  Icon(
                    _currentDistance!.isWithinRadius
                        ? Icons.check_circle
                        : Icons.location_off,
                    color: _currentDistance!.isWithinRadius
                        ? Colors.green
                        : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_currentDistance!.distance.toStringAsFixed(2)} km',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _currentDistance!.message,
                          style: TextStyle(
                            color: _currentDistance!.isWithinRadius
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.business, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentDistance!.officeName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const Text(
                'Tap the location button to get current distance',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficeInfoCard() {
    if (_officeInfo == null) return const SizedBox();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Office Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Name', _officeInfo!.name),
            _buildInfoRow('Address', _officeInfo!.address),
            _buildInfoRow('Radius', '${_officeInfo!.radius} meters'),
            _buildInfoRow(
              'Location',
              '${_officeInfo!.latitude.toStringAsFixed(6)}, ${_officeInfo!.longitude.toStringAsFixed(6)}',
            ),
            _buildInfoRow('Timezone', _officeInfo!.timezone),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_summary == null) return const SizedBox();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distance Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Records',
                    '${_summary!.totalRecords}',
                    Icons.list_alt,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Avg Distance',
                    '${_summary!.averageDistance.toStringAsFixed(2)} km',
                    Icons.straighten,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Within Radius',
                    '${_summary!.withinRadiusPercentage.toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Farthest',
                    '${_summary!.farthestDistance.toStringAsFixed(2)} km',
                    Icons.location_on,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, [Color? color]) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color ?? Colors.blue, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.blue,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_history.isEmpty)
              const Text(
                'No distance history available',
                style: TextStyle(color: Colors.grey),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final record = _history[index];
                  return _buildHistoryItem(record);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(DistanceHistoryRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record.date,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Icon(
                record.isWithinRadius ? Icons.check_circle : Icons.location_off,
                color: record.isWithinRadius ? Colors.green : Colors.orange,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${record.distance.toStringAsFixed(2)} km',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                record.locationStatus,
                style: TextStyle(
                  fontSize: 12,
                  color: record.isWithinRadius ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (record.checkIn != null) ...[
            const SizedBox(height: 4),
            Text(
              'Check-in: ${_formatTime(record.checkIn!)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String isoTime) {
    final dateTime = DateTime.parse(isoTime);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
