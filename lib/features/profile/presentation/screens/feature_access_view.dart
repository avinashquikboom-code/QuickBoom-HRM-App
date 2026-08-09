import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/features/profile/data/models/feature_access_model.dart';
import 'package:quickboom_hrm/features/profile/presentation/providers/feature_access_viewmodel.dart';

class FeatureAccessView extends ConsumerStatefulWidget {
  const FeatureAccessView({super.key});

  @override
  ConsumerState<FeatureAccessView> createState() => _FeatureAccessViewState();
}

class _FeatureAccessViewState extends ConsumerState<FeatureAccessView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(featureAccessViewModelProvider.notifier).fetchFeatures();
    });
  }

  void _showRequestModal(BuildContext context, {String? defaultFeature}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeatureRequestBottomSheet(defaultFeature: defaultFeature),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(featureAccessViewModelProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Feature Access'),
        actions: [
          IconButton(
            icon: const Icon(RemixIcons.refresh_line),
            onPressed: () =>
                ref.read(featureAccessViewModelProvider.notifier).fetchFeatures(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRequestModal(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(RemixIcons.add_line, color: Colors.white),
        label: const Text(
          'Request Access',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(featureAccessViewModelProvider.notifier).fetchFeatures();
        },
        color: AppColors.primary,
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    AppColors.primary.withValues(alpha: 0.2),
                                    AppColors.surface
                                  ]
                                : [
                                    AppColors.primary.withValues(alpha: 0.08),
                                    Colors.white
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                RemixIcons.shield_keyhole_line,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Feature Access Governance',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Request specialized permissions for time-bound features directly from your HR & Administrator.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.05, end: 0),
                    ),
                  ),

                  if (state.errorMessage != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ),
                    ),

                  if (state.features.isEmpty && !state.isLoading)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              RemixIcons.key_2_line,
                              size: 48,
                              color: cs.onSurface.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No specific feature restrictions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All standard modules are enabled for your account.',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showRequestModal(context),
                              icon: const Icon(RemixIcons.add_line),
                              label: const Text('Request Feature Access'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final feature = state.features[index];
                            return _FeatureCard(
                              feature: feature,
                              onRequestTap: () => _showRequestModal(
                                context,
                                defaultFeature: feature.name,
                              ),
                            ).animate().fadeIn(delay: (index * 50).ms);
                          },
                          childCount: state.features.length,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final FeatureAccessModel feature;
  final VoidCallback onRequestTap;

  const _FeatureCard({
    required this.feature,
    required this.onRequestTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color statusColor = feature.active ? AppColors.success : AppColors.error;
    final String statusText = feature.active ? 'ACTIVE' : 'RESTRICTED';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    feature.active
                        ? RemixIcons.checkbox_circle_line
                        : RemixIcons.lock_2_line,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            if (feature.reason != null && feature.reason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                feature.reason!,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (feature.validFrom != null || feature.validTo != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (feature.validFrom != null)
                    _MetaBadge(
                      icon: RemixIcons.calendar_event_line,
                      label:
                          'From: ${DateFormat('dd MMM yyyy').format(feature.validFrom!)}',
                    ),
                  if (feature.validTo != null)
                    _MetaBadge(
                      icon: RemixIcons.calendar_event_line,
                      label:
                          'To: ${DateFormat('dd MMM yyyy').format(feature.validTo!)}',
                    ),
                  if (feature.validFromTime != null)
                    _MetaBadge(
                      icon: RemixIcons.time_line,
                      label: 'After: ${feature.validFromTime}',
                    ),
                  if (feature.validToTime != null)
                    _MetaBadge(
                      icon: RemixIcons.time_line,
                      label: 'Until: ${feature.validToTime}',
                    ),
                ],
              ),
            ],
            if (!feature.active) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRequestTap,
                  icon: const Icon(RemixIcons.key_line, size: 16),
                  label: const Text('Request Temporary Access'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _FeatureRequestBottomSheet extends ConsumerStatefulWidget {
  final String? defaultFeature;

  const _FeatureRequestBottomSheet({this.defaultFeature});

  @override
  ConsumerState<_FeatureRequestBottomSheet> createState() =>
      __FeatureRequestBottomSheetState();
}

class __FeatureRequestBottomSheetState
    extends ConsumerState<_FeatureRequestBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _featureNameController;
  late TextEditingController _reasonController;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _featureNameController =
        TextEditingController(text: widget.defaultFeature ?? '');
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _featureNameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate.isBefore(_fromDate)) {
            _toDate = _fromDate.add(const Duration(days: 1));
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(featureAccessViewModelProvider.notifier)
        .requestFeatureAccess(
          featureName: _featureNameController.text.trim(),
          reason: _reasonController.text.trim(),
          fromDate: _fromDate,
          toDate: _toDate,
        );

    if (mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feature access request submitted to HR!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(featureAccessViewModelProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Request Feature Access',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Submit request for feature enablement to HR / Super Admin.',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _featureNameController,
                decoration: const InputDecoration(
                  labelText: 'Feature Name',
                  hintText: 'e.g. Remote Work, Shift Change, Reports',
                  prefixIcon: Icon(RemixIcons.key_line),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Feature name is required' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason for Access',
                  hintText: 'Explain why you require this feature permission...',
                  prefixIcon: Icon(RemixIcons.chat_4_line),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Reason is required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(true),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: cs.onSurface.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From Date',
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(_fromDate),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(false),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: cs.onSurface.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To Date',
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(_toDate),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Access Request',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
