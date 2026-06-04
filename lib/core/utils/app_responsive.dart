import 'package:flutter/material.dart';

/// Responsive sizing utility for the HRM app.
///
/// Uses MediaQuery to compute sizes relative to the screen.
/// Works correctly on:
///  - Small Android phones  (360 × 640 dp)
///  - Large Android phones  (412 × 915 dp)
///  - iPhones SE/Mini       (~375 × 667 dp)
///  - iPhones Standard      (~390 × 844 dp)
///  - iPhones Pro Max       (~430 × 932 dp)
///  - Small tablets         (~600 × 960 dp)
///
/// Usage inside a widget build():
///   final r = AppResponsive.of(context);
///   SizedBox(height: r.h(24))   // 24 logical px scaled to screen height
///   Text('Hi', style: TextStyle(fontSize: r.sp(15)))
class AppResponsive {
  final double screenWidth;
  final double screenHeight;
  final double _baseWidth;
  final double _baseHeight;

  AppResponsive._({
    required this.screenWidth,
    required this.screenHeight,
  })  : _baseWidth  = 390.0, // iPhone 14 / Pixel 6 reference
        _baseHeight = 844.0;

  factory AppResponsive.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AppResponsive._(
      screenWidth:  size.width,
      screenHeight: size.height,
    );
  }

  // ─── Scaled Width ───────────────────────────────────────────────────────────
  /// Scale a value proportionally to the screen width.
  double w(double px) => px * (screenWidth / _baseWidth);

  // ─── Scaled Height ──────────────────────────────────────────────────────────
  /// Scale a value proportionally to the screen height.
  double h(double px) => px * (screenHeight / _baseHeight);

  // ─── Font Size ──────────────────────────────────────────────────────────────
  /// Scale a font-size using the average of width & height ratios
  /// (avoids overly large text on wide tablets).
  double sp(double size) {
    final wRatio = screenWidth  / _baseWidth;
    final hRatio = screenHeight / _baseHeight;
    return size * (wRatio * 0.5 + hRatio * 0.5);
  }

  // ─── Convenience shortcuts ──────────────────────────────────────────────────

  /// Clamp a value between [min] and [max].
  double clamp(double value, double min, double max) =>
      value.clamp(min, max).toDouble();

  /// Percentage of screen width.
  double wp(double percent) => screenWidth * percent / 100;

  /// Percentage of screen height.
  double hp(double percent) => screenHeight * percent / 100;

  // ─── Device category helpers ────────────────────────────────────────────────
  bool get isSmallPhone => screenWidth < 360;
  bool get isPhone      => screenWidth >= 360 && screenWidth < 600;
  bool get isTablet     => screenWidth >= 600;

  // ─── Responsive padding helpers ─────────────────────────────────────────────

  /// Standard horizontal screen padding (shrinks on small phones).
  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(
        horizontal: isSmallPhone ? w(16) : w(24),
      );

  /// Card inner padding.
  EdgeInsets get cardPadding => EdgeInsets.all(
        isSmallPhone ? w(20) : w(28),
      );
}

// ─── Extension for convenience ────────────────────────────────────────────────
extension ResponsiveContext on BuildContext {
  AppResponsive get r => AppResponsive.of(this);
}
