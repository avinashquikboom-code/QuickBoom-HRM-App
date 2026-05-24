import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../auth/login_view.dart';
import 'employee_documents_view.dart';
import 'employee_expenses_view.dart';
import 'employee_shift_view.dart';

class EmployeeProfileView extends ConsumerWidget {
  const EmployeeProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).currentUser;
    if (user == null) return const Scaffold();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: false,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout_rounded,
                size: 18, color: AppColors.error),
            label: const Text('Logout',
                style: TextStyle(color: AppColors.error, fontSize: 13)),
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── Profile Header ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4), width: 3),
                    ),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.designation,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      user.employeeId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Personal Info ───────────────────────────────────────
                  _SectionCard(
                    title: 'Personal Information',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _InfoRow(
                          label: 'Full Name',
                          value: user.name,
                          icon: Icons.badge_outlined),
                      _InfoRow(
                          label: 'Email',
                          value: user.email,
                          icon: Icons.email_outlined),
                      _InfoRow(
                          label: 'Phone',
                          value: user.phone,
                          icon: Icons.phone_outlined),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ─── Employment Info ─────────────────────────────────────
                  _SectionCard(
                    title: 'Employment Details',
                    icon: Icons.work_outline_rounded,
                    children: [
                      _InfoRow(
                          label: 'Department',
                          value: user.department,
                          icon: Icons.business_outlined),
                      _InfoRow(
                          label: 'Designation',
                          value: user.designation,
                          icon: Icons.work_outline_rounded),
                      _InfoRow(
                          label: 'Joining Date',
                          value: DateFormat('dd MMMM yyyy')
                              .format(user.joinDate),
                          icon: Icons.calendar_today_outlined),
                      _InfoRow(
                          label: 'Experience',
                          value: '${user.yearsOfService}+ years',
                          icon: Icons.timeline_rounded),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ─── Salary Info ─────────────────────────────────────────
                  _SectionCard(
                    title: 'Salary',
                    icon: Icons.account_balance_wallet_outlined,
                    children: [
                      _InfoRow(
                        label: 'Monthly CTC',
                        value:
                            '₹${NumberFormat('#,##,###').format(user.salary)}',
                        icon: Icons.currency_rupee_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ─── Quick Links ─────────────────────────────────────────
                  _SectionCard(
                    title: 'Quick Links',
                    icon: Icons.link_rounded,
                    children: [
                      _ActionRow(
                        label: 'My Documents',
                        icon: Icons.folder_outlined,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeDocumentsView()));
                        },
                      ),
                      _ActionRow(
                        label: 'Expense Claims',
                        icon: Icons.receipt_long_outlined,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeExpensesView()));
                        },
                      ),
                      _ActionRow(
                        label: 'My Shift Schedule',
                        icon: Icons.schedule_rounded,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeShiftView()));
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ─── Logout ──────────────────────────────────────────────
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    onPressed: () => _confirmLogout(context, ref),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(authViewModelProvider.notifier).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginView()),
                (_) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
