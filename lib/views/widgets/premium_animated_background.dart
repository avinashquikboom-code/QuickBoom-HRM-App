import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PremiumAnimatedBackground extends StatefulWidget {
  final Widget child;

  const PremiumAnimatedBackground({super.key, required this.child});

  @override
  State<PremiumAnimatedBackground> createState() => _PremiumAnimatedBackgroundState();
}

class _PremiumAnimatedBackgroundState extends State<PremiumAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Light Brand-Aligned Soft Base (0% Grey)
        Container(
          color: const Color(0xFFF3FAF8), // Very soft, clean mint-white base
        ),
        // 2. Slow-Moving Ambient Brand Orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = _controller.value;
            return Stack(
              children: [
                // Orb 1: Shifting primary brand color (#3ba38b)
                Positioned(
                  top: -120 + (180 * value),
                  left: -80 + (120 * value),
                  child: Container(
                    width: 380,
                    height: 380,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.22),
                          AppColors.primary.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Orb 2: Pulsing brand light color (#5bbda6)
                Positioned(
                  bottom: -80 + (150 * value),
                  right: -120 + (180 * value),
                  child: Container(
                    width: 440,
                    height: 440,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryLight.withValues(alpha: 0.18),
                          AppColors.primaryLight.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                // Orb 3: Center-left brand dark accent (#2d8a74)
                Positioned(
                  top: 250 - (60 * value),
                  right: 60 + (120 * value),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryDark.withValues(alpha: 0.15),
                          AppColors.primaryDark.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        // 3. Luxurious Frosted Glass Blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Container(
              color: Colors.white.withValues(alpha: 0.45), // Frosted white tint for light theme
            ),
          ),
        ),
        // 4. Content Overlay
        Positioned.fill(child: widget.child),
      ],
    );
  }
}
