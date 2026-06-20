import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_url.dart';
import '../models/user_model.dart';

// ─── Profile State ──────────────────────────────────────────────────────────────

class ProfileState {
  final UserModel? user;
  final bool isLoading;
  final bool isUpdating;
  final String? errorMessage;
  final String? successMessage;

  const ProfileState({
    this.user,
    this.isLoading = false,
    this.isUpdating = false,
    this.errorMessage,
    this.successMessage,
  });

  ProfileState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isUpdating,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ─── Profile ViewModel ─────────────────────────────────────────────────────────

class ProfileViewModel extends StateNotifier<ProfileState> {
  ProfileViewModel() : super(const ProfileState()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final res = await ApiService.get(AppUrl.employeeProfile);
      final data = jsonDecode(res.body);

      // Handle mobile API response structure
      final user = data['user'] ?? data;
      final prof = user['profile'] as Map<String, dynamic>? ?? {};
      final emp = user['employee'] as Map<String, dynamic>? ?? {};
      final uRole = (user['role'] ?? 'EMPLOYEE').toString().toUpperCase();

      final parsedUser = UserModel(
        id: user['id']?.toString() ?? emp['id']?.toString() ?? '0',
        employeeId: emp['employeeCode']?.toString() ?? user['id']?.toString() ?? '0',
        name: prof['fullName']?.toString() ??
               '${emp['firstName']?.toString() ?? ''} ${(emp['lastName']?.toString() ?? '').trim()}',
        email: prof['email']?.toString() ?? user['email']?.toString() ?? '',
        phone: prof['phone']?.toString() ?? '',
        role: (uRole == 'HR' || uRole == 'SUPER_ADMIN' || uRole == 'ADMIN' || uRole == 'PLATFORM_ADMIN')
            ? UserRole.hrManager
            : UserRole.employee,
        department: emp['department']?.toString() ?? 'General',
        designation: emp['designation']?.toString() ?? prof['bio']?.toString() ?? 'Employee',
        joinDate: DateTime.tryParse(prof['createdAt']?.toString() ?? emp['joinDate']?.toString() ?? '') ?? DateTime.now(),
        salary: 0.0,
      );

      state = state.copyWith(user: parsedUser, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
    String? bio,
  }) async {
    state = state.copyWith(isUpdating: true, clearMessages: true);
    try {
      await ApiService.put(AppUrl.employeeProfile, {
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'bio': bio?.trim() ?? '',
      });

      await fetchProfile();
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Profile updated successfully!',
      );
    } catch (error) {
      state = state.copyWith(
        isUpdating: false,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> uploadAvatar(String imageBase64) async {
    state = state.copyWith(isUpdating: true, clearMessages: true);
    try {
      await ApiService.put(AppUrl.employeeAvatar, {
        'imageBase64': imageBase64,
      });

      await fetchProfile();
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Avatar updated successfully!',
      );
    } catch (error) {
      state = state.copyWith(
        isUpdating: false,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> removeAvatar() async {
    state = state.copyWith(isUpdating: true, clearMessages: true);
    try {
      await ApiService.delete(AppUrl.employeeAvatar);

      await fetchProfile();
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Avatar removed successfully!',
      );
    } catch (error) {
      state = state.copyWith(
        isUpdating: false,
        errorMessage: error.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final profileViewModelProvider =
    StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
  return ProfileViewModel();
});
