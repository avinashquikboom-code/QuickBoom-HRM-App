import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import '../../core/constants/app_colors.dart';
import '../../models/document_model.dart';

class EmployeeDocumentsView extends StatelessWidget {
  const EmployeeDocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for documents
    final docs = [
      DocumentModel(
        id: 'D001',
        title: 'April 2025 Payslip',
        type: DocumentType.payslip,
        date: DateTime(2025, 4, 30),
        fileSize: '1.2 MB',
        period: 'April 2025',
      ),
      DocumentModel(
        id: 'D002',
        title: 'March 2025 Payslip',
        type: DocumentType.payslip,
        date: DateTime(2025, 3, 31),
        fileSize: '1.1 MB',
        period: 'March 2025',
      ),
      DocumentModel(
        id: 'D003',
        title: 'Offer Letter',
        type: DocumentType.offerLetter,
        date: DateTime(2023, 1, 10),
        fileSize: '2.5 MB',
      ),
      DocumentModel(
        id: 'D004',
        title: 'Employee Handbook 2025',
        type: DocumentType.policy,
        date: DateTime(2025, 1, 1),
        fileSize: '8.4 MB',
      ),
      DocumentModel(
        id: 'D005',
        title: 'IT Asset Policy',
        type: DocumentType.policy,
        date: DateTime(2024, 6, 15),
        fileSize: '3.1 MB',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'My Documents',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _DocumentCard(doc: docs[i]),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentModel doc;
  const _DocumentCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(doc.typeIcon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      doc.typeLabel,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    const Text('•',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textHint)),
                    Text(
                      DateFormat('MMM yyyy').format(doc.date),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const Text('•',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textHint)),
                    Text(
                      doc.fileSize,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(RemixIcons.download_line, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading ${doc.title}...'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
