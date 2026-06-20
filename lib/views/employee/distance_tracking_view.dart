import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quickboom_hrm/core/services/distance_service.dart';

class DistanceTrackingView extends ConsumerStatefulWidget {
  const DistanceTrackingView({super.key});

  @override
  ConsumerState<DistanceTrackingView> createState() => _DistanceTrackingViewState();
}

class _DistanceTrackingViewState extends ConsumerState<DistanceTrackingView> {
  DistanceData? _currentDistance;
  OfficeInfo? _officeInfo;
  List<DistanceHistoryRecord> _history = [];
  DistanceHistorySummary? _summary;
  bool _isLoading = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final officeResult = await DistanceService.getOfficeInfo();
    setState(() => _officeInfo = OfficeInfo.fromJson(officeResult));

    final historyResult = await DistanceService.getDistanceHistory(limit: 30);
    setState(() {
      _history = (historyResult['history'] as List? ?? [])
          .map((item) => DistanceHistoryRecord.fromJson(item))
          .toList();
      _summary = DistanceHistorySummary.fromJson(historyResult['summary'] ?? {});
    });

    await _getCurrentDistance();
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentDistance() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in settings.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final result = await DistanceService.getCurrentDistance(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() => _currentDistance = DistanceData.fromJson(result));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Distance Tracking'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                const Text('Current Distance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _isGettingLocation
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(icon: const Icon(Icons.my_location), onPressed: _getCurrentDistance),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentDistance != null) ...[
              Row(
                children: [
                  Icon(_currentDistance!.isWithinRadius ? Icons.check_circle : Icons.location_off,
                      color: _currentDistance!.isWithinRadius ? Colors.green : Colors.red, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_currentDistance!.distance.toStringAsFixed(2)} km',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(_currentDistance!.message,
                            style: TextStyle(
                                color: _currentDistance!.isWithinRadius ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ] else
              const Text('Tap the location button to get current distance', style: TextStyle(color: Colors.grey)),
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
            const Text('Office Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _infoRow('Name', _officeInfo!.name),
            _infoRow('Address', _officeInfo!.address),
            _infoRow('Radius', '${_officeInfo!.radius} meters'),
            _infoRow('Location', '${_officeInfo!.latitude.toStringAsFixed(6)}, ${_officeInfo!.longitude.toStringAsFixed(6)}'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey))),
          const Text(': '),
          Expanded(child: Text(value)),
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
            const Text('Distance Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _summaryItem('Total Records', '${_summary!.totalRecords}', Icons.list_alt),
                _summaryItem('Avg Distance', '${_summary!.averageDistance.toStringAsFixed(2)} km', Icons.straighten),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _summaryItem('Within Radius', '${_summary!.withinRadiusPercentage.toStringAsFixed(1)}%', Icons.check_circle, Colors.green),
                _summaryItem('Farthest', '${_summary!.farthestDistance.toStringAsFixed(2)} km', Icons.location_on, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon, [Color? color]) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (color ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? Colors.blue, size: 24),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.blue)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
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
            const Text('Recent History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_history.isEmpty)
              const Text('No distance history available', style: TextStyle(color: Colors.grey))
            else
              ..._history.take(10).map((record) => _historyItem(record)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _historyItem(DistanceHistoryRecord record) {
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
              Text(record.date, style: const TextStyle(fontWeight: FontWeight.bold)),
              Icon(record.isWithinRadius ? Icons.check_circle : Icons.location_off,
                  color: record.isWithinRadius ? Colors.green : Colors.orange, size: 20),
            ],
          ),
          Row(
            children: [
              Text('${record.distance.toStringAsFixed(2)} km',
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue)),
              const SizedBox(width: 12),
              Text(record.locationStatus,
                  style: TextStyle(fontSize: 12, color: record.isWithinRadius ? Colors.green : Colors.orange, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
