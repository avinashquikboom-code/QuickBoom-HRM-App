#!/usr/bin/env dart
// ignore_for_file: avoid_print

/// HopKid Live API Test — TEST-DEL- prefixed invoices only.
/// Hits hopkidapi.3dweb.in with ≤10 HTTP calls.
/// Tests: AddSales → UpdateSales → AddCreditNote → AddSalesExchange
///
/// Run: dart run hopkid_live_test.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

const String _baseUrl = 'https://hopkidapi.3dweb.in';
const String _apiKey = 'HOPKID-MOBILE-ACCESS-API-KEY';
const String _zeroGuid = '00000000-0000-0000-0000-000000000000';

/// Invoice numbers must be unique — use milliseconds to avoid collision.
final String _suffix = DateTime.now().millisecondsSinceEpoch.toString();
final String _invoiceNo = 'TEST-DEL-$_suffix';
final String _cnNo = 'TEST-DEL-CN-$_suffix';
final String _exNo = 'TEST-DEL-EX-$_suffix';

Map<String, String> get _headers => {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-api-key': _apiKey,
    };

Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
  print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('🚀 POST $_baseUrl$path');
  print('📤 Body: ${const JsonEncoder.withIndent('  ').convert(body)}');

  final resp = await http
      .post(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 20));

  print('\n📥 Status: ${resp.statusCode}');
  print('📄 Response:\n${resp.body}');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

  try {
    return jsonDecode(resp.body) as Map<String, dynamic>;
  } catch (_) {
    return {'_raw': resp.body, '_statusCode': resp.statusCode};
  }
}

String _istNow() {
  // Convert UTC to IST (UTC+5:30) — avoid importing intl in standalone script.
  final utc = DateTime.now().toUtc();
  final ist = utc.add(const Duration(hours: 5, minutes: 30));
  return '${ist.year.toString().padLeft(4, '0')}'
      '-${ist.month.toString().padLeft(2, '0')}'
      '-${ist.day.toString().padLeft(2, '0')}'
      'T${ist.hour.toString().padLeft(2, '0')}'
      ':${ist.minute.toString().padLeft(2, '0')}'
      ':${ist.second.toString().padLeft(2, '0')}';
}

