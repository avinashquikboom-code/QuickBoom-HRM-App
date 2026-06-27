import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_hrm/core/constants/app_colors.dart';
import 'package:quickboom_hrm/core/services/theme_service.dart';

class ThemeSettingsView extends ConsumerWidget {
  const ThemeSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Appearance Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildThemeTile(
            context: context,
            ref: ref,
            mode: ThemeMode.light,
            title: 'Light Mode',
            subtitle: 'Classic bright look with clear contrast',
            icon: RemixIcons.sun_line,
            isSelected: currentThemeMode == ThemeMode.light,
          ),
          const SizedBox(height: 12),
          _buildThemeTile(
            context: context,
            ref: ref,
            mode: ThemeMode.dark,
            title: 'Dark Mode',
            subtitle: 'Sleek dark look, comfortable for night viewing',
            icon: RemixIcons.moon_line,
            isSelected: currentThemeMode == ThemeMode.dark,
          ),
          const SizedBox(height: 12),
          _buildThemeTile(
            context: context,
            ref: ref,
            mode: ThemeMode.system,
            title: 'System Default',
            subtitle: 'Automatically syncs with your device settings',
            icon: RemixIcons.settings_4_line,
            isSelected: currentThemeMode == ThemeMode.system,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? AppColors.primary 
              : (isDark ? const Color(0xFF334155) : AppColors.cardBorder),
          width: isSelected ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onTap: () async {
            await ref.read(themeModeProvider.notifier).setThemeMode(mode);
          },
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary.withValues(alpha: 0.1) 
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon, 
              color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            ),
          ),
          trailing: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF475569) : AppColors.inputBorder),
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
