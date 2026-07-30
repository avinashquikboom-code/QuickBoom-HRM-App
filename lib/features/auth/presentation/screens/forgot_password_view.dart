import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';

class ForgotPasswordView extends ConsumerStatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  ConsumerState<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends ConsumerState<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isVerifying = false;
  bool _isResetting = false;
  bool _isVerified = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  String? _verifiedName;
  String? _verifiedEmpCode;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Step 1: Verify Account by Employee Code / Mobile No / Email
  Future<void> _verifyAccount() async {
    final input = _identifierController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Employee Code, Mobile Number, or Email');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.post(
        '${AppUrl.baseUrl}/mobile/auth/verify-identifier',
        {'identifier': input},
      );

      final responseData = jsonDecode(response.body);

      if (responseData['success'] == true && responseData['verified'] == true) {
        setState(() {
          _isVerified = true;
          _verifiedName = responseData['employeeName'] ?? 'Employee';
          _verifiedEmpCode = responseData['employeeCode'] ?? input;
        });
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'No account found matching your details.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to verify account. Please check network connection.';
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  // Step 2: Reset Password
  Future<void> _submitResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'New password and confirm password do not match');
      return;
    }

    setState(() {
      _isResetting = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.post(
        AppUrl.forgotPassword,
        {
          'identifier': _identifierController.text.trim(),
          'newPassword': newPass,
        },
      );

      final responseData = jsonDecode(response.body);

      if (responseData['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Password reset successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Failed to reset password. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during password reset.';
      });
    } finally {
      setState(() {
        _isResetting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Reset Password',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: Icon(RemixIcons.arrow_left_line, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        RemixIcons.lock_password_line,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your Employee Code, Mobile Number, or Email to verify your account and set a new password.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 24),

              // Smart Identifier Input Box (Accepts Emp Code / Mobile No / Email)
              TextFormField(
                controller: _identifierController,
                enabled: !_isVerified,
                decoration: InputDecoration(
                  labelText: 'Employee Code / Mobile No / Email',
                  hintText: 'e.g. 074, 9876543210, or user@hopkid.com',
                  prefixIcon: Icon(
                    _isVerified ? RemixIcons.checkbox_circle_fill : RemixIcons.user_search_line,
                    color: _isVerified ? AppColors.success : AppColors.primary,
                  ),
                  suffixIcon: !_isVerified
                      ? TextButton(
                          onPressed: _isVerifying ? null : _verifyAccount,
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      : const Icon(RemixIcons.check_line, color: AppColors.success),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
                  ),
                  filled: true,
                  fillColor: _isVerified ? AppColors.success.withValues(alpha: 0.05) : Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your Employee Code, Mobile Number, or Email';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),

              // Verified Employee Badge Card
              if (_isVerified) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(RemixIcons.check_line, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _verifiedName ?? 'Employee Verified',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF065F46),
                              ),
                            ),
                            Text(
                              'Code: ${_verifiedEmpCode ?? ''} • Verified Account',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isVerified = false;
                            _verifiedName = null;
                            _verifiedEmpCode = null;
                          });
                        },
                        child: const Text('Change', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(),
              ],

              const SizedBox(height: 20),

              // Step 2: New Password Inputs (unlocked after verification or accessible directly)
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'At least 6 characters',
                  prefixIcon: Icon(RemixIcons.lock_line, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? RemixIcons.eye_off_line : RemixIcons.eye_line,
                      color: AppColors.textHint,
                    ),
                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  hintText: 'Re-enter new password',
                  prefixIcon: Icon(RemixIcons.lock_line, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? RemixIcons.eye_off_line : RemixIcons.eye_line,
                      color: AppColors.textHint,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05),

              const SizedBox(height: 24),

              // Error Banner
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(RemixIcons.error_warning_line, color: AppColors.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

              // Reset Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isResetting
                      ? null
                      : () {
                          if (!_isVerified) {
                            _verifyAccount().then((_) {
                              if (_isVerified) {
                                _submitResetPassword();
                              }
                            });
                          } else {
                            _submitResetPassword();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _isResetting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(RemixIcons.refresh_line, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Reset Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isResetting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.inputBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
