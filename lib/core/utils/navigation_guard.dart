import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_hrm/core/services/permission_service.dart';
import 'package:quickboom_hrm/core/providers/feature_access_provider.dart';
import 'package:quickboom_hrm/core/widgets/access_restricted_bottom_sheet.dart';
import 'package:quickboom_hrm/features/auth/presentation/providers/auth_viewmodel.dart';

class NavigationGuard {
  NavigationGuard._();

  /// Check if the logged-in user has permission for the specified module.
  /// If granted, pushes [page]. If denied, shows [AccessRestrictedBottomSheet] and blocks push.
  static Future<T?> pushProtected<T>({
    required BuildContext context,
    required WidgetRef ref,
    required String permissionKey,
    required String moduleName,
    required Widget page,
  }) async {
    final user = ref.read(authViewModelProvider).currentUser;
    final hasBasePermission = PermissionService.hasPermission(user, permissionKey);

    final feature = ref.read(featureAccessProvider.notifier).getFeature(moduleName);
    final isFeatureEnabled = feature == null || feature.isCurrentlyValid;

    final isAuthorized = hasBasePermission && isFeatureEnabled;

    if (isAuthorized) {
      return Navigator.push<T>(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    }

    // Permission Denied: Show Access Required bottom sheet and block route push
    AccessRestrictedBottomSheet.show(
      context,
      moduleName,
      permissionKey: permissionKey,
    );

    return null;
  }
}
