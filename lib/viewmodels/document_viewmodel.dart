import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/api_service.dart';
import '../core/constants/app_url.dart';
import '../models/document_model.dart';

class DocumentState {
  final List<DocumentModel> documents;
  final bool isLoading;
  final String? errorMessage;

  const DocumentState({
    this.documents = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  DocumentState copyWith({
    List<DocumentModel>? documents,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DocumentState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DocumentViewModel extends StateNotifier<DocumentState> {
  DocumentViewModel() : super(const DocumentState()) {
    fetchDocuments();
  }

  final List<DocumentModel> _staticDocs = [
    DocumentModel(
      id: 'static-offer-letter',
      title: 'Offer Letter',
      type: DocumentType.offerLetter,
      date: DateTime(2025, 1, 10),
      fileSize: '2.5 MB',
    ),
    DocumentModel(
      id: 'static-policy-handbook',
      title: 'Employee Handbook 2026',
      type: DocumentType.policy,
      date: DateTime(2026, 1, 1),
      fileSize: '8.4 MB',
    ),
    DocumentModel(
      id: 'static-policy-it',
      title: 'IT Asset Policy',
      type: DocumentType.policy,
      date: DateTime(2025, 6, 15),
      fileSize: '3.1 MB',
    ),
  ];

  Future<void> fetchDocuments() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🔄 Fetching payslips from backend...');
      final response = await ApiService.get(AppUrl.employeePayslips);
      final responseData = jsonDecode(response.body);

      final List rawPayslips = responseData['data'] ?? [];
      
      final List<DocumentModel> fetchedPayslips = rawPayslips.map((p) {
        final monthNames = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        final monthVal = p['month'] as int? ?? 1;
        final yearVal = p['year'] as int? ?? 2026;
        final monthIndex = (monthVal >= 1 && monthVal <= 12) ? monthVal - 1 : 0;
        final monthName = monthNames[monthIndex];
        final netSalary = p['netSalary'] as num? ?? 0;

        return DocumentModel(
          id: p['id'].toString(),
          title: '$monthName $yearVal Payslip',
          type: DocumentType.payslip,
          date: DateTime.tryParse(p['createdAt']?.toString() ?? '') ?? DateTime(yearVal, monthVal, 1),
          fileSize: '₹${netSalary.toStringAsFixed(0)}',
          period: '$monthName $yearVal',
        );
      }).toList();

      final allDocs = [...fetchedPayslips, ..._staticDocs];

      state = DocumentState(
        documents: allDocs,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('❌ Error fetching documents: $e');
      state = DocumentState(
        documents: _staticDocs,
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> downloadPayslip(String id) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      final baseUrl = AppUrl.baseUrl;
      final path = AppUrl.employeeDownloadPayslip(id);
      
      final downloadUri = Uri.parse('$baseUrl$path?token=$token');
      
      debugPrint('📥 Opening download URL: $downloadUri');

      if (await canLaunchUrl(downloadUri)) {
        await launchUrl(downloadUri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        throw Exception('Could not open the download URL in browser.');
      }
    } catch (e) {
      debugPrint('❌ Download error: $e');
      state = state.copyWith(errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final documentViewModelProvider =
    StateNotifierProvider<DocumentViewModel, DocumentState>((ref) {
  return DocumentViewModel();
});
