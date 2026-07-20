import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/storage_service.dart';
import 'package:quickboom_hrm/core/services/hopkid_client.dart';
import 'package:quickboom_hrm/core/services/hopkid_sales_dto.dart';

/// Service for all HopKid Sales API interactions.
///
/// Two submission paths:
///   1. [submitToHopkid] — posts directly to hopkidapi.3dweb.in using the new DTOs.
///      Used by the live sale entry UI flow.
///   2. [syncOfflineQueue] — retries queued entries through our own backend's
///      /api/Sales/Sync endpoint (which also handles commission tracking).
///      Maps old legacy payloads AND new DTO payloads to the batch format.
class SalesService {
  static final Duration _timeout = const Duration(seconds: 15);
  static const String _queueKey = 'offline_sales_queue';

  static Future<String?> _getToken() async {
    return await StorageService.getToken();
  }

  static Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-api-key': AppUrl.hopkidApiKey,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Salesman GUID helper
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the salesman's HopKid employee GUID from persistent storage.
  /// Falls back to zero-GUID when not yet matched (pre-login or no master entry).
  static Future<String> getSalesmanGuid() async {
    final stored = await StorageService.getHopkidEmployeeId();
    return stored ?? HopkidSalesConstants.zeroGuid;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Direct-to-HopKid submission (new DTOs, live path)
  // ──────────────────────────────────────────────────────────────────────────

  /// Submit an AddSales request directly to HopKid.
  ///
  /// Returns the full response map including [SalesID] on success.
  /// On network failure the payload is queued offline for later retry.
  static Future<Map<String, dynamic>> addSales(AddSalesDto dto) async {
    return _submitToHopkid(AppUrl.hopkidAddSales, dto.toJson());
  }

  /// Submit an UpdateSales request directly to HopKid.
  static Future<Map<String, dynamic>> updateSales(UpdateSalesDto dto) async {
    return _submitToHopkid(AppUrl.hopkidUpdateSales, dto.toJson());
  }

  /// Submit an AddCreditNote request directly to HopKid.
  static Future<Map<String, dynamic>> addCreditNote(AddCreditNoteDto dto) async {
    return _submitToHopkid(AppUrl.hopkidAddCreditNote, dto.toJson());
  }

  /// Submit an AddSalesExchange request directly to HopKid.
  static Future<Map<String, dynamic>> addSalesExchange(AddSalesExchangeDto dto) async {
    return _submitToHopkid(AppUrl.hopkidAddSalesExchange, dto.toJson());
  }

  /// Core HopKid POST helper — uses HopkidClient (which has retry + timeout).
  static Future<Map<String, dynamic>> _submitToHopkid(
    String path,
    Map<String, dynamic> body,
  ) async {
    dev.log('🚀 [SalesService] POST $path', name: 'SalesService');
    dev.log('📤 Body: ${jsonEncode(body)}', name: 'SalesService');

    try {
      final response = await HopkidClient.post(path, body);

      dev.log(
        '📥 [SalesService] ${response.statusCode}: ${response.body}',
        name: 'SalesService',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final resBody = jsonDecode(response.body);
        return {
          'success': true,
          'data': resBody,
          'offline': false,
        };
      } else if (response.statusCode >= 500) {
        // Server error — queue the payload offline for later retry via our backend sync.
        await queueOffline(path, body);
        return {
          'success': true,
          'message': 'Transaction queued offline due to server error',
          'offline': true,
        };
      } else {
        final resBody = _safeDecode(response.body);
        return {
          'success': false,
          'message': resBody['message'] ?? resBody['Message'] ?? 'Failed to submit transaction',
          'statusCode': response.statusCode,
          'offline': false,
          'rawResponse': response.body,
        };
      }
    } on SocketException catch (_) {
      await queueOffline(path, body);
      return {
        'success': true,
        'message': 'Connection offline. Transaction saved to sync queue.',
        'offline': true,
      };
    } catch (e) {
      dev.log('💥 [SalesService] Error submitting to HopKid: $e', name: 'SalesService');
      await queueOffline(path, body);
      return {
        'success': true,
        'message': 'Network error. Transaction saved to sync queue.',
        'offline': true,
      };
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Legacy path — routes through our own backend (kept for backward compat)
  // ──────────────────────────────────────────────────────────────────────────

  /// Sends a sales request to our own backend. If it fails due to network,
  /// it queues the transaction offline.
  ///
  /// Prefer [addSales] / [updateSales] for new code — this is kept for existing
  /// callers that use the old `/api/Sales/AddSales` style endpoints.
  static Future<Map<String, dynamic>> submitTransaction({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('${AppUrl.baseUrl}$endpoint');
    final headers = _getHeaders(token);

    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(payload))
          .timeout(_timeout);

      dev.log(
        'Sales Response ($endpoint): ${response.statusCode} - ${response.body}',
        name: 'SalesService',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final resBody = jsonDecode(response.body);
        return {
          'success': true,
          'message': resBody['message'] ?? 'Transaction submitted successfully',
          'offline': false,
        };
      } else if (response.statusCode >= 500) {
        await queueOffline(endpoint, payload);
        return {
          'success': true,
          'message': 'Transaction queued offline due to server error',
          'offline': true,
        };
      } else {
        final resBody = _safeDecode(response.body);
        return {
          'success': false,
          'message': resBody['message'] ?? 'Failed to submit transaction',
          'offline': false,
        };
      }
    } on SocketException catch (_) {
      await queueOffline(endpoint, payload);
      return {
        'success': true,
        'message': 'Connection offline. Transaction saved to sync queue.',
        'offline': true,
      };
    } catch (e) {
      dev.log('Error submitting transaction: $e', name: 'SalesService');
      await queueOffline(endpoint, payload);
      return {
        'success': true,
        'message': 'Network error. Transaction saved to sync queue.',
        'offline': true,
      };
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Offline Queue
  // ──────────────────────────────────────────────────────────────────────────

  /// Save a transaction to the offline queue in SharedPreferences.
  static Future<void> queueOffline(String endpoint, Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> queue = prefs.getStringList(_queueKey) ?? [];

      final newItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'endpoint': endpoint,
        'payload': payload,
        'timestamp': DateTime.now().toIso8601String(),
        // Flag so sync handler knows this is a new-DTO payload
        'dtoVersion': 2,
      };

      queue.add(jsonEncode(newItem));
      await prefs.setStringList(_queueKey, queue);
      dev.log('📦 Transaction queued offline: $endpoint', name: 'SalesService');
    } catch (e) {
      dev.log('Failed to queue transaction offline: $e', name: 'SalesService');
    }
  }

  /// Fetch the list of pending offline transactions.
  static Future<List<Map<String, dynamic>>> getOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> queue = prefs.getStringList(_queueKey) ?? [];
      return queue
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      dev.log('Failed to read offline queue: $e', name: 'SalesService');
      return [];
    }
  }

