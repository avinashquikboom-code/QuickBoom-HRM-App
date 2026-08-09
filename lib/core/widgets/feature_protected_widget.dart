import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/providers/feature_access_provider.dart';

class FeatureProtectedWidget extends ConsumerWidget {
  final String featureName;
  final Widget child;
  final VoidCallback? onTap;

  const FeatureProtectedWidget({
    super.key,
    required this.featureName,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider state to rebuild when API completes
    ref.watch(featureAccessProvider);
    
    final feature = ref
        .read(featureAccessProvider.notifier)
        .getFeature(featureName);

    // If not found or enabled, pass through normally
    // (Assuming default is enabled if backend doesn't explicitly restrict, or we just rely on state)
    final hasAccess = feature == null || feature.enabled;

    if (hasAccess) {
      if (onTap != null) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: child,
        );
      }
      return child;
    }

    final reason = feature.reason;

    // Disabled mode UI + Lock Badge + Request Access Dialog on tap
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _showRequestAccessDialog(context, ref, featureName, reason);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              0.45,
              0,
            ]),
            child: IgnorePointer(child: child),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestAccessDialog(
    BuildContext context,
    WidgetRef ref,
    String featureName,
    String reason,
  ) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _RequestAccessDialog(featureName: featureName, reason: reason),
    );
  }
}

class _RequestAccessDialog extends ConsumerStatefulWidget {
  final String featureName;
  final String reason;

  const _RequestAccessDialog({required this.featureName, required this.reason});

  @override
  ConsumerState<_RequestAccessDialog> createState() =>
      _RequestAccessDialogState();
}

class _RequestAccessDialogState extends ConsumerState<_RequestAccessDialog> {
  final _reasonController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a reason')));
      return;
    }
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select dates')));
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref
        .read(featureAccessProvider.notifier)
        .requestAccess(
          widget.featureName,
          _reasonController.text.trim(),
          _fromDate!.toIso8601String().split('T')[0],
          _toDate!.toIso8601String().split('T')[0],
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent to HR'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send request'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Request Access to ${widget.featureName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currently disabled: ${widget.reason}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Why do you need this?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _fromDate = date);
                    },
                    child: Text(
                      _fromDate == null
                          ? 'From Date'
                          : _fromDate!.toIso8601String().split('T')[0],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _fromDate ?? DateTime.now(),
                        firstDate: _fromDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _toDate = date);
                    },
                    child: Text(
                      _toDate == null
                          ? 'Until Date'
                          : _toDate!.toIso8601String().split('T')[0],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Request', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