void main() async {
  print('\n🧪 HopKid Live Sales API Test');
  print('   InvoiceNo prefix: TEST-DEL-');
  print('   Salesman GUID: $_zeroGuid (walk-in / zero-GUID)');
  print('   Time (IST): ${_istNow()}\n');

  final String now = _istNow();
  final Map<String, dynamic> results = {};

  // ─── TEST 1: AddSales ──────────────────────────────────────────────────────
  print('\n[TEST 1] AddSales — minimal valid POS sale, one product, cash payment');
  final addSalesBody = {
    'SalesID': _zeroGuid,
    'SalesType': 'POS',
    'CustomerID': _zeroGuid,
    'AccountLedger': 'Cash',
    'Invoicedate': now,
    'Duedate': now,
    'InvoiceNo': _invoiceNo,
    'SalesMan': _zeroGuid,
    'CreatedBy': _zeroGuid,
    'BranchID': _zeroGuid,
    'CompanyID': _zeroGuid,
    'GrossAmount': 500.0,
    'TaxableAmount': 500.0,
    'TaxAmount': 0.0,
    'FinalAmount': 500.0,
    'NetAmount': 500.0,
    'Discount': 0.0,
    'CreateInvoiceForm': '{}',
    'SalesProductList': [
      {
        'ProductID': _zeroGuid,
        'VariantID': _zeroGuid,
        'BrandID': _zeroGuid,
        'CategoryID': _zeroGuid,
        'EmployeeID': _zeroGuid,
        'Qty': 1.0,
        'Price': 500.0,
        'Taxable': 500.0,
        'Total': 500.0,
        'Discount': 0.0,
        'TaxPercent': 0.0,
        'TaxAmount': 0.0,
        'BarcodeNo': '',
        'BatchNo': '',
        'Remark': '',
        'VasyRowID': 0,
      }
    ],
    'SalesPaymentList': [
      {'PaymentType': 'Cash', 'PaidAmount': 500.0}
    ],
    'SalesAdditionalChargeList': [],
  };

  final addRes = await _post('/api/Sales/AddSales', addSalesBody);
  results['AddSales'] = addRes;

  // Extract SalesID from response (field name may vary by API version)
  final salesId = addRes['data']?['salesID'] ??
      addRes['data']?['SalesID'] ??
      addRes['SalesID'] ??
      addRes['salesID'] ??
      addRes['Id'] ??
      addRes['id'] ??
      addRes['data']?['id'] ??
      '';

  print('\n   → SalesID returned: $salesId');
  final bool addSuccess = addRes['Success'] == true ||
      addRes['success'] == true ||
      addRes['Status'] == 'Success';

  // ─── TEST 2: UpdateSales ──────────────────────────────────────────────────
  if (addSuccess && salesId.isNotEmpty) {
    print('\n[TEST 2] UpdateSales — update sale with returned SalesID: $salesId');
    final updateBody = {
      ...addSalesBody,
      'SalesID': salesId,
      'GrossAmount': 550.0,
      'TaxableAmount': 550.0,
      'FinalAmount': 550.0,
      'NetAmount': 550.0,
      'SalesProductList': [
        {
          'ProductID': _zeroGuid,
          'VariantID': _zeroGuid,
          'BrandID': _zeroGuid,
          'CategoryID': _zeroGuid,
          'EmployeeID': _zeroGuid,
          'Qty': 1.0,
          'Price': 550.0,
          'Taxable': 550.0,
          'Total': 550.0,
          'Discount': 0.0,
          'TaxPercent': 0.0,
          'TaxAmount': 0.0,
          'BarcodeNo': '',
          'BatchNo': '',
          'Remark': '',
          'VasyRowID': 0,
        }
      ],
      'SalesPaymentList': [
        {'PaymentType': 'Cash', 'PaidAmount': 550.0}
      ],
    };
    final updateRes = await _post('/api/Sales/UpdateSales', updateBody);
    results['UpdateSales'] = updateRes;
  } else {
    print('\n[TEST 2] SKIPPED — AddSales did not return a usable SalesID');
    print('   Raw AddSales response: ${jsonEncode(addRes)}');
    results['UpdateSales'] = {'skipped': true, 'reason': 'No SalesID from AddSales'};
  }

  // ─── TEST 3: AddCreditNote ────────────────────────────────────────────────
  if (addSuccess && salesId.isNotEmpty) {
    print('\n[TEST 3] AddCreditNote — CNAmount=100 against SalesID: $salesId');
    final cnBody = {
      'CNID': _zeroGuid,
      'SalesID': salesId,
      'CNNo': _cnNo,
      'CNAmount': 100.0,
      'Salesman': _zeroGuid,
      'BranchID': _zeroGuid,
      'CompanyID': _zeroGuid,
      'CounterID': _zeroGuid,
      'CreditNoteProducts': [
        {
          'ProductID': _zeroGuid,
          'VariantID': _zeroGuid,
          'BrandID': _zeroGuid,
          'CategoryID': _zeroGuid,
          'EmployeeID': _zeroGuid,
          'Qty': 1.0,
          'Price': 100.0,
          'Taxable': 100.0,
          'Total': 100.0,
          'Discount': 0.0,
          'TaxPercent': 0.0,
          'TaxAmount': 0.0,
          'BarcodeNo': '',
          'BatchNo': '',
          'Remark': '',
          'VasyRowID': 0,
        }
      ],
    };
    final cnRes = await _post('/api/Sales/AddCreditNote', cnBody);
    results['AddCreditNote'] = cnRes;
  } else {
    print('\n[TEST 3] SKIPPED — No SalesID from AddSales');
    results['AddCreditNote'] = {'skipped': true, 'reason': 'No SalesID from AddSales'};
  }

  // ─── TEST 4: AddSalesExchange ─────────────────────────────────────────────
  if (addSuccess && salesId.isNotEmpty) {
    print('\n[TEST 4] AddSalesExchange — 1 IsOld:true (returned) + 1 IsOld:false (new)');
    final exBody = {
      'SalesExchangeID': _zeroGuid,
      'SalesID': salesId,
      'ExchangeInvoiceNo': _exNo,
      'BranchID': _zeroGuid,
      'CompanyID': _zeroGuid,
      'SalesExchangeProductList': [
        {
          'ProductID': _zeroGuid,
          'VariantID': _zeroGuid,
          'BrandID': _zeroGuid,
          'CategoryID': _zeroGuid,
          'EmployeeID': _zeroGuid,
          'Qty': 1.0,
          'Price': 500.0,
          'Taxable': 500.0,
          'Total': 500.0,
          'Discount': 0.0,
          'TaxPercent': 0.0,
          'TaxAmount': 0.0,
          'BarcodeNo': '',
          'BatchNo': '',
          'Remark': '',
          'VasyRowID': 0,
          'IsOld': true, // returned / old item
        },
        {
          'ProductID': _zeroGuid,
          'VariantID': _zeroGuid,
          'BrandID': _zeroGuid,
          'CategoryID': _zeroGuid,
          'EmployeeID': _zeroGuid,
          'Qty': 1.0,
          'Price': 600.0,
          'Taxable': 600.0,
          'Total': 600.0,
          'Discount': 0.0,
          'TaxPercent': 0.0,
          'TaxAmount': 0.0,
          'BarcodeNo': '',
          'BatchNo': '',
          'Remark': '',
          'VasyRowID': 0,
          'IsOld': false, // new item being purchased
        },
      ],
    };
    final exRes = await _post('/api/Sales/AddSalesExchange', exBody);
    results['AddSalesExchange'] = exRes;
  } else {
    print('\n[TEST 4] SKIPPED — No SalesID from AddSales');
    results['AddSalesExchange'] = {'skipped': true, 'reason': 'No SalesID from AddSales'};
  }

  // ─── Summary ───────────────────────────────────────────────────────────────
  print('\n\n╔═══════════════════════════════════════════════════╗');
  print('║              TEST RESULTS SUMMARY                ║');
  print('╠═══════════════════════════════════════════════════╣');

  for (final entry in results.entries) {
    final r = entry.value as Map<String, dynamic>;
    final skipped = r['skipped'] == true;
    final success = !skipped &&
        (r['Success'] == true || r['success'] == true || r['Status'] == 'Success');
    final icon = skipped ? '⏭️ ' : (success ? '✅' : '❌');
    print('║  $icon ${entry.key.padRight(20)} ${skipped ? "SKIPPED" : (success ? "SUCCESS" : "FAILED")}');
  }

  print('╚═══════════════════════════════════════════════════╝');
  print('\nVerbatim responses saved above ↑\n');
}
