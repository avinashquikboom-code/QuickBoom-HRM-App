import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';
import '../auth/login_view.dart';
import 'edit_profile_view.dart';
import 'employee_expenses_view.dart';
import 'employee_shift_view.dart';
import 'change_password_view.dart';
import 'theme_settings_view.dart';

class EmployeeProfileView extends ConsumerStatefulWidget {
  const EmployeeProfileView({super.key});

  @override
  ConsumerState<EmployeeProfileView> createState() =>
      _EmployeeProfileViewState();
}

class _EmployeeProfileViewState extends ConsumerState<EmployeeProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileViewModelProvider.notifier).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileViewModelProvider);
    final user = profileState.user;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (profileState.isLoading) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(RemixIcons.error_warning_line,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                profileState.errorMessage ?? 'Failed to load profile',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(profileViewModelProvider.notifier).fetchProfile(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'My Profile',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              RemixIcons.logout_box_line,
              color: AppColors.error,
              size: 20,
            ),
            onPressed: () => _confirmLogout(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Profile Header Card ──────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : AppColors.cardBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black26
                            : AppColors.primary.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            user.initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ).animate().scale(
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 4),
                      Text(
                        user.designation,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.55),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : AppColors.textHint.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          user.employeeId,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.55),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─── Personal Info ─────────────────────────────────────────
                _SectionCard(
                  title: 'Personal Information',
                  icon: RemixIcons.user_3_line,
                  children: [
                    _InfoRow(
                        label: 'Full Name',
                        value: user.name,
                        icon: RemixIcons.profile_line),
                    _InfoRow(
                        label: 'Email Address',
                        value: user.email,
                        icon: RemixIcons.mail_line),
                    _InfoRow(
                        label: 'Contact Number',
                        value: user.phone,
                        icon: RemixIcons.phone_line),
                  ],
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 16),

                // ─── Employment Info ───────────────────────────────────────
                _SectionCard(
                  title: 'Employment Details',
                  icon: RemixIcons.briefcase_line,
                  children: [
                    _InfoRow(
                        label: 'Department',
                        value: user.department,
                        icon: RemixIcons.government_line),
                    _InfoRow(
                        label: 'Designation',
                        value: user.designation,
                        icon: RemixIcons.briefcase_line),
                    _InfoRow(
                        label: 'Date of Joining',
                        value: DateFormat('dd MMMM yyyy').format(user.joinDate),
                        icon: RemixIcons.calendar_event_line),
                    _InfoRow(
                        label: 'Tenure',
                        value: '${user.yearsOfService}+ Years of Service',
                        icon: RemixIcons.pulse_line),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 16),

                // ─── Compensation ──────────────────────────────────────────
                _SectionCard(
                  title: 'Compensation',
                  icon: RemixIcons.wallet_line,
                  children: [
                    _InfoRow(
                        label: 'Monthly CTC',
                        value:
                            '₹${NumberFormat('#,##,###').format(user.salary)}',
                        icon: RemixIcons.money_rupee_circle_line),
                  ],
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 16),

                // ─── Quick Links ───────────────────────────────────────────
                _SectionCard(
                  title: 'Quick Access',
                  icon: RemixIcons.link_m,
                  children: [
                    _ActionRow(
                      label: 'Edit Profile',
                      icon: RemixIcons.edit_line,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileView(),
                          ),
                        );
                      },
                    ),
                    _ActionRow(
                      label: 'Submit & Track Expenses',
                      icon: RemixIcons.bill_line,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmployeeExpensesView(),
                          ),
                        );
                      },
                    ),
                    _ActionRow(
                      label: 'Weekly Shift Schedule',
                      icon: RemixIcons.time_line,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmployeeShiftView(),
                          ),
                        );
                      },
                    ),
                    _ActionRow(
                      label: 'Change Password',
                      icon: RemixIcons.lock_line,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordView(),
                          ),
                        );
                      },
                    ),
                    _ActionRow(
                      label: 'Theme Settings',
                      icon: RemixIcons.sun_line,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ThemeSettingsView(),
                          ),
                        );
                      },
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05, end: 0),

                const SizedBox(height: 24),

                // ─── Logout Button ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.4),
                          width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(RemixIcons.logout_box_line, size: 18),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    onPressed: () => _confirmLogout(context, ref),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout Confirmation',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Theme.of(ctx).colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to securely end your current session?',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(ctx)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(ctx).colorScheme.primary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              ref.read(profileViewModelProvider.notifier).clearCachedData();
              ref.read(authViewModelProvider.notifier).logout();
              Navigator.of(ctx).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginView()),
                (_) => false,
              );
            },
            child: const Text(
              'End Session',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Card ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              isDark ? const Color(0xFF334155) : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: isDark
                  ? const Color(0xFF334155)
                  : AppColors.cardBorder),
          ...children,
        ],
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: cs.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Row ───────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(
              RemixIcons.arrow_right_s_line,
              size: 20,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}
