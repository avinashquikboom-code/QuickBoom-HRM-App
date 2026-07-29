import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/utils/app_responsive.dart';
import 'package:quickboom_hrm/features/auth/data/models/user_model.dart';
import 'package:quickboom_hrm/features/auth/presentation/providers/auth_viewmodel.dart';
import 'package:quickboom_hrm/features/dashboard/presentation/screens/employee_shell.dart';
import 'package:quickboom_hrm/features/dashboard/presentation/screens/hr_shell.dart';
import 'package:quickboom_hrm/core/widgets/premium_animated_background.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _mobileCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final mobileNo = _mobileCtrl.text.trim();
    final employeeCode = _codeCtrl.text.trim();
    final password = _passCtrl.text;

    final success = await ref.read(authViewModelProvider.notifier).register(
          mobileNo: mobileNo,
          employeeCode: employeeCode,
          password: password,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Welcome to HopKid.'),
          backgroundColor: AppColors.primary,
        ),
      );

      final authState = ref.read(authViewModelProvider);
      if (authState.currentUser != null) {
        final isHr = authState.currentUser!.role == UserRole.hrManager;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => isHr ? const HrShell() : const EmployeeShell(),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      body: PremiumAnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: r.w(24),
              vertical: r.h(16),
            ),
            child: Column(
              children: [
                // App Bar / Back Navigation
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      padding: EdgeInsets.all(r.w(8)),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        RemixIcons.arrow_left_line,
                        color: AppColors.textPrimary,
                        size: r.w(20),
                      ),
                    ),
                  ),
                ),

                  SizedBox(height: r.h(12)),

                  // Logo & Header
                  Container(
                    width: r.w(70),
                    height: r.w(70),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(r.w(12)),
                    child: Image.asset(
                      'assets/icons/hopkid_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        RemixIcons.user_add_line,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ).animate().scale(duration: 400.ms),

                  SizedBox(height: r.h(16)),

                  Text(
                    'Employee Registration',
                    style: TextStyle(
                      fontSize: r.sp(24),
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ).animate().fadeIn().slideY(begin: -0.2, end: 0),

                  SizedBox(height: r.h(6)),

                  Text(
                    'Create your HopKid HRM account',
                    style: TextStyle(
                      fontSize: r.sp(14),
                      color: AppColors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  SizedBox(height: r.h(28)),

                  // Glassmorphism Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(r.w(24)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: EdgeInsets.all(r.w(24)),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(r.w(24)),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Error Message Display
                              if (authState.errorMessage != null) ...[
                                Container(
                                  padding: EdgeInsets.all(r.w(12)),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(r.w(12)),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        RemixIcons.error_warning_line,
                                        color: Colors.red.shade700,
                                        size: r.w(18),
                                      ),
                                      SizedBox(width: r.w(8)),
                                      Expanded(
                                        child: Text(
                                          authState.errorMessage!,
                                          style: TextStyle(
                                            color: Colors.red.shade800,
                                            fontSize: r.sp(12),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(),
                                SizedBox(height: r.h(16)),
                              ],

                              // Mobile Number Input
                              _buildInputField(
                                r: r,
                                controller: _mobileCtrl,
                                label: 'Mobile Number',
                                hint: 'e.g. 8866686203',
                                icon: RemixIcons.phone_line,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Mobile number is required';
                                  }
                                  final digits = value.replaceAll(RegExp(r'\D'), '');
                                  if (digits.length < 10) {
                                    return 'Please enter a valid 10-digit mobile number';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: r.h(16)),

                              // Employee Code Input
                              _buildInputField(
                                r: r,
                                controller: _codeCtrl,
                                label: 'Employee Code',
                                hint: 'e.g. 074',
                                icon: RemixIcons.hashtag,
                                textCapitalization: TextCapitalization.characters,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Employee code is required';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: r.h(16)),

                              // Password Input
                              _buildInputField(
                                r: r,
                                controller: _passCtrl,
                                label: 'Password',
                                hint: 'At least 6 characters',
                                icon: RemixIcons.lock_password_line,
                                isObscure: _obscurePass,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePass ? RemixIcons.eye_off_line : RemixIcons.eye_line,
                                    color: AppColors.textSecondary,
                                    size: r.w(18),
                                  ),
                                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: r.h(16)),

                              // Confirm Password Input
                              _buildInputField(
                                r: r,
                                controller: _confirmPassCtrl,
                                label: 'Confirm Password',
                                hint: 'Re-enter your password',
                                icon: RemixIcons.shield_keyhole_line,
                                isObscure: _obscureConfirmPass,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPass ? RemixIcons.eye_off_line : RemixIcons.eye_line,
                                    color: AppColors.textSecondary,
                                    size: r.w(18),
                                  ),
                                  onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passCtrl.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: r.h(24)),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: r.h(52),
                                child: ElevatedButton(
                                  onPressed: authState.isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(r.w(16)),
                                    ),
                                    elevation: 4,
                                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
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
                                          'Register',
                                          style: TextStyle(
                                            fontSize: r.sp(16),
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                  SizedBox(height: r.h(24)),

                  // Already registered link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: r.sp(13),
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: r.sp(13),
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),
          ),
        ),
      );
    }

  Widget _buildInputField({
    required AppResponsive r,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool isObscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: r.sp(13),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: r.h(6)),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: TextStyle(
            fontSize: r.sp(14),
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontSize: r.sp(14),
            ),
            prefixIcon: Icon(icon, color: AppColors.primary, size: r.w(18)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: r.w(16),
              vertical: r.h(14),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(r.w(12)),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(r.w(12)),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(r.w(12)),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(r.w(12)),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
