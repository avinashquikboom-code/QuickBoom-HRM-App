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

      final emp = data['employee'];
      final prof = data['profile'];
      final uRole = (data['user']?['role'] ?? 'EMPLOYEE').toString().toUpperCase();

      final parsedUser = UserModel(
        id: emp['id'].toString(),
        employeeId: emp['employeeCode'].toString(),
        name: emp['name'].toString(),
        email: prof['email'].toString(),
        phone: prof['phone'].toString(),
        role: (uRole == 'HR' || uRole == 'SUPER_ADMIN' || uRole == 'ADMIN' || uRole == 'PLATFORM_ADMIN')
            ? UserRole.hrManager
            : UserRole.employee,
        department: emp['department'].toString(),
        designation: emp['designation'].toString(),
        joinDate: DateTime.tryParse(emp['joinDate'].toString()) ?? DateTime.now(),
        salary: 65000.0,
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
