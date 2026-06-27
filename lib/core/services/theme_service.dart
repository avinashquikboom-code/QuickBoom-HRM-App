import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickboom_hrm/features/auth/presentation/providers/auth_viewmodel.dart';

class ThemeService {
  ThemeService._();

  static const String _themeKeyPrefix = 'app_theme_mode_';
  static const String _globalThemeKey = 'app_theme_mode';

  static Future<ThemeMode> getThemeModeForUser(String? userKey) async {
    final prefs = await SharedPreferences.getInstance();
    final key = userKey != null && userKey.isNotEmpty
        ? '$_themeKeyPrefix$userKey'
        : _globalThemeKey;
    final themeIndex = prefs.getInt(key) ?? 1; // Default to ThemeMode.light (1)
    return ThemeMode.values[themeIndex];
  }

  static Future<void> setThemeModeForUser(String? userKey, ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final key = userKey != null && userKey.isNotEmpty
        ? '$_themeKeyPrefix$userKey'
        : _globalThemeKey;
    await prefs.setInt(key, mode.index);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier(ref);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;
  String? _currentUserKey;

  ThemeNotifier(this._ref) : super(ThemeMode.light) {
    // Listen to changes in the current user to reload theme
    _ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      final userKey = next.currentUser?.email ?? next.currentUser?.id;
      if (userKey != _currentUserKey) {
        _currentUserKey = userKey;
        _loadThemeMode(userKey);
      }
    });
    
    // Initial load
    final initialUserKey = _ref.read(authViewModelProvider).currentUser?.email ?? 
                           _ref.read(authViewModelProvider).currentUser?.id;
    _currentUserKey = initialUserKey;
    _loadThemeMode(initialUserKey);
  }

  Future<void> _loadThemeMode(String? userKey) async {
    final savedThemeMode = await ThemeService.getThemeModeForUser(userKey);
    state = savedThemeMode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final userKey = _ref.read(authViewModelProvider).currentUser?.email ?? 
                    _ref.read(authViewModelProvider).currentUser?.id;
    await ThemeService.setThemeModeForUser(userKey, mode);
    state = mode;
  }
}
