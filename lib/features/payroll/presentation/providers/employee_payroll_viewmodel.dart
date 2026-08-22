import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quickboom_hrm/core/services/api_service.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/mobile_commission_service.dart';

class PayslipModel {
  final int id;
  final int employeeId;
  final int month;
  final int year;
  final double baseSalary;
  final double allowance;
  final double deductions;
  final double netSalary;
  final String status;
  final String employeeCode;
  final String employeeName;
  final String designation;
  final String department;
  final String officeName;
  final String netInWords;
  final String createdAt;
  final double? commissionEarned;
  final double? pendingCommission;
  final double? paidCommission;
  final int? presentDays;
  final int? halfDays;
  final double? halfDayDeduction;
  final int? leaveDays;
  final double? leaveDeduction;
  final double? advanceDeduction;
  final double? expenseReimbursement;

  PayslipModel({
    required this.id,
    required this.employeeId,
    required this.month,
    required this.year,
    required this.baseSalary,
    required this.allowance,
    required this.deductions,
    required this.netSalary,
    required this.status,
    required this.employeeCode,
    required this.employeeName,
    required this.designation,
    required this.department,
    required this.officeName,
    required this.netInWords,
    required this.createdAt,
    this.commissionEarned,
    this.pendingCommission,
    this.paidCommission,
    this.presentDays,
    this.halfDays,
    this.halfDayDeduction,
    this.leaveDays,
    this.leaveDeduction,
    this.advanceDeduction,
    this.expenseReimbursement,
  });

  factory PayslipModel.fromJson(Map<String, dynamic> json) {
    return PayslipModel(
      id: json['id'] as int? ?? 0,
      employeeId: json['employeeId'] as int? ?? 0,
      month: json['month'] as int? ?? 1,
      year: json['year'] as int? ?? 2026,
      baseSalary: (json['baseSalary'] as num?)?.toDouble() ?? 0.0,
      allowance: (json['allowance'] as num?)?.toDouble() ?? 0.0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0.0,
      netSalary: (json['netSalary'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'Pending Approval',
      employeeCode: json['employeeCode']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      officeName: json['officeName']?.toString() ?? '',
      netInWords: json['netInWords']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      commissionEarned: (json['commissionEarned'] as num?)?.toDouble(),
      pendingCommission: (json['pendingCommission'] as num?)?.toDouble(),
      paidCommission: (json['paidCommission'] as num?)?.toDouble(),
      presentDays: (json['presentDays'] as num?)?.toInt(),
      halfDays: (json['halfDays'] as num?)?.toInt(),
      halfDayDeduction: (json['halfDayDeduction'] as num?)?.toDouble(),
      leaveDays: (json['leaveDays'] as num?)?.toInt(),
      leaveDeduction: (json['leaveDeduction'] as num?)?.toDouble(),
      advanceDeduction: (json['advanceDeduction'] as num?)?.toDouble() ?? (json['deductions'] is Map ? (json['deductions']['advanceDeduction'] as num?)?.toDouble() : null),
      expenseReimbursement: (json['expenseReimbursement'] as num?)?.toDouble() ?? (json['approvedExpenses'] as num?)?.toDouble() ?? (json['approvedExpenseAmount'] as num?)?.toDouble() ?? (json['earnings'] is Map ? (json['earnings']['expenseReimbursement'] as num?)?.toDouble() : null),
    );
  }
}

class EmployeePayrollState {
  final List<PayslipModel> payslips;
  final bool isLoading;
  final String? errorMessage;

  const EmployeePayrollState({
    this.payslips = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  EmployeePayrollState copyWith({
    List<PayslipModel>? payslips,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EmployeePayrollState(
      payslips: payslips ?? this.payslips,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class EmployeePayrollViewModel extends StateNotifier<EmployeePayrollState> {
  EmployeePayrollViewModel() : super(const EmployeePayrollState()) {
    fetchPayslips();
  }

  Future<void> fetchPayslips() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await ApiService.get(AppUrl.employeePayslips);
      final data = jsonDecode(response.body);

      final List rawPayslips = data['data'] ?? [];
      final List<PayslipModel> payslips = rawPayslips
          .map((json) => PayslipModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (payslips.isNotEmpty && (payslips.first.commissionEarned == null || payslips.first.commissionEarned == 0)) {
        try {
          final commDash = await MobileCommissionService.getCommissionDashboard();
          if (commDash != null && commDash['data'] != null && commDash['data']['summary'] != null) {
            final approvedComm = (commDash['data']['summary']['approvedCommission'] ?? commDash['data']['summary']['pendingCommission'] ?? 0).toDouble();
            if (approvedComm > 0) {
              final first = payslips.first;
              payslips[0] = PayslipModel(
                id: first.id,
                employeeId: first.employeeId,
                month: first.month,
                year: first.year,
                baseSalary: first.baseSalary,
                allowance: first.allowance,
                deductions: first.deductions,
                netSalary: first.netSalary,
                status: first.status,
                employeeCode: first.employeeCode,
                employeeName: first.employeeName,
                designation: first.designation,
                department: first.department,
                officeName: first.officeName,
                netInWords: first.netInWords,
                createdAt: first.createdAt,
                commissionEarned: approvedComm,
                pendingCommission: first.pendingCommission,
                paidCommission: first.paidCommission,
                presentDays: first.presentDays,
                halfDays: first.halfDays,
                halfDayDeduction: first.halfDayDeduction,
                leaveDays: first.leaveDays,
                leaveDeduction: first.leaveDeduction,
              );
            }
          }
        } catch (commErr) {
          debugPrint('Error fetching fallback commission dashboard: $commErr');
        }
      }

      if (!mounted) return;
      state = EmployeePayrollState(
        payslips: payslips,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error fetching payslips: $e');
      if (!mounted) return;
      state = EmployeePayrollState(
        payslips: [],
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> downloadPayslip(int id) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      final baseUrl = AppUrl.baseUrl;
      final path = AppUrl.employeeDownloadPayslip(id.toString());
      final downloadUri = Uri.parse('$baseUrl$path?token=$token');

      debugPrint('📥 Opening payslip download URL: $downloadUri');

      if (await canLaunchUrl(downloadUri)) {
        await launchUrl(downloadUri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        throw Exception('Could not open the download URL in browser.');
      }
    } catch (e) {
      debugPrint('❌ Download error: $e');
      if (!mounted) return false;
      state = state.copyWith(errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> downloadPayslipByMonthYear(int month, int year) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      final baseUrl = AppUrl.baseUrl;
      final downloadUri = Uri.parse('$baseUrl/api/mobile/payroll/slips/download?month=$month&year=$year&token=$token');

      debugPrint('📥 Opening payslip download by month/year URL: $downloadUri');

      if (await canLaunchUrl(downloadUri)) {
        await launchUrl(downloadUri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        throw Exception('Could not open the download URL in browser.');
      }
    } catch (e) {
      debugPrint('❌ Download error: $e');
      if (!mounted) return false;
      state = state.copyWith(errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final employeePayrollViewModelProvider =
    StateNotifierProvider<EmployeePayrollViewModel, EmployeePayrollState>((ref) {
  return EmployeePayrollViewModel();
});