  /// Sync all pending offline transactions in a single batch request to our backend.
  ///
  /// Maps BOTH old legacy payloads (saleAmount, invoiceNumber) AND new DTO payloads
  /// (SalesProductList, SalesPaymentList arrays) to the backend batch format.
  ///
  /// Returns the number of successfully synced transactions.
  static Future<int> syncOfflineQueue() async {
    final queue = await getOfflineQueue();
    if (queue.isEmpty) return 0;

    dev.log(
      '🔄 Syncing ${queue.length} offline transactions in a batch...',
      name: 'SalesService',
    );
    final prefs = await SharedPreferences.getInstance();

    final token = await _getToken();
    final headers = _getHeaders(token);
    final url = Uri.parse('${AppUrl.baseUrl}${AppUrl.syncSales}');

    // Map each queued item to the backend batch format, normalising both
    // old legacy shape (invoiceNumber/saleAmount) and new DTO shape.
    final transactionsList = queue.map((item) {
      final endpoint = item['endpoint'] as String? ?? '';
      final payload = item['payload'] as Map<String, dynamic>? ?? {};
      final isNewDto = (item['dtoVersion'] as int? ?? 1) >= 2;

      Map<String, dynamic> normPayload;
      if (isNewDto) {
        // New DTO shape — already has correct field names; pass through.
        normPayload = payload;
      } else {
        // Legacy shape — map old fields to what the backend batch sync expects.
        normPayload = _mapLegacyPayload(endpoint, payload);
      }

      return {
        'endpoint': endpoint,
        'payload': normPayload,
      };
    }).toList();

    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode({'transactions': transactionsList}),
          )
          .timeout(_timeout);

