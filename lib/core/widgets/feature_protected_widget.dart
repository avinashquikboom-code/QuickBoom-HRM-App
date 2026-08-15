import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/providers/feature_access_provider.dart';
import 'package:quickboom_hrm/core/widgets/access_restricted_bottom_sheet.dart';

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

    // Disabled mode UI + Lock Badge + Access Restricted Bottom Sheet on tap
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AccessRestrictedBottomSheet.show(context, featureName);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      0.45, 0,
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
}
