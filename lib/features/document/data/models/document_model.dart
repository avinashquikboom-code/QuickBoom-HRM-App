enum DocumentType { payslip, offerLetter, policy, certificate, idCard, other }

class DocumentModel {
  final String id;
  final String title;
  final DocumentType type;
  final DateTime date;
  final String fileSize;
  final bool isDownloaded;
  final String? period; // e.g., "April 2025" for payslips

  const DocumentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.fileSize,
    this.isDownloaded = false,
    this.period,
  });

  String get typeLabel {
    switch (type) {
      case DocumentType.payslip:
        return 'Payslip';
      case DocumentType.offerLetter:
        return 'Offer Letter';
      case DocumentType.policy:
        return 'HR Policy';
      case DocumentType.certificate:
        return 'Certificate';
      case DocumentType.idCard:
        return 'ID Card';
      case DocumentType.other:
        return 'Document';
    }
  }

  String get typeIcon {
    switch (type) {
      case DocumentType.payslip:
        return '💰';
      case DocumentType.offerLetter:
        return '📄';
      case DocumentType.policy:
        return '📋';
      case DocumentType.certificate:
        return '🏆';
      case DocumentType.idCard:
        return '🪪';
      case DocumentType.other:
        return '📎';
    }
  }
}
