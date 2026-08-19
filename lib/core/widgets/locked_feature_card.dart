import 'package:flutter/material.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/services/permission_service.dart';
import 'package:quickboom_hrm/core/widgets/access_restricted_bottom_sheet.dart';
import 'package:quickboom_hrm/features/auth/data/models/user_model.dart';

/// Reusable Locked Feature Card / Wrapper Component.
/// Supports both card layout (title, icon, onTap) and custom child wrapper.
class LockedFeatureCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final bool? isLocked;
  final UserModel? user;
  final String? permissionKey;
  final String moduleName;
  final VoidCallback? onTap;
  final Widget? child;

  const LockedFeatureCard({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.isLocked,
    this.user,
    this.permissionKey,
    required this.moduleName,
    this.onTap,
    this.child,
  });

  /// Factory constructor for wrapping any custom card or widget.
  factory LockedFeatureCard.wrapper({
    Key? key,
    required Widget child,
    required String moduleName,
    String? permissionKey,
    UserModel? user,
    bool? isLocked,
    VoidCallback? onTap,
  }) {
    return LockedFeatureCard(
      key: key,
      moduleName: moduleName,
      permissionKey: permissionKey,
      user: user,
      isLocked: isLocked,
      onTap: onTap,
      child: child,
    );
  }

  bool _checkIsLocked() {
    if (isLocked != null) return isLocked!;
    if (user != null && permissionKey != null) {
      return !PermissionService.hasPermission(user, permissionKey!);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final locked = _checkIsLocked();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content;
    if (child != null) {
      content = child!;
    } else {
      // Default Card Layout
      content = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155)
                : AppColors.primary.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (color ?? AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color ?? AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (!locked) {
      if (onTap != null) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: content,
        );
      }
      return content;
    }

    // Locked UI presentation: Greyscale + 45% Opacity + Dark Lock Badge
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AccessRestrictedBottomSheet.show(
          context,
          moduleName,
          permissionKey: permissionKey,
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
              child: content,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
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
