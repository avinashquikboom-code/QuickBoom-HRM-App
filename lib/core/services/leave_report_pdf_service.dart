import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/leave_request_model.dart';
import '../../viewmodels/leave_viewmodel.dart';

/// Builds and presents an in-app generated Leave Report PDF that includes the
/// full leave balance (Casual / Sick / Earned) and the leave history.
class LeaveReportPdfService {
  LeaveReportPdfService._();

  static final DateFormat _dateFmt = DateFormat('dd MMM yyyy');

  /// Generates the PDF and opens the native share / print sheet so the user
  /// can view, save, or share it.
  static Future<void> generateAndShare({
    required LeaveBalance balance,
    required List<LeaveRequestModel> leaves,
    String employeeName = 'Employee',
  }) async {
    final bytes = await _buildDocument(
      balance: balance,
      leaves: leaves,
      employeeName: employeeName,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'leave_report.pdf',
    );
  }

  static Future<Uint8List> _buildDocument({
    required LeaveBalance balance,
    required List<LeaveRequestModel> leaves,
    required String employeeName,
  }) async {
    final doc = pw.Document();

    const primary = PdfColor.fromInt(0xFF4F46E5);
    const lightGrey = PdfColor.fromInt(0xFFF3F4F6);
    const darkText = PdfColor.fromInt(0xFF111827);
    const subText = PdfColor.fromInt(0xFF6B7280);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          // ─── Header ───────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              color: primary,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Leave Report',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      employeeName,
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'Generated: ${_dateFmt.format(DateTime.now())}',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // ─── Leave Balance ────────────────────────────────────────
          pw.Text(
            'Leave Balance',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: darkText,
            ),
          ),
          pw.SizedBox(height: 12),
          _balanceTable(balance, primary, lightGrey, darkText),
          pw.SizedBox(height: 28),

          // ─── Leave History ────────────────────────────────────────
          pw.Text(
            'Leave History',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: darkText,
            ),
          ),
          pw.SizedBox(height: 12),
          if (leaves.isEmpty)
            pw.Text(
              'No leave records found.',
              style: const pw.TextStyle(color: subText, fontSize: 12),
            )
          else
            _historyTable(leaves, primary, lightGrey, darkText),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: subText, fontSize: 9),
          ),
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _balanceTable(
    LeaveBalance b,
    PdfColor primary,
    PdfColor lightGrey,
    PdfColor darkText,
  ) {
    pw.TableRow header() => pw.TableRow(
          decoration: pw.BoxDecoration(color: primary),
          children: [
            _cell('Leave Type', color: PdfColors.white, bold: true),
            _cell('Total', color: PdfColors.white, bold: true, center: true),
            _cell('Used', color: PdfColors.white, bold: true, center: true),
            _cell('Remaining',
                color: PdfColors.white, bold: true, center: true),
          ],
        );

    pw.TableRow row(
      String type,
      int total,
      int used,
      int remaining,
      bool shaded,
    ) =>
        pw.TableRow(
          decoration: shaded ? pw.BoxDecoration(color: lightGrey) : null,
          children: [
            _cell(type, color: darkText),
            _cell('$total', color: darkText, center: true),
            _cell('$used', color: darkText, center: true),
            _cell('$remaining', color: darkText, center: true),
          ],
        );

    final totalAll = b.casualTotal + b.sickTotal + b.earnedTotal;
    final usedAll = b.casualUsed + b.sickUsed + b.earnedUsed;
    final remainingAll =
        b.casualRemaining + b.sickRemaining + b.earnedRemaining;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        header(),
        row('Casual Leave', b.casualTotal, b.casualUsed, b.casualRemaining,
            false),
        row('Sick Leave', b.sickTotal, b.sickUsed, b.sickRemaining, true),
        row('Earned Leave', b.earnedTotal, b.earnedUsed, b.earnedRemaining,
            false),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE0E7FF)),
          children: [
            _cell('Total', color: darkText, bold: true),
            _cell('$totalAll', color: darkText, bold: true, center: true),
            _cell('$usedAll', color: darkText, bold: true, center: true),
            _cell('$remainingAll', color: darkText, bold: true, center: true),
          ],
        ),
      ],
    );
  }

  static pw.Widget _historyTable(
    List<LeaveRequestModel> leaves,
    PdfColor primary,
    PdfColor lightGrey,
    PdfColor darkText,
  ) {
    pw.TableRow header() => pw.TableRow(
          decoration: pw.BoxDecoration(color: primary),
          children: [
            _cell('Type', color: PdfColors.white, bold: true),
            _cell('From', color: PdfColors.white, bold: true),
            _cell('To', color: PdfColors.white, bold: true),
            _cell('Days', color: PdfColors.white, bold: true, center: true),
            _cell('Status', color: PdfColors.white, bold: true, center: true),
          ],
        );

    final rows = <pw.TableRow>[header()];
    for (var i = 0; i < leaves.length; i++) {
      final l = leaves[i];
      rows.add(
        pw.TableRow(
          decoration: i.isOdd ? pw.BoxDecoration(color: lightGrey) : null,
          children: [
            _cell(l.typeLabel, color: darkText),
            _cell(_dateFmt.format(l.fromDate), color: darkText),
            _cell(_dateFmt.format(l.toDate), color: darkText),
            _cell('${l.daysCount}', color: darkText, center: true),
            _cell(l.statusLabel, color: darkText, center: true),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(2.5),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }

  static pw.Widget _cell(
    String text, {
    required PdfColor color,
    bool bold = false,
    bool center = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
