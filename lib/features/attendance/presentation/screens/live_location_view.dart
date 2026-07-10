import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/features/attendance/presentation/providers/live_tracking_viewmodel.dart';
import 'package:quickboom_hrm/features/attendance/presentation/providers/geofence_viewmodel.dart';
import 'package:quickboom_hrm/core/services/mobile_store_service.dart';
import 'package:quickboom_hrm/features/store/data/store_models.dart';

class LiveLocationView extends ConsumerStatefulWidget {
  const LiveLocationView({super.key});

  @override
  ConsumerState<LiveLocationView> createState() => _LiveLocationViewState();
}

class _LiveLocationViewState extends ConsumerState<LiveLocationView> {
  String? _selectedLocationId;
  List<Store> _allLocations = [];
  List<OfficeGeofence> _officeLocations = [];
  bool _isLoadingLocations = false;

  @override
  void initState() {
    super.initState();
    _loadAllLocations();
  }

  Future<void> _loadAllLocations() async {
    setState(() => _isLoadingLocations = true);
    
    try {
      // Load all store locations
      final storeData = await MobileStoreService.getAllStores();
      if (storeData != null && storeData['stores'] != null) {
        final stores = (storeData['stores'] as List)
            .map((store) => Store.fromJson(store))
            .toList();
        setState(() => _allLocations = stores);
      }

      // Load office geofences
      await ref.read(geofenceViewModelProvider.notifier).getAllOfficeGeofences();
      setState(() => _officeLocations = ref.read(geofenceViewModelProvider).offices);
      
    } catch (e) {
      debugPrint('Error loading locations: $e');
    } finally {
      setState(() => _isLoadingLocations = false);
    }
  }

  List<DropdownMenuItem<String>> _buildLocationDropdownItems() {
    final items = <DropdownMenuItem<String>>[];
    
    // Add "All Locations" option
    items.add(const DropdownMenuItem(
      value: 'all',
      child: Row(
        children: [
          Icon(RemixIcons.global_line, size: 16),
          SizedBox(width: 8),
          Text('All Locations'),
        ],
      ),
    ));

    // Add store locations
    for (final store in _allLocations) {
      items.add(DropdownMenuItem(
        value: 'store_${store.id}',
        child: Row(
          children: [
            const Icon(RemixIcons.store_2_line, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(store.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(store.address, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ));
    }

    // Add office locations
    for (final office in _officeLocations) {
      items.add(DropdownMenuItem(
        value: 'office_${office.id}',
        child: Row(
          children: [
            const Icon(RemixIcons.building_line, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(office.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(office.address, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ));
    }

    return items;
  }

  Future<void> _refreshLiveLocations() async {
    if (_selectedLocationId == null) return;

    setState(() => _isLoadingLocations = true);
    
    try {
      if (_selectedLocationId == 'all') {
        // Get all live locations
        await ref.read(liveTrackingViewModelProvider.notifier).getLiveLocations();
      } else if (_selectedLocationId!.startsWith('store_')) {
        // Get live locations for specific store
        final storeId = _selectedLocationId!.replaceFirst('store_', '');
        debugPrint('Loading live locations for store: $storeId');
        // TODO: Implement store-specific live locations API call
        await ref.read(liveTrackingViewModelProvider.notifier).getLiveLocations();
      } else if (_selectedLocationId!.startsWith('office_')) {
        // Get live locations for specific office
        final officeId = _selectedLocationId!.replaceFirst('office_', '');
        debugPrint('Loading live locations for office: $officeId');
        // TODO: Implement office-specific live locations API call
        await ref.read(liveTrackingViewModelProvider.notifier).getLiveLocations();
      }
    } catch (e) {
      debugPrint('Error refreshing live locations: $e');
    } finally {
      setState(() => _isLoadingLocations = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveTrackingState = ref.watch(liveTrackingViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Live Location Tracking',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshLiveLocations,
            icon: _isLoadingLocations
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  )
                : Icon(
                    RemixIcons.refresh_line,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Location Dropdown Section ──────────────────────────────────────
            _buildLocationDropdown(isDark),
            const SizedBox(height: 24),

            // ─── Live Location Stats ──────────────────────────────────────────
            _buildLiveLocationStats(liveTrackingState, isDark),
            const SizedBox(height: 24),

            // ─── Active Tracking Sessions ───────────────────────────────────────
            _buildActiveSessions(liveTrackingState, isDark),
            const SizedBox(height: 24),

            // ─── Location History ───────────────────────────────────────────────
            _buildLocationHistory(liveTrackingState, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDropdown(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.inputBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  RemixIcons.map_2_line,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedLocationId,
              decoration: InputDecoration(
                hintText: 'Choose location to track',
                prefixIcon: Icon(
                  RemixIcons.global_line,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : AppColors.primarySurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _buildLocationDropdownItems(),
              onChanged: (value) {
                setState(() {
                  _selectedLocationId = value;
                });
                if (value != null) {
                  _refreshLiveLocations();
                }
              },
            ),
            if (_selectedLocationId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      RemixIcons.information_line,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedLocationId == 'all'
                            ? 'Showing live locations for all stores and offices'
                            : 'Showing live locations for selected location',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildLiveLocationStats(LiveTrackingState state, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.inputBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  RemixIcons.pulse_line,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Live Statistics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active Users',
                    '${state.isTracking ? 1 : 0}',
                    RemixIcons.user_3_line,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Distance',
                    '${state.totalDistance.toStringAsFixed(2)} km',
                    RemixIcons.route_line,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessions(LiveTrackingState state, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.inputBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  RemixIcons.play_circle_line,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Sessions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.isTracking) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.trackingPurpose ?? 'Live Tracking',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'Session started ${state.sessionDuration.inMinutes} minutes ago',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      RemixIcons.live_line,
                      color: Colors.green,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      RemixIcons.pause_circle_line,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'No active tracking sessions',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLocationHistory(LiveTrackingState state, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.inputBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  RemixIcons.history_line,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Location History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.locationHistory.isNotEmpty) ...[
              ...state.locationHistory.take(5).map((location) => _buildLocationItem(location)),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      RemixIcons.map_pin_line,
                      color: Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'No location history available',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLocationItem(LocationPoint location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            RemixIcons.map_pin_2_line,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${location.timestamp.hour.toString().padLeft(2, '0')}:${location.timestamp.minute.toString().padLeft(2, '0')}:${location.timestamp.second.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (location.accuracy != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '±${location.accuracy!.toStringAsFixed(0)}m',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
