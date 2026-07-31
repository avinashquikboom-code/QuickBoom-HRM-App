import 'dart:async';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';

class AnimatedNotificationBell extends StatefulWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const AnimatedNotificationBell({
    super.key,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  State<AnimatedNotificationBell> createState() =>
      _AnimatedNotificationBellState();
}

class _AnimatedNotificationBellState extends State<AnimatedNotificationBell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Bell swinging keyframes: 0 -> -20deg -> +20deg -> -12deg -> +12deg -> 0
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.30), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -0.30, end: 0.30), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.30, end: -0.18), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.18, end: 0.12), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: 0.0), weight: 15),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Initial ring after widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward(from: 0.0);
      }
    });

    // Periodic gentle animation every 5 seconds if unread notifications exist
    _periodicTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _controller.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller.forward(from: 0.0);
        widget.onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.unreadCount > 0
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.cardBorder,
            width: 1,
          ),
          boxShadow: widget.unreadCount > 0
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value,
                  alignment: Alignment.topCenter,
                  child: child,
                );
              },
              child: Icon(
                widget.unreadCount > 0
                    ? RemixIcons.notification_4_fill
                    : RemixIcons.notification_3_line,
                color: widget.unreadCount > 0
                    ? AppColors.primary
                    : AppColors.textPrimary,
                size: 20,
              ),
            ),
            if (widget.unreadCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.unreadCount > 99 ? '99+' : '${widget.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
