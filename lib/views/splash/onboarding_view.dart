import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remixicon/remixicon.dart';
import '../../core/constants/app_colors.dart';
import '../auth/login_view.dart';
import '../widgets/premium_animated_background.dart';

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;

  OnboardingSlide({required this.title, required this.description, required this.icon});
}

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Seamless Attendance',
      description: 'Check in and out effortlessly with just a single tap. Track your daily hours in real time.',
      icon: RemixIcons.time_fill,
    ),
    OnboardingSlide(
      title: 'Manage Leaves Easily',
      description: 'Apply for leaves, check balances, and track approval status all from one unified dashboard.',
      icon: RemixIcons.calendar_check_fill,
    ),
    OnboardingSlide(
      title: 'Team Collaboration',
      description: 'Stay connected with instant announcements, task tracking, and transparent HR communications.',
      icon: RemixIcons.group_fill,
    ),
  ];

  Future<void> _finishOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenOnboarding', true);
    } catch (e) {
      debugPrint('Error saving onboarding preference: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  void _nextSlide() {
    if (_currentPage == _slides.length - 1) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: PremiumAnimatedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // ─── Skip Button ──────────────────────────────
              Positioned(
                top: 10,
                right: 20,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: const Text(
                    'SKIP',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ),

              // ─── Page View ────────────────────────────────
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  // Using Glassmorphism for the content block
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            slide.icon,
                            color: AppColors.primary,
                            size: 80,
                          ),
                        ).animate(key: ValueKey('img_$index')).scale(duration: 500.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 50),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF14473C),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ).animate(key: ValueKey('title_$index')).fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                        const SizedBox(height: 16),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF4A6B63),
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ).animate(key: ValueKey('desc_$index')).fadeIn(delay: 350.ms),
                      ],
                    ),
                  );
                },
              ),

              // ─── Bottom Controls ──────────────────────────
              Positioned(
                bottom: 40,
                left: 32,
                right: 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Indicators
                    Row(
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    // Next / Get Started Button
                    GestureDetector(
                      onTap: _nextSlide,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.symmetric(
                          horizontal: _currentPage == _slides.length - 1 ? 24 : 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _currentPage == _slides.length - 1
                            ? const Text(
                                'Get Started',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              )
                            : Icon(
                                RemixIcons.arrow_right_line,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
