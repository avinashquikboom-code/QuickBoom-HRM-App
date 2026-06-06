import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import '../../core/constants/app_colors.dart';
import '../../models/document_model.dart';
import '../../viewmodels/document_viewmodel.dart';

class EmployeeDocumentsView extends ConsumerWidget {
  const EmployeeDocumentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentViewModelProvider);
    final vm = ref.read(documentViewModelProvider.notifier);

    // Show error snackbar if error message changes
    ref.listen<DocumentState>(documentViewModelProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

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
        actions: [
          IconButton(
            icon: const Icon(RemixIcons.refresh_line, color: AppColors.textPrimary),
            onPressed: vm.fetchDocuments,
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.documents.isEmpty
              ? const Center(
                  child: Text(
                    'No documents found.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: vm.fetchDocuments,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.documents.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _DocumentCard(
                      doc: state.documents[i],
                      onDownload: () async {
                        final isPayslip = state.documents[i].type == DocumentType.payslip;
                        final isStatic = state.documents[i].id.startsWith('static-');
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isPayslip && !isStatic 
                                ? 'Generating and downloading ${state.documents[i].title}...' 
                                : 'Downloading ${state.documents[i].title}...'),
                            backgroundColor: AppColors.primary,
                          ),
                        );

                        if (isPayslip && !isStatic) {
                          final success = await vm.downloadPayslip(state.documents[i].id);
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.errorMessage ?? 'Failed to download payslip.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else {
                          // Real document download
                          try {
                            // Show loading indicator
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Downloading document...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            
                            // Simulate download - replace with actual download logic
                            await Future.delayed(const Duration(seconds: 2));
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${state.documents[i].title} downloaded successfully.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to download document: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentModel doc;
  final VoidCallback onDownload;
  
  const _DocumentCard({
    required this.doc,
    required this.onDownload,
  });

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
            icon: const Icon(RemixIcons.download_line, color: AppColors.primary),
            onPressed: onDownload,
          ),
        ],
      ),
    );
  }
}
