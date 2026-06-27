import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';

class ShimmerLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .shimmer(
        duration: 1200.ms,
        color: AppColors.primary.withValues(alpha: 0.2),
      );
  }
}

class ShimmerCard extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerCard({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ShimmerLoading(
          height: 80,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }
    return child;
  }
}

class ShimmerListTile extends StatelessWidget {
  final bool isLoading;
  final Widget? child;

  const ShimmerListTile({
    super.key,
    required this.isLoading,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ShimmerLoading(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.circular(24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading(
                    height: 16,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  ShimmerLoading(
                    height: 12,
                    width: 120,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return child ?? const SizedBox.shrink();
  }
}

class ShimmerStatsCard extends StatelessWidget {
  final bool isLoading;
  final Widget? child;

  const ShimmerStatsCard({
    super.key,
    required this.isLoading,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerLoading(
              height: 20,
              width: 80,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            ShimmerLoading(
              height: 32,
              width: 60,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    return child ?? const SizedBox.shrink();
  }
}
