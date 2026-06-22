import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/services/storage_service.dart';
import 'package:quickboom_hrm/core/utils/app_responsive.dart';
import 'package:quickboom_hrm/features/auth/data/models/user_model.dart';
import 'package:quickboom_hrm/features/auth/presentation/providers/auth_viewmodel.dart';
import 'package:quickboom_hrm/features/auth/presentation/screens/login_view.dart';
import 'package:quickboom_hrm/features/dashboard/presentation/screens/employee_shell.dart';
import 'package:quickboom_hrm/features/dashboard/presentation/screens/hr_shell.dart';
import 'package:quickboom_hrm/core/widgets/premium_animated_background.dart';
import 'package:quickboom_hrm/features/splash/presentation/screens/onboarding_view.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  String _statusMessage = 'Loading...';

  @override
  void initState() {
    super.initState();
    _checkSessionAndRoute();
  }

  Future<void> _checkSessionAndRoute() async {
    bool hasSeenOnboarding = false;
    String? token;

    // Ask for location permissions at app startup in the background (non-blocking)
    Geolocator.checkPermission().then((permission) {
      if (permission == LocationPermission.denied) {
        debugPrint('📋 Requesting location permission...');
        Geolocator.requestPermission();
      }
    }).catchError((e) {
      debugPrint('⚠️ Failed to request location permission on startup: $e');
    });

    // Run storage check and minimum splash display in parallel
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1500)),
      () async {
        try {
          debugPrint('🔍 Checking storage...');
          hasSeenOnboarding = await StorageService.hasSeenOnboarding();
          token = await StorageService.getToken();
          debugPrint('🔍 Onboarding seen: $hasSeenOnboarding');
          debugPrint('🔍 Token exists: ${token != null && token!.isNotEmpty}');
        } catch (e) {
          debugPrint('❌ Error loading storage: $e');
        }
      }(),
    ]);

    if (!mounted) return;

    // No token -> onboarding or login
    if (token == null || token!.isEmpty) {
      debugPrint('🚀 No token, navigating to ${hasSeenOnboarding ? "Login" : "Onboarding"}');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => hasSeenOnboarding ? const LoginView() : const OnboardingView(),
        ),
      );
      return;
    }

    // Token exists -> restore session via authViewModel
    setState(() => _statusMessage = 'Restoring session...');
    debugPrint('🔄 Restoring session...');

    try {
      final restored = await ref.read(authViewModelProvider.notifier).restoreSession()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint('⏱️ Session restore timeout');
        throw Exception('Session restore timeout');
      });

      if (!mounted) return;

      if (restored) {
        final user = ref.read(authViewModelProvider).currentUser!;
        debugPrint('✅ Session restored for ${user.name} (${user.role})');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => user.role == UserRole.hrManager
                ? const HrShell()
                : const EmployeeShell(),
          ),
        );
      } else {
        debugPrint('❌ Session restore failed, navigating to login');
        // Token invalid or expired
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => hasSeenOnboarding ? const LoginView() : const OnboardingView(),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Session restore error: $e');
      if (!mounted) return;
      // On error, navigate to login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => hasSeenOnboarding ? const LoginView() : const OnboardingView(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    return Scaffold(
      body: PremiumAnimatedBackground(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: r.w(100),
              height: r.w(100),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                RemixIcons.building_line,
                color: AppColors.primary,
                size: r.w(50),
              ),
            )
                .animate()
                .scale(duration: 800.ms, curve: Curves.easeOutBack)
                .then()
                .shimmer(duration: 1000.ms, color: AppColors.primary.withValues(alpha: 0.3)),
            SizedBox(height: r.h(24)),
            Text(
              'HRM',
              style: TextStyle(
                color: const Color(0xFF14473C),
                fontSize: r.sp(36),
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5, end: 0),
            SizedBox(height: r.h(16)),
            Text(
              _statusMessage,
              style: TextStyle(
                color: AppColors.primary.withValues(alpha: 0.7),
                fontSize: r.sp(13),
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
