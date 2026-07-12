import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickboom_hrm/core/constants/app_url.dart';
import 'package:quickboom_hrm/core/services/storage_service.dart';

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

  /// Sends a sales request. If it fails due to network, it queues the transaction offline.
  static Future<Map<String, dynamic>> submitTransaction({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    final token = await _getToken();
    final url = Uri.parse('${AppUrl.baseUrl}$endpoint');
    final headers = _getHeaders(token);

    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      dev.log('Sales Response ($endpoint): ${response.statusCode} - ${response.body}', name: 'SalesService');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final resBody = jsonDecode(response.body);
        return {
          'success': true,
          'message': resBody['message'] ?? 'Transaction submitted successfully',
          'offline': false,
        };
      } else if (response.statusCode >= 500) {
        // Server error, queue offline for retry
        await queueOffline(endpoint, payload);
        return {
          'success': true,
          'message': 'Transaction queued offline due to server error',
          'offline': true,
        };
      } else {
        final resBody = jsonDecode(response.body);
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

  /// Save transaction to the offline queue
  static Future<void> queueOffline(String endpoint, Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> queue = prefs.getStringList(_queueKey) ?? [];
      
      final newItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'endpoint': endpoint,
        'payload': payload,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      queue.add(jsonEncode(newItem));
      await prefs.setStringList(_queueKey, queue);
      dev.log('Transaction queued offline: $endpoint', name: 'SalesService');
    } catch (e) {
      dev.log('Failed to queue transaction offline: $e', name: 'SalesService');
    }
  }

  /// Fetch the list of pending offline transactions
  static Future<List<Map<String, dynamic>>> getOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> queue = prefs.getStringList(_queueKey) ?? [];
      return queue.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
    } catch (e) {
      dev.log('Failed to read offline queue: $e', name: 'SalesService');
      return [];
    }
  }

  /// Sync all pending offline transactions
  static Future<int> syncOfflineQueue() async {
    final queue = await getOfflineQueue();
    if (queue.isEmpty) return 0;

    dev.log('Syncing ${queue.length} offline transactions...', name: 'SalesService');
    final prefs = await SharedPreferences.getInstance();
    
    int syncedCount = 0;
    final List<String> remainingQueue = [];

    final token = await _getToken();
    final headers = _getHeaders(token);

    for (final item in queue) {
      final endpoint = item['endpoint'] as String;
      final payload = item['payload'] as Map<String, dynamic>;
      final url = Uri.parse('${AppUrl.baseUrl}$endpoint');

      try {
        final response = await http
            .post(
              url,
              headers: headers,
              body: jsonEncode(payload),
            )
            .timeout(_timeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          syncedCount++;
          dev.log('Synced successfully: $endpoint', name: 'SalesService');
        } else if (response.statusCode >= 400 && response.statusCode < 500) {
          // Client error - discard from queue since retrying won't help
          dev.log('Discarding invalid transaction ($endpoint) - Status ${response.statusCode}: ${response.body}', name: 'SalesService');
        } else {
          // Server error - keep in queue for next sync
          remainingQueue.add(jsonEncode(item));
        }
      } catch (e) {
        dev.log('Sync error for $endpoint: $e', name: 'SalesService');
        remainingQueue.add(jsonEncode(item));
      }
    }

    await prefs.setStringList(_queueKey, remainingQueue);
    return syncedCount;
  }
}
