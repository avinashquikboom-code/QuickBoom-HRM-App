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

  
  Future<void> fetchDocuments() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('🔄 Fetching documents from backend...');
      final response = await ApiService.get(AppUrl.employeeDocuments);
      final data = jsonDecode(response.body);

      final List rawDocuments = data['documents'] ?? [];
      
      final List<DocumentModel> documents = rawDocuments.map((doc) {
        // Parse document type
        DocumentType docType;
        switch ((doc['type'] ?? 'other').toString().toLowerCase()) {
          case 'payslip':
            docType = DocumentType.payslip;
            break;
          case 'offer_letter':
            docType = DocumentType.offerLetter;
            break;
          case 'policy':
            docType = DocumentType.policy;
            break;
          case 'certificate':
            docType = DocumentType.certificate;
            break;
          case 'other':
          default:
            docType = DocumentType.other;
            break;
        }

        // Parse date
        DateTime docDate;
        try {
          docDate = DateTime.parse(doc['date'].toString());
        } catch (e) {
          docDate = DateTime.now();
        }

        return DocumentModel(
          id: doc['id']?.toString() ?? '',
          title: doc['title']?.toString() ?? 'Unknown Document',
          type: docType,
          date: docDate,
          fileSize: doc['fileSize']?.toString() ?? 'Unknown size',
          period: doc['period'] ?? '',
        );
      }).toList();

      state = DocumentState(
        documents: documents,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('❌ Error fetching documents: $e');
      state = DocumentState(
        documents: [],
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
