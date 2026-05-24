import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/user_model.dart';
import '../employee/employee_shell.dart';
import '../hr/hr_shell.dart';
import '../widgets/premium_animated_background.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController(text: 'QB001');
  final _passCtrl = TextEditingController(text: 'emp123');
  bool _obscure = true;
  bool _isHr = false;
  TabController? _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_tabController == null) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) return;
        setState(() {
          _isHr = _tabController!.index == 1;
          _idCtrl.text = _isHr ? 'HR001' : 'QB001';
          _passCtrl.text = _isHr ? 'hr123' : 'emp123';
          ref.read(authViewModelProvider.notifier).clearError();
        });
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref
        .read(authViewModelProvider.notifier)
        .login(_idCtrl.text, _passCtrl.text);
    if (success && mounted) {
      final user = ref.read(authViewModelProvider).currentUser!;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => user.role == UserRole.hrManager
              ? const HrShell()
              : const EmployeeShell(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: PremiumAnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ─── Logo & Header ─────────────────────────────────────────
                  Container(
                    width: 80,
                    height: 80,
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
                    child: const Icon(
                      Icons.corporate_fare_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 20),
                  const Text(
                    'QuickBoom',
                    style: TextStyle(
                      color: Color(0xFF14473C),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 4),
                  const Text(
                    'Elevate your workspace',
                    style: TextStyle(
                      color: Color(0xFF4A6B63),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 40),

                  // ─── Glassmorphism Card ──────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(32),
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
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F3F1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: TabBar(
                                  controller: _tabController,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  dividerColor: Colors.transparent,
                                  indicator: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
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
                                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                  tabs: const [
                                    Tab(text: 'Employee'),
                                    Tab(text: 'HR Manager'),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 400.ms),
                              const SizedBox(height: 32),

                              // ─── Inputs ──────────────────────────────────
                              _buildPremiumInput(
                                controller: _idCtrl,
                                hint: _isHr ? 'HR ID (e.g. HR001)' : 'Employee ID (e.g. QB001)',
                                icon: Icons.badge_rounded,
                                isObscure: false,
                              ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0),
                              const SizedBox(height: 16),
                              _buildPremiumInput(
                                controller: _passCtrl,
                                hint: 'Password',
                                icon: Icons.lock_rounded,
                                isObscure: _obscure,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    color: AppColors.primary.withValues(alpha: 0.6),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),

                              // ─── Error Message ───────────────────────────
                              if (authState.errorMessage != null) ...[
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          authState.errorMessage!,
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn().shakeX(hz: 4),
                              ],

                              const SizedBox(height: 32),

                              // ─── Sign In Button ──────────────────────────
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: authState.isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: authState.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 16,
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

                  const SizedBox(height: 32),

                  // ─── Demo Info ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Demo: HR001 (HR) | QB001 (Emp)',
                          style: TextStyle(
                            color: const Color(0xFF14473C),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isObscure,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Color(0xFF14473C), fontSize: 15, fontWeight: FontWeight.w600),
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF7CA69E), fontSize: 14, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: const Color(0xFFF3FAF8),
        prefixIcon: Icon(icon, color: AppColors.primary.withValues(alpha: 0.8), size: 20),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.8), width: 1),
        ),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      onChanged: (_) => ref.read(authViewModelProvider.notifier).clearError(),
    );
  }
}
