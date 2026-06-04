import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/app_responsive.dart';
import '../../models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_view.dart';
import '../employee/employee_shell.dart';
import '../hr/hr_shell.dart';
import '../widgets/premium_animated_background.dart';
import 'onboarding_view.dart';

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

    try {
      hasSeenOnboarding = await StorageService.hasSeenOnboarding();
      token = await StorageService.getToken();
    } catch (e) {
      debugPrint('Error loading storage: $e');
    }

    // Always show splash for at least 1.5 seconds
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // No token -> onboarding or login
    if (token == null || token.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => hasSeenOnboarding ? const LoginView() : const OnboardingView(),
        ),
      );
      return;
    }

    // Token exists -> restore session via authViewModel
    setState(() => _statusMessage = 'Restoring session...');

    final restored = await ref.read(authViewModelProvider.notifier).restoreSession();

    if (!mounted) return;

    if (restored) {
      final user = ref.read(authViewModelProvider).currentUser!;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => user.role == UserRole.hrManager
              ? const HrShell()
              : const EmployeeShell(),
        ),
      );
    } else {
      // Token invalid or expired
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
