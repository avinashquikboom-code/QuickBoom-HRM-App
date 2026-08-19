import 'package:flutter/material.dart';
import 'package:quickboom_hrm/core/widgets/locked_feature_card.dart';
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
    return LockedFeatureCard.wrapper(
      user: user,
      permissionKey: permission,
      moduleName: moduleName,
      onTap: onTap,
      child: child,
    );
  }
}
