import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Central service for all SharedPreferences and secure storage interactions.
///
/// All storage keys are defined here as private constants so they
/// cannot be mis-spelled across the codebase.
class StorageService {
  StorageService._(); // prevent instantiation

  // FlutterSecureStorage instance for tokens
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // ─── Keys ──────────────────────────────────────────────────────────────────
  static const String _empTokenKey         = 'emp_token';
  static const String _hrTokenKey          = 'hr_token';
  static const String _empRefreshTokenKey  = 'emp_refresh_token';
  static const String _hrRefreshTokenKey   = 'hr_refresh_token';
  static const String _activeRoleKey       = 'active_role';
  static const String _onboardingKey       = 'hasSeenOnboarding';
  static const String _lastEmailKey        = 'last_login_email';
  static const String _userRoleKey         = 'cached_user_role';
  static const String _fcmTokenKey         = 'fcm_token';

  /// Public alias so ApiService can reference the token key constant.
  static const String tokenKeyPublic = _empTokenKey;

  // ─── Token ─────────────────────────────────────────────────────────────────

  /// Save the JWT auth token received after login.
  static Future<void> saveToken(String token, String role) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_activeRoleKey, role);
      if (role == 'HR') {
        await _secureStorage.write(key: _hrTokenKey, value: token);
      } else {
        await _secureStorage.write(key: _empTokenKey, value: token);
      }
      debugPrint('✅ Access token saved to secure storage for role: $role');
    } catch (e) {
      debugPrint('❌ Failed to save access token: $e');
    }
  }

  /// Save both access and refresh tokens.
  static Future<void> saveTokens(String token, String refreshToken, String role) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_activeRoleKey, role);
      if (role == 'HR') {
        await _secureStorage.write(key: _hrTokenKey, value: token);
        await _secureStorage.write(key: _hrRefreshTokenKey, value: refreshToken);
      } else {
        await _secureStorage.write(key: _empTokenKey, value: token);
        await _secureStorage.write(key: _empRefreshTokenKey, value: refreshToken);
      }
      debugPrint('✅ Tokens saved to secure storage for role: $role');
    } catch (e) {
      debugPrint('❌ Failed to save tokens: $e');
    }
  }

  /// Save the refresh token.
  static Future<void> saveRefreshToken(String refreshToken, String role) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_activeRoleKey, role);
      if (role == 'HR') {
        await _secureStorage.write(key: _hrRefreshTokenKey, value: refreshToken);
      } else {
        await _secureStorage.write(key: _empRefreshTokenKey, value: refreshToken);
      }
      debugPrint('✅ Refresh token saved to secure storage for role: $role');
    } catch (e) {
      debugPrint('❌ Failed to save refresh token: $e');
    }
  }

  /// Read the stored JWT token. Returns null if none exists.
  static Future<String?> getToken() async {
    try {
      final prefs = await _getPrefs();
      final role = prefs.getString(_activeRoleKey);
      if (role == 'HR') {
        return await _secureStorage.read(key: _hrTokenKey);
      } else if (role == 'EMPLOYEE') {
        return await _secureStorage.read(key: _empTokenKey);
      }

      // Fallback if active role is not set: check if either token is present
      final empToken = await _secureStorage.read(key: _empTokenKey);
      if (empToken != null && empToken.isNotEmpty) {
        await prefs.setString(_activeRoleKey, 'EMPLOYEE');
        return empToken;
      }
      final hrToken = await _secureStorage.read(key: _hrTokenKey);
      if (hrToken != null && hrToken.isNotEmpty) {
        await prefs.setString(_activeRoleKey, 'HR');
        return hrToken;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to read token: $e');
      return null;
    }
  }

  /// Read the stored refresh token. Returns null if none exists.
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await _getPrefs();
      final role = prefs.getString(_activeRoleKey);
      if (role == 'HR') {
        return await _secureStorage.read(key: _hrRefreshTokenKey);
      } else if (role == 'EMPLOYEE') {
        return await _secureStorage.read(key: _empRefreshTokenKey);
      }

      // Fallback if active role is not set: check if either token is present
      final empRefreshToken = await _secureStorage.read(key: _empRefreshTokenKey);
      if (empRefreshToken != null && empRefreshToken.isNotEmpty) {
        await prefs.setString(_activeRoleKey, 'EMPLOYEE');
        return empRefreshToken;
      }
      final hrRefreshToken = await _secureStorage.read(key: _hrRefreshTokenKey);
      if (hrRefreshToken != null && hrRefreshToken.isNotEmpty) {
        await prefs.setString(_activeRoleKey, 'HR');
        return hrRefreshToken;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to read refresh token: $e');
      return null;
    }
  }

  /// Delete all stored tokens (used on logout).
  static Future<void> clearToken() async {
    try {
      final prefs = await _getPrefs();
      // Clear all tokens from secure storage
      await _secureStorage.delete(key: _hrTokenKey);
      await _secureStorage.delete(key: _empTokenKey);
      await _secureStorage.delete(key: _hrRefreshTokenKey);
      await _secureStorage.delete(key: _empRefreshTokenKey);
      await prefs.remove(_activeRoleKey);
      debugPrint('🗑️ All tokens cleared from secure storage');
    } catch (e) {
      debugPrint('❌ Failed to clear tokens: $e');
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
      final prefs = await _getPrefs();
      final success = await prefs.setBool(_onboardingKey, true);
      debugPrint('✅ Onboarding marked as seen: $success');
    } catch (e) {
      debugPrint('❌ Failed to mark onboarding: $e');
    }
  }

  /// Returns true if the user has already seen onboarding.
  static Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await _getPrefs();
      final value = prefs.getBool(_onboardingKey) ?? false;
      debugPrint('🔍 Reading onboarding flag: $value');
      return value;
    } catch (e) {
      debugPrint('❌ Failed to read onboarding flag: $e');
      return false;
    }
  }

  // ─── Last Login Email ───────────────────────────────────────────────────────

  static Future<void> saveLastEmail(String email) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_lastEmailKey, email);
    } catch (_) {}
  }

  static Future<String?> getLastEmail() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_lastEmailKey);
    } catch (_) {
      return null;
    }
  }

  // ─── Cached User Role ───────────────────────────────────────────────────────

  static Future<void> saveUserRole(String role) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_userRoleKey, role);
    } catch (_) {}
  }

  static Future<String?> getUserRole() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_userRoleKey);
    } catch (_) {
      return null;
    }
  }

  // ─── FCM Token ─────────────────────────────────────────────────────────────

  static Future<void> saveFCMToken(String token) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_fcmTokenKey, token);
      debugPrint('✅ FCM Token saved to storage');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  }

  static Future<String?> getFCMToken() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      debugPrint('❌ Failed to read FCM token: $e');
      return null;
    }
  }

  static Future<void> clearFCMToken() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_fcmTokenKey);
      debugPrint('🗑️ FCM Token cleared from storage');
    } catch (e) {
      debugPrint('❌ Failed to clear FCM token: $e');
    }
  }

  // ─── SharedPreferences Instance ───────────────────────────────────────────────

  /// Get the SharedPreferences instance (used by ApiService for WebSocket)
  static Future<SharedPreferences> getPrefs() async {
    return await _getPrefs();
  }

  // ─── Full Logout Clear ──────────────────────────────────────────────────────

  /// Clears token and cached role on logout. Keeps onboarding flag.
  static Future<void> clearSessionData() async {
    await clearToken();
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_userRoleKey);
      await prefs.remove(_lastEmailKey);
    } catch (e) {
      debugPrint('❌ Failed to clear session data: $e');
    }
  }
}
