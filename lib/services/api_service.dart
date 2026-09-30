import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/website_config.dart';
import '../models/device_details.dart';
import '../models/payment_transaction.dart';
import '../models/sms_message_data.dart';
import 'domain_normalizer.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({required this.success, required this.message, this.data});
}

class ApiService {
  final http.Client _client = http.Client();

  Map<String, String> _buildHeaders({String? deviceId, String? deviceToken}) {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (deviceId != null && deviceId.isNotEmpty) {
      headers['X-Device-ID'] = deviceId;
    }
    if (deviceToken != null && deviceToken.isNotEmpty) {
      headers['X-Device-Token'] = deviceToken;
    }
    return headers;
  }

  /// Test Connection & Verify Website Plugin Presence
  Future<ApiResponse<WebsiteConfig>> connectWebsite(String rawDomain) async {
    final String apiEndpoint = DomainNormalizer.normalizeUrl(rawDomain);
    final String domainOnly = DomainNormalizer.extractDomainOnly(rawDomain);

    try {
      final response = await _client.post(
        Uri.parse(apiEndpoint),
        headers: _buildHeaders(),
        body: jsonEncode({
          'action': 'connect',
          'app_version': '1.0.0',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' || body['success'] == true) {
          final data = body['data'] ?? {};
          final config = WebsiteConfig(
            siteName: data['site_name'] ?? domainOnly,
            domain: domainOnly,
            apiEndpoint: apiEndpoint,
            isConnected: true,
            connectedAt: DateTime.now(),
            supportedProviders: List<String>.from(data['supported_providers'] ?? ['bkash', 'nagad', 'rocket', 'upay']),
          );
          return ApiResponse(success: true, message: 'Successfully connected to $domainOnly', data: config);
        } else {
          return ApiResponse(success: false, message: body['message'] ?? 'Plugin API returned an error.');
        }
      } else {
        return ApiResponse(success: false, message: 'Server responded with status code ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Could not connect to website: $e');
    }
  }

  /// Register Device with Website
  Future<ApiResponse<DeviceDetails>> registerDevice({
    required String apiEndpoint,
    required String deviceId,
    required String deviceName,
    required String deviceModel,
    required String osVersion,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(apiEndpoint),
        headers: _buildHeaders(deviceId: deviceId),
        body: jsonEncode({
          'action': 'register_device',
          'device_id': deviceId,
          'device_name': deviceName,
          'device_model': deviceModel,
          'os_version': osVersion,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' || body['success'] == true) {
          final data = body['data'] ?? {};
          final device = DeviceDetails(
            deviceId: deviceId,
            deviceName: deviceName,
            deviceModel: deviceModel,
            osVersion: osVersion,
            token: data['device_token'] ?? data['token'] ?? '',
            status: 'active',
            lastSync: DateTime.now(),
          );
          return ApiResponse(success: true, message: 'Device registered successfully', data: device);
        } else {
          return ApiResponse(success: false, message: body['message'] ?? 'Device registration failed.');
        }
      } else {
        return ApiResponse(success: false, message: 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Device registration request failed: $e');
    }
  }

  /// Send Parsed SMS Transaction to Server
  Future<ApiResponse<PaymentTransaction>> sendSmsTransaction({
    required String apiEndpoint,
    required String deviceId,
    required String deviceToken,
    required ParsedPaymentSms parsedSms,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(apiEndpoint),
        headers: _buildHeaders(deviceId: deviceId, deviceToken: deviceToken),
        body: jsonEncode({
          'action': 'sms_transaction',
          'provider': parsedSms.provider,
          'trx_id': parsedSms.trxId,
          'amount': parsedSms.amount,
          'sender': parsedSms.senderNumber,
          'raw_sms': parsedSms.rawBody,
          'received_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' || body['success'] == true) {
          final data = body['data'] ?? {};
          final transaction = PaymentTransaction.fromJson(data);
          return ApiResponse(
            success: true,
            message: body['message'] ?? 'Transaction verified on server.',
            data: transaction,
          );
        } else {
          return ApiResponse(
            success: false,
            message: body['message'] ?? 'Transaction unmatched or invalid.',
            data: body['data'] != null ? PaymentTransaction.fromJson(body['data']) : null,
          );
        }
      } else {
        return ApiResponse(success: false, message: 'Server HTTP ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Network error posting transaction: $e');
    }
  }

  /// Device Heartbeat & Ping
  Future<ApiResponse<Map<String, dynamic>>> sendHeartbeat({
    required String apiEndpoint,
    required String deviceId,
    required String deviceToken,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(apiEndpoint),
        headers: _buildHeaders(deviceId: deviceId, deviceToken: deviceToken),
        body: jsonEncode({
          'action': 'heartbeat',
          'device_id': deviceId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return ApiResponse(
          success: body['status'] == 'success' || body['success'] == true,
          message: body['message'] ?? 'Heartbeat acknowledged',
          data: body['data'],
        );
      } else {
        return ApiResponse(success: false, message: 'Heartbeat HTTP ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(success: false, message: 'Heartbeat failed: $e');
    }
  }

  /// Fetch Transactions List from Server
  Future<ApiResponse<List<PaymentTransaction>>> fetchPayments({
    required String apiEndpoint,
    required String deviceId,
    required String deviceToken,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(apiEndpoint),
        headers: _buildHeaders(deviceId: deviceId, deviceToken: deviceToken),
        body: jsonEncode({
          'action': 'sync',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'success' || body['success'] == true) {
          final List list = body['data']?['payments'] ?? body['data'] ?? [];
          final payments = list.map((e) => PaymentTransaction.fromJson(e)).toList();
          return ApiResponse(success: true, message: 'Payments synced', data: payments);
        }
      }
      return ApiResponse(success: false, message: 'Failed to fetch payments');
    } catch (e) {
      return ApiResponse(success: false, message: 'Error fetching payments: $e');
    }
  }

  /// Disconnect Device
  Future<ApiResponse<bool>> disconnectDevice({
    required String apiEndpoint,
    required String deviceId,
    required String deviceToken,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(apiEndpoint),
        headers: _buildHeaders(deviceId: deviceId, deviceToken: deviceToken),
        body: jsonEncode({
          'action': 'disconnect',
        }),
      ).timeout(const Duration(seconds: 10));

      return ApiResponse(
        success: response.statusCode == 200,
        message: 'Disconnected successfully',
        data: true,
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Disconnect error: $e');
    }
  }
}
