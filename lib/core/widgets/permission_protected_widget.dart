import 'package:flutter/material.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/services/permission_service.dart';
import 'package:quickboom_hrm/features/auth/data/models/user_model.dart';

class PermissionProtectedWidget extends StatelessWidget {
  final UserModel? user;
  final String permission;
  final String moduleName;
  final Widget child;
  final VoidCallback? onTap;

  const PermissionProtectedWidget({
    super.key,
    required this.user,
    required this.permission,
    required this.moduleName,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAccess = PermissionService.hasPermission(user, permission);

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

    // Disabled mode UI + Lock Badge + SnackBar Toast on tap
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Access Restricted: You do not have permission to access $moduleName. Contact HR.',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
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
            child: IgnorePointer(
              child: child,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
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