      dev.log(
        'Batch Sync Response: ${response.statusCode} - ${response.body}',
        name: 'SalesService',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final resBody = _safeDecode(response.body);
        final results = resBody['results'] as List?;
        final syncedCount = results?.length ?? queue.length;

        // Clear queue on success.
        await prefs.setStringList(_queueKey, []);
        dev.log(
          '✅ Batch sync completed. Synced $syncedCount items.',
          name: 'SalesService',
        );
        return syncedCount;
      } else {
        dev.log(
          'Batch sync failed: ${response.statusCode}: ${response.body}',
          name: 'SalesService',
        );
        return 0;
      }
    } catch (e) {
      dev.log('Batch sync exception: $e', name: 'SalesService');
      return 0;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  Internal helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Maps an old legacy payload (from queued entries before the DTO rebuild)
  /// to the shape expected by our backend batch sync.
  ///
  /// Old fields: invoiceNumber, saleAmount, billId, returnAmount, creditAmount, etc.
  /// New fields the backend uses: passed through to commission calculation.
  static Map<String, dynamic> _mapLegacyPayload(
    String endpoint,
    Map<String, dynamic> payload,
  ) {
    final norm = endpoint.toLowerCase();

    if (norm.contains('addsales')) {
      // For legacy AddSales: keep existing keys; backend reads saleAmount.
      return {
        'invoiceNumber': payload['invoiceNumber'] ?? payload['InvoiceNo'],
        'saleAmount': payload['saleAmount'] ?? payload['NetAmount'] ?? payload['FinalAmount'] ?? 0,
        'billId': payload['billId'],
        'notes': payload['notes'],
        // Include new-DTO amounts if present, so backend can extract them.
        'NetAmount': payload['NetAmount'] ?? payload['saleAmount'] ?? 0,
        'FinalAmount': payload['FinalAmount'] ?? payload['saleAmount'] ?? 0,
        // Pass through product and payment lists if they exist in the payload.
        if (payload.containsKey('SalesProductList'))
          'SalesProductList': payload['SalesProductList'],
        if (payload.containsKey('SalesPaymentList'))
          'SalesPaymentList': payload['SalesPaymentList'],
      };
    } else if (norm.contains('addcreditnote')) {
      return {
        'invoiceNumber': payload['invoiceNumber'] ?? payload['CNNo'],
        'creditAmount': payload['creditAmount'] ?? payload['CNAmount'] ?? 0,
        'billId': payload['billId'],
        'notes': payload['notes'],
        if (payload.containsKey('CNAmount')) 'CNAmount': payload['CNAmount'],
        if (payload.containsKey('SalesID')) 'SalesID': payload['SalesID'],
        if (payload.containsKey('CreditNoteProducts'))
          'CreditNoteProducts': payload['CreditNoteProducts'],
      };
    } else if (norm.contains('addsalesexchange')) {
      return {
        'invoiceNumber': payload['invoiceNumber'] ?? payload['ExchangeInvoiceNo'],
        'returnAmount': payload['returnAmount'] ?? 0,
        'newSaleAmount': payload['newSaleAmount'] ?? 0,
        'billId': payload['billId'],
        'notes': payload['notes'],
        if (payload.containsKey('SalesID')) 'SalesID': payload['SalesID'],
        if (payload.containsKey('SalesExchangeProductList'))
          'SalesExchangeProductList': payload['SalesExchangeProductList'],
      };
    }

    // Fallback: pass through as-is.
    return payload;
  }

  static Map<String, dynamic> _safeDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
