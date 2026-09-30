import 'dart:async';
import 'package:flutter/services.dart';
import '../models/sms_message_data.dart';
import '../models/payment_transaction.dart';
import '../models/app_log.dart';
import '../parsers/parser_factory.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'offline_queue_service.dart';
import 'notification_service.dart';

class SmsListenerService {
  static const EventChannel _eventChannel = EventChannel('com.netfie.pay_checker/sms_events');
  static const MethodChannel _methodChannel = MethodChannel('com.netfie.pay_checker/native_methods');

  StreamSubscription? _subscription;
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final OfflineQueueService _queueService = OfflineQueueService();
  final NotificationService _notificationService = NotificationService();

  void startListening({
    required Function(PaymentTransaction) onTransactionProcessed,
    required Function(AppLog) onLogAdded,
  }) {
    _subscription?.cancel();
    _subscription = _eventChannel.receiveBroadcastStream().listen((dynamic event) async {
      if (event is Map) {
        final smsData = SmsMessageData.fromMap(event);
        await processIncomingSms(smsData, onTransactionProcessed, onLogAdded);
      }
    }, onError: (dynamic error) {
      onLogAdded(AppLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: LogType.error,
        title: 'SMS Listener Error',
        message: 'Stream error: $error',
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> processIncomingSms(
    SmsMessageData smsData,
    Function(PaymentTransaction) onTransactionProcessed,
    Function(AppLog) onLogAdded,
  ) async {
    // 1. Log incoming SMS
    onLogAdded(AppLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: LogType.sms,
      title: 'Incoming SMS Detected',
      message: 'Sender: ${smsData.sender}',
      details: smsData.body,
      timestamp: DateTime.now(),
    ));

    // 2. Parse SMS
    final parsed = ParserFactory.parseSms(smsData.sender, smsData.body);

    if (!parsed.isValid) {
      onLogAdded(AppLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: LogType.info,
        title: 'Ignored Non-Payment SMS',
        message: parsed.parseError ?? 'SMS does not match payment patterns',
        details: smsData.body,
        timestamp: DateTime.now(),
      ));
      return;
    }

    // 3. Prepare Transaction Model
    final localTxn = PaymentTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      trxId: parsed.trxId,
      provider: parsed.provider,
      amount: parsed.amount,
      sender: parsed.senderNumber,
      rawSms: parsed.rawBody,
      status: PaymentStatus.received,
      receivedAt: DateTime.now(),
      isSynced: false,
    );

    // Save locally
    await _queueService.saveTransaction(localTxn);

    // 4. Post to Server API if Connected
    final website = await _storageService.getWebsiteConfig();
    final device = await _storageService.getDeviceDetails();

    if (website != null && device != null) {
      final response = await _apiService.sendSmsTransaction(
        apiEndpoint: website.apiEndpoint,
        deviceId: device.deviceId,
        deviceToken: device.token,
        parsedSms: parsed,
      );

      if (response.success && response.data != null) {
        final updatedTxn = response.data!.copyWith(isSynced: true);
        await _queueService.saveTransaction(updatedTxn);
        await _queueService.markAsSynced(parsed.trxId);

        onTransactionProcessed(updatedTxn);

        onLogAdded(AppLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: LogType.verification,
          title: 'Payment Verified (${updatedTxn.provider.toUpperCase()})',
          message: 'TrxID: ${updatedTxn.trxId} - Amount: ৳${updatedTxn.amount}',
          details: 'Order ID: ${updatedTxn.orderId ?? 'N/A'}',
          timestamp: DateTime.now(),
        ));

        // Trigger Notification
        if (updatedTxn.status == PaymentStatus.verified || updatedTxn.status == PaymentStatus.completed) {
          await _notificationService.showPaymentVerifiedNotification(updatedTxn);
        } else {
          await _notificationService.showUnmatchedPaymentNotification(updatedTxn);
        }
      } else {
        // Queue for offline sync
        onLogAdded(AppLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: LogType.warning,
          title: 'Queued for Offline Sync',
          message: response.message,
          details: 'TrxID: ${parsed.trxId}',
          timestamp: DateTime.now(),
        ));

        onTransactionProcessed(localTxn);
        await _notificationService.showUnmatchedPaymentNotification(localTxn);
      }
    } else {
      onTransactionProcessed(localTxn);
    }
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final bool result = await _methodChannel.invokeMethod('isIgnoringBatteryOptimizations');
      return result;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _methodChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
