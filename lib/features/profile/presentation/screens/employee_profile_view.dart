import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/features/auth/presentation/providers/auth_viewmodel.dart';
import 'package:quickboom_hrm/features/profile/presentation/providers/profile_viewmodel.dart';
import 'package:quickboom_hrm/features/auth/presentation/screens/login_view.dart';
import 'package:quickboom_hrm/features/profile/presentation/screens/edit_profile_view.dart';
import 'package:quickboom_hrm/features/expense/presentation/screens/employee_expenses_view.dart';
import 'package:quickboom_hrm/features/shift/presentation/screens/employee_shift_view.dart';
import 'package:quickboom_hrm/features/profile/presentation/screens/change_password_view.dart';
import 'package:quickboom_hrm/features/profile/presentation/screens/theme_settings_view.dart';
import 'package:quickboom_hrm/features/payroll/presentation/screens/employee_payroll_view.dart';

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
                      Stack(
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
                            child: _buildAvatarImage(user.avatar, user.initials),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _showAvatarOptions(context, ref),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: cs.surface, width: 2),
                                ),
                                child: const Icon(
                                  RemixIcons.camera_line,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                    _ActionRow(
                      label: 'View Salary History',
                      icon: RemixIcons.file_list_3_line,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmployeePayrollView(),
                          ),
                        );
                      },
                    ),
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

  Widget _buildAvatarImage(String? avatar, String initials) {
    if (avatar == null || avatar.isEmpty || avatar == '/favicon.svg') {
      return Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    try {
      if (avatar.startsWith('data:image')) {
        final base64Content = avatar.split(',').last;
        return ClipOval(
          child: Image.memory(
            base64Decode(base64Content),
            fit: BoxFit.cover,
            width: 90,
            height: 90,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      } else if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
        return ClipOval(
          child: Image.network(
            avatar,
            fit: BoxFit.cover,
            width: 90,
            height: 90,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      } else {
        return ClipOval(
          child: Image.memory(
            base64Decode(avatar),
            fit: BoxFit.cover,
            width: 90,
            height: 90,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      return Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }
  }

  void _showAvatarOptions(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final profileState = ref.read(profileViewModelProvider);
    final user = profileState.user;
    final hasAvatar = user?.avatar != null && user!.avatar!.isNotEmpty && user.avatar != '/favicon.svg';

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(RemixIcons.image_line, color: AppColors.primary),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(RemixIcons.camera_line, color: AppColors.primary),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUploadImage(ImageSource.camera);
                },
              ),
              if (hasAvatar)
                ListTile(
                  leading: Icon(RemixIcons.delete_bin_line, color: AppColors.error),
                  title: Text(
                    'Remove Photo',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(profileViewModelProvider.notifier).removeAvatar();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        await ref.read(profileViewModelProvider.notifier).uploadAvatar(base64Image);
      }
    } catch (e) {
      debugPrint('Failed to pick and upload image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(profileViewModelProvider.notifier).clearCachedData();
              ref.read(authViewModelProvider.notifier).logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
                (route) => false,
              );
            },
            child: Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
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
