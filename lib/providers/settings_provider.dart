import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/storage_service.dart';
import '../services/sms_listener_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final SmsListenerService _smsListenerService = SmsListenerService();

  bool _notificationsEnabled = true;
  bool _smsPermissionGranted = false;
  bool _notificationPermissionGranted = false;
  bool _isIgnoringBatteryOpt = false;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get smsPermissionGranted => _smsPermissionGranted;
  bool get notificationPermissionGranted => _notificationPermissionGranted;
  bool get isIgnoringBatteryOpt => _isIgnoringBatteryOpt;

  Future<void> initSettings() async {
    _notificationsEnabled = await _storageService.isNotificationsEnabled();
    await checkPermissions();
  }

  Future<void> checkPermissions() async {
    _smsPermissionGranted = await Permission.sms.isGranted;
    _notificationPermissionGranted = await Permission.notification.isGranted;
    _isIgnoringBatteryOpt = await _smsListenerService.isIgnoringBatteryOptimizations();
    notifyListeners();
  }

  Future<void> requestSmsPermission() async {
    final status = await Permission.sms.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    _smsPermissionGranted = await Permission.sms.isGranted;
    notifyListeners();
  }

  Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    _notificationPermissionGranted = await Permission.notification.isGranted;
    notifyListeners();
  }

  Future<void> requestBatteryOptimization() async {
    await _smsListenerService.requestIgnoreBatteryOptimizations();
    _isIgnoringBatteryOpt = await _smsListenerService.isIgnoringBatteryOptimizations();
    notifyListeners();
  }

  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    await _storageService.setNotificationsEnabled(enabled);
    if (enabled && !_notificationPermissionGranted) {
      await requestNotificationPermission();
    }
    notifyListeners();
  }
}
