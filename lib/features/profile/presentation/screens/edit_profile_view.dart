import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/features/profile/presentation/providers/profile_viewmodel.dart';

class EditProfileView extends ConsumerStatefulWidget {
  const EditProfileView({super.key});

  @override
  ConsumerState<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends ConsumerState<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _initialized = false;

  String? _selectedDepartmentId;
  String _selectedShiftType = 'MORNING';
  String _selectedWorkMode = 'OFFICE';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileViewModelProvider.notifier).fetchDepartments();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(ProfileState state) {
    if (!_initialized && state.user != null) {
      _nameCtrl.text = state.user!.name;
      _phoneCtrl.text = state.user!.phone;
      _bioCtrl.text = ''; // bio is not stored in UserModel; leave empty for now
      _selectedShiftType = state.user!.shiftType ?? 'MORNING';
      _selectedWorkMode = state.user!.workMode ?? 'OFFICE';
      _selectedDepartmentId = state.user!.departmentId;
      _initialized = true;
    }

    // Keep selected department valid when the dropdown list loads
    if (state.departments.isNotEmpty &&
        _selectedDepartmentId != null &&
        !state.departments.any((d) => d.id == _selectedDepartmentId)) {
      _selectedDepartmentId = state.departments.first.id;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(profileViewModelProvider.notifier).updateProfile(
          fullName: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          bio: _bioCtrl.text.trim(),
          departmentId: _selectedDepartmentId,
          shiftType: _selectedShiftType,
          workMode: _selectedWorkMode,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileViewModelProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _prefillIfNeeded(state);

    // Listen for success → pop back
    ref.listen<ProfileState>(profileViewModelProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(profileViewModelProvider.notifier).clearMessages();
        Navigator.of(context).pop();
      }
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(profileViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(RemixIcons.arrow_left_line, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (state.isUpdating)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Avatar ────────────────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      child: _buildAvatarImage(
                        state.user?.avatar,
                        state.user?.initials ?? '?',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 2),
                        ),
                        child: const Icon(
                          RemixIcons.pencil_line,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 450.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 8),
              Center(
                child: Text(
                  state.user?.name ?? '',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ─── Section Label ─────────────────────────────────────────
              _sectionLabel(context, 'Personal Details'),

              const SizedBox(height: 12),

              // ─── Full Name ─────────────────────────────────────────────
              _buildField(
                context: context,
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: RemixIcons.user_3_line,
                isDark: isDark,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  if (v.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ─── Phone ─────────────────────────────────────────────────
              _buildField(
                context: context,
                controller: _phoneCtrl,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                icon: RemixIcons.phone_line,
                isDark: isDark,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (v.trim().length < 10) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              _sectionLabel(context, 'About You'),

              const SizedBox(height: 12),

              // ─── Bio ───────────────────────────────────────────────────
              _buildField(
                context: context,
                controller: _bioCtrl,
                label: 'Bio / Short Description',
                hint: 'Write a short bio (optional)',
                icon: RemixIcons.file_text_line,
                isDark: isDark,
                maxLines: 4,
                validator: null,
              ),

              const SizedBox(height: 24),

              _sectionLabel(context, 'Department & Shift'),

              const SizedBox(height: 12),

              // ─── Department ────────────────────────────────────────────
              _buildDropdown<String?>(
                context: context,
                label: 'Department',
                icon: RemixIcons.building_line,
                isDark: isDark,
                value: _selectedDepartmentId,
                items: state.departments
                    .map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDepartmentId = v),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Department is required' : null,
              ),

              const SizedBox(height: 16),

              // ─── Shift Type ────────────────────────────────────────────
              _buildDropdown<String>(
                context: context,
                label: 'Shift Type',
                icon: RemixIcons.time_line,
                isDark: isDark,
                value: _selectedShiftType,
                items: const [
                  DropdownMenuItem(value: 'MORNING', child: Text('Morning Shift')),
                  DropdownMenuItem(value: 'EVENING', child: Text('Evening Shift')),
                  DropdownMenuItem(value: 'NIGHT', child: Text('Night Shift')),
                  DropdownMenuItem(value: 'ON_FIELD', child: Text('On Field Shift')),
                ],
                onChanged: (v) => setState(() => _selectedShiftType = v ?? 'MORNING'),
              ),

              const SizedBox(height: 16),

              // ─── Work Mode ─────────────────────────────────────────────
              _buildDropdown<String>(
                context: context,
                label: 'Work Mode',
                icon: RemixIcons.briefcase_line,
                isDark: isDark,
                value: _selectedWorkMode,
                items: const [
                  DropdownMenuItem(value: 'OFFICE', child: Text('Office (On-site)')),
                  DropdownMenuItem(value: 'HYBRID', child: Text('Hybrid')),
                  DropdownMenuItem(value: 'REMOTE', child: Text('Remote')),
                ],
                onChanged: (v) => setState(() => _selectedWorkMode = v ?? 'OFFICE'),
              ),

              const SizedBox(height: 32),

              // ─── Save Button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.isUpdating ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  child: state.isUpdating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 12),

              // ─── Read-only info note ───────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(RemixIcons.information_line,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Designation and salary details can only be updated by your HR team.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: cs.onSurface.withValues(alpha: 0.4),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        color: cs.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.55),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.35),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon,
            size: 18, color: cs.onSurface.withValues(alpha: 0.45)),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color:
                  isDark ? const Color(0xFF334155) : AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color:
                  isDark ? const Color(0xFF334155) : AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 16 : 14,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isDark,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    String? hint,
  }) {
    final cs = Theme.of(context).colorScheme;

    // Deduplicate items by value to prevent duplicate value errors
    final Map<T, DropdownMenuItem<T>> uniqueItems = {};
    for (final item in items) {
      if (item.value != null && !uniqueItems.containsKey(item.value)) {
        uniqueItems[item.value as T] = item;
      }
    }
    final List<DropdownMenuItem<T>> cleanItems = uniqueItems.values.toList();

    // Ensure selected value is present in cleanItems
    final T? validValue = cleanItems.any((item) => item.value == value) ? value : null;

    return DropdownButtonFormField<T>(
      key: ValueKey(validValue),
      value: validValue,
      items: cleanItems,
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.55),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.35),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon,
            size: 18, color: cs.onSurface.withValues(alpha: 0.45)),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color:
                  isDark ? const Color(0xFF334155) : AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color:
                  isDark ? const Color(0xFF334155) : AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
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
            fontSize: 34,
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
                  fontSize: 34,
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
                  fontSize: 34,
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
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      }
    } catch (_) {
      return Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }
  }
}
