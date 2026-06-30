import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/utils/app_responsive.dart';
import 'package:quickboom_hrm/features/auth/presentation/providers/auth_viewmodel.dart';
import 'package:quickboom_hrm/features/dashboard/presentation/screens/employee_shell.dart';
import 'package:quickboom_hrm/core/widgets/premium_animated_background.dart';
import 'package:quickboom_hrm/features/auth/presentation/screens/forgot_password_view.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  TabController? _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tabController == null) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) return;
        setState(() {
          _emailCtrl.clear();
          _passCtrl.clear();
          ref.read(authViewModelProvider.notifier).clearError();
        });
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref
        .read(authViewModelProvider.notifier)
        .login(_emailCtrl.text, _passCtrl.text);
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EmployeeShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final r = AppResponsive.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: PremiumAnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: r.w(24),
                vertical: r.h(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ─── Logo & Header ─────────────────────────────────────────
                  Container(
                    width: r.w(80),
                    height: r.w(80),
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
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      RemixIcons.building_line,
                      color: AppColors.primary,
                      size: r.w(40),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                  SizedBox(height: r.h(20)),
                  Text(
                    'HRM',
                    style: TextStyle(
                      color: const Color(0xFF14473C),
                      fontSize: r.sp(32),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                  SizedBox(height: r.h(4)),
                  Text(
                    'Elevate your workspace',
                    style: TextStyle(
                      color: const Color(0xFF4A6B63),
                      fontSize: r.sp(15),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  SizedBox(height: r.h(40)),

                  // ─── Glassmorphism Card ──────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(r.w(32)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: r.cardPadding,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ─── Tabs ────────────────────────────────────
                              Container(
                                height: r.h(50),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F3F1),
                                  borderRadius: BorderRadius.circular(r.w(16)),
                                ),
                                padding: EdgeInsets.all(r.w(4)),
                                child: TabBar(
                                  controller: _tabController,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  dividerColor: Colors.transparent,
                                  indicator: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(r.w(12)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  labelColor: AppColors.primary,
                                  unselectedLabelColor: const Color(0xFF4A6B63),
                                  labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: r.sp(13)),
                                  tabs: const [
                                    Tab(text: 'Store Manager'),
                                    Tab(text: 'Staff / Salesman'),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 400.ms),
                              SizedBox(height: r.h(32)),

                              // ─── Inputs ──────────────────────────────────
                              _buildPremiumInput(
                                r: r,
                                controller: _emailCtrl,
                                hint: 'Email or Employee ID',
                                icon: RemixIcons.mail_line,
                                isObscure: false,
                                keyboardType: TextInputType.text,
                                autocorrect: false,
                                enableSuggestions: false,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email or Employee ID is required';
                                  return null;
                                },
                              ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0),
                              SizedBox(height: r.h(16)),
                              _buildPremiumInput(
                                r: r,
                                controller: _passCtrl,
                                hint: 'Password',
                                icon: RemixIcons.lock_line,
                                isObscure: _obscure,
                                autocorrect: false,
                                enableSuggestions: false,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscure ? RemixIcons.eye_off_line : RemixIcons.eye_line,
                                    color: AppColors.primary.withValues(alpha: 0.6),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Password is required';
                                  if (v.length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),

                              // ─── Error Message ───────────────────────────
                              if (authState.errorMessage != null) ...[
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.error.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(RemixIcons.error_warning_line, color: Colors.white, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          authState.errorMessage!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn().shakeX(hz: 4),
                              ],

                              const SizedBox(height: 32),

                              // ─── Forgot Password Link ───────────────────────
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ForgotPasswordView(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 650.ms).slideX(begin: 0.1, end: 0),

                              const SizedBox(height: 16),

                              // ─── Sign In Button ──────────────────────────
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(r.w(16)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: authState.isLoading
                                      ? null
                                      : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: r.h(18)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(r.w(16)),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: authState.isLoading
                                      ? SizedBox(
                                          height: r.w(20),
                                          width: r.w(20),
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: r.sp(16),
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                ),
                              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: r.h(32)),

                  // ─── Biometric Hint ──────────────────────────────────────
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.w(20),
                      vertical: r.h(12),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(r.w(20)),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(RemixIcons.fingerprint_line, color: AppColors.primary, size: r.w(16)),
                        SizedBox(width: r.w(8)),
                        Text(
                          'Biometric login available after first sign-in',
                          style: TextStyle(
                            color: const Color(0xFF4A6B63),
                            fontSize: r.sp(12),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumInput({
    required AppResponsive r,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isObscure,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool autocorrect = true,
    bool enableSuggestions = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      style: TextStyle(
        color: const Color(0xFF14473C),
        fontSize: r.sp(15),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: const Color(0xFF7CA69E),
          fontSize: r.sp(14),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFF3FAF8),
        prefixIcon: Icon(icon, color: AppColors.primary.withValues(alpha: 0.8), size: r.w(20)),
        suffixIcon: suffix,
        contentPadding: EdgeInsets.symmetric(
          horizontal: r.w(20),
          vertical: r.h(18),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.w(16)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.w(16)),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.w(16)),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r.w(16)),
          borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.8), width: 1),
        ),
      ),
      validator: validator,
      onChanged: (_) => ref.read(authViewModelProvider.notifier).clearError(),
    );
  }
}
