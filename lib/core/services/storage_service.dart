import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central service for all SharedPreferences interactions.
///
/// All storage keys are defined here as private constants so they
/// cannot be mis-spelled across the codebase.
class StorageService {
  StorageService._(); // prevent instantiation

  // ─── Keys ──────────────────────────────────────────────────────────────────
  static const String _tokenKey          = 'auth_token';
  static const String _onboardingKey     = 'hasSeenOnboarding';
  static const String _lastEmailKey      = 'last_login_email';
  static const String _userRoleKey       = 'cached_user_role';

  /// Public alias so ApiService can reference the token key constant.
  static const String tokenKeyPublic = _tokenKey;

  // ─── Token ─────────────────────────────────────────────────────────────────

  /// Save the JWT auth token received after login.
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      debugPrint('✅ Token saved to storage');
    } catch (e) {
      debugPrint('❌ Failed to save token: $e');
    }
  }

  /// Read the stored JWT token. Returns null if none exists.
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      debugPrint('❌ Failed to read token: $e');
      return null;
    }
  }

  /// Delete the stored token (used on logout).
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      debugPrint('🗑️ Token cleared from storage');
    } catch (e) {
      debugPrint('❌ Failed to clear token: $e');
    }
  }

  /// Whether a valid (non-empty) token exists locally.
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ─── Onboarding ────────────────────────────────────────────────────────────

  /// Mark onboarding as completed.
  static Future<void> markOnboardingSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
    } catch (e) {
      debugPrint('❌ Failed to mark onboarding: $e');
    }
  }

  /// Returns true if the user has already seen onboarding.
  static Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // ─── Last Login Email ───────────────────────────────────────────────────────

  static Future<void> saveLastEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastEmailKey, email);
    } catch (_) {}
  }

  static Future<String?> getLastEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastEmailKey);
    } catch (_) {
      return null;
    }
  }

  // ─── Cached User Role ───────────────────────────────────────────────────────

  static Future<void> saveUserRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, role);
    } catch (_) {}
  }

  static Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userRoleKey);
    } catch (_) {
      return null;
    }
  }

  // ─── Full Logout Clear ──────────────────────────────────────────────────────

  /// Clears token and cached role on logout. Keeps onboarding flag.
  static Future<void> clearSessionData() async {
    await clearToken();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userRoleKey);
      await prefs.remove(_lastEmailKey);
    } catch (e) {
      debugPrint('❌ Failed to clear session data: $e');
    }
  }
}
