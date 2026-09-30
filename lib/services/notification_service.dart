import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/payment_transaction.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click if needed
      },
    );

    _isInitialized = true;
  }

  Future<void> showPaymentVerifiedNotification(PaymentTransaction txn) async {
    await init();

    final androidDetails = AndroidNotificationDetails(
      'pay_checker_verified',
      'Verified Payments',
      channelDescription: 'Notifications for successfully verified payment SMS',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(android: androidDetails);

    final String title = 'Payment Verified! ৳${txn.amount.toStringAsFixed(0)} (${txn.provider.toUpperCase()})';
    final String body = 'TrxID: ${txn.trxId} matched with Order #${txn.orderId ?? 'Pending'}';

    await _notificationsPlugin.show(
      txn.trxId.hashCode,
      title,
      body,
      details,
    );
  }

  Future<void> showUnmatchedPaymentNotification(PaymentTransaction txn) async {
    await init();

    final androidDetails = AndroidNotificationDetails(
      'pay_checker_unmatched',
      'Unmatched Payments',
      channelDescription: 'Notifications for received SMS without matching pending order',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(android: androidDetails);

    final String title = 'Unmatched Payment Received ৳${txn.amount.toStringAsFixed(0)}';
    final String body = '${txn.provider.toUpperCase()} TrxID: ${txn.trxId}. No matching pending order found.';

    await _notificationsPlugin.show(
      txn.trxId.hashCode,
      title,
      body,
      details,
    );
  }

  Future<void> showConnectionErrorNotification(String errorMessage) async {
    await init();

    final androidDetails = AndroidNotificationDetails(
      'pay_checker_errors',
      'Connection & System Errors',
      channelDescription: 'Alerts for website connection or SMS syncing issues',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      1001,
      'Pay Checker Warning',
      errorMessage,
      details,
    );
  }
}
