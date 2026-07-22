import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoiceItemData {
  final String productName;
  final String sku;
  final String size;
  final String color;
  final String hsnCode;
  final int quantity;
  final double unitPrice;
  final double gstRate;
  final double totalAmount;

  InvoiceItemData({
    required this.productName,
    required this.sku,
    required this.size,
    required this.color,
    required this.hsnCode,
    required this.quantity,
    required this.unitPrice,
    required this.gstRate,
    required this.totalAmount,
  });
}

class InvoiceService {
  /// Generate PDF invoice bytes
  static Future<Uint8List> generateInvoicePdf({
    required String invoiceNumber,
    required String orderId,
    required String date,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required double totalAmount,
    List<InvoiceItemData>? items,
  }) async {
    final pdf = pw.Document();

    final formattedDate = date.isNotEmpty
        ? date
        : DateFormat('dd MMM yyyy').format(DateTime.now());

    final itemList = items ??
        [
          InvoiceItemData(
            productName: 'HopKid Premium Kids Apparel',
            sku: 'HK-APP-001',
            size: 'M',
            color: 'Navy Blue',
            hsnCode: '6204',
            quantity: 1,
            unitPrice: (totalAmount / 1.18),
            gstRate: 18.0,
            totalAmount: totalAmount,
          ),
        ];

    final totalTaxable = itemList.fold<double>(
        0.0, (sum, item) => sum + (item.unitPrice * item.quantity));
    final totalTax = totalAmount - totalTaxable;
    final cgst = totalTax / 2;
    final sgst = totalTax / 2;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'HopKid Retail',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'TAX INVOICE / BILL OF SUPPLY',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'Original for Recipient',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Invoice #: $invoiceNumber',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text('Order ID: $orderId',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Date: $formattedDate',
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 12),

              // Seller & Customer Details
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Sold By:',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          ),
                          pw.Text('HopKid Retail Pvt Ltd',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                            'Plot 42, Industrial Sector 62, Noida, UP 201301',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text('GSTIN: 09AAACH2426J1Z5',
                              style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Customer Details:',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                          ),
                          pw.Text(
                            customerName.isNotEmpty
                                ? customerName
                                : 'Walk-in Customer',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (customerPhone.isNotEmpty)
                            pw.Text('Phone: $customerPhone',
                                style: const pw.TextStyle(fontSize: 8)),
                          pw.Text(
                            customerAddress.isNotEmpty
                                ? customerAddress
                                : 'Main Market Branch Store',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Items Table
              pw.Text(
                'ORDER ITEMS DETAILS',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Item Description',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('HSN',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Qty',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Unit Price (Rs)',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('Total (Rs)',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Table Body
                  ...itemList.map(
                    (item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(item.productName,
                                  style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(
                                'Size: ${item.size}  |  Color: ${item.color}  |  SKU: ${item.sku}',
                                style: const pw.TextStyle(
                                    fontSize: 7.5, color: PdfColors.grey700),
                              ),
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(item.hsnCode,
                              style: const pw.TextStyle(fontSize: 8.5)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${item.quantity}',
                              style: const pw.TextStyle(fontSize: 8.5)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(item.unitPrice.toStringAsFixed(2),
                              style: const pw.TextStyle(fontSize: 8.5)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(item.totalAmount.toStringAsFixed(2),
                              style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Tax Breakdown & Grand Total Box
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Tax Breakdown:',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                              'Taxable Value: Rs ${totalTaxable.toStringAsFixed(2)}',
                              style: const pw.TextStyle(fontSize: 8)),
                          pw.Text(
                              'CGST (9%): Rs ${cgst.toStringAsFixed(2)}',
                              style: const pw.TextStyle(fontSize: 8)),
                          pw.Text(
                              'SGST (9%): Rs ${sgst.toStringAsFixed(2)}',
                              style: const pw.TextStyle(fontSize: 8)),
                          pw.Text(
                              'Total Tax: Rs ${totalTax.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                  fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Container(
                    width: 200,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      border: pw.Border.all(color: PdfColors.blue300),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('GRAND TOTAL',
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue900)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Rs ${totalAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          'Inclusive of all GST taxes',
                          style: const pw.TextStyle(
                              fontSize: 7.5, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // Footer Barcode & Signature
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.code128(),
                        data: orderId,
                        width: 120,
                        height: 30,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('Order: $orderId',
                          style: const pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('For HopKid Retail Pvt Ltd',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 16),
                      pw.Text('Authorized Signatory',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Download, view, print, or share the generated Invoice PDF
  static Future<void> downloadAndOpenInvoice({
    required BuildContext context,
    required String invoiceNumber,
    required String orderId,
    required String date,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required double totalAmount,
    List<InvoiceItemData>? items,
  }) async {
    try {
      final pdfBytes = await generateInvoicePdf(
        invoiceNumber: invoiceNumber,
        orderId: orderId,
        date: date,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        totalAmount: totalAmount,
        items: items,
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Invoice_${invoiceNumber.replaceAll('/', '_')}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
