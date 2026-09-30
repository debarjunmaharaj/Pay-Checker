import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/website_config.dart';
import '../models/device_details.dart';

class StorageService {
  static const String _keyWebsiteConfig = 'website_config';
  static const String _keyDeviceDetails = 'device_details';
  static const String _keyDeviceToken = 'device_token';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keySmsListeningEnabled = 'sms_listening_enabled';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> saveWebsiteConfig(WebsiteConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWebsiteConfig, jsonEncode(config.toJson()));
  }

  Future<WebsiteConfig?> getWebsiteConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final String? str = prefs.getString(_keyWebsiteConfig);
    if (str != null && str.isNotEmpty) {
      try {
        return WebsiteConfig.fromJson(jsonDecode(str));
      } catch (_) {}
    }
    return null;
  }

  Future<void> saveDeviceDetails(DeviceDetails device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceDetails, jsonEncode(device.toJson()));
    await _secureStorage.write(key: _keyDeviceToken, value: device.token);
  }

  Future<DeviceDetails?> getDeviceDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final String? str = prefs.getString(_keyDeviceDetails);
    if (str != null && str.isNotEmpty) {
      try {
        final token = await _secureStorage.read(key: _keyDeviceToken) ?? '';
        final jsonMap = jsonDecode(str) as Map<String, dynamic>;
        jsonMap['device_token'] = token;
        return DeviceDetails.fromJson(jsonMap);
      } catch (_) {}
    }
    return null;
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<void> setOnboardingComplete(bool complete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, complete);
  }

  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  Future<bool> isSmsListeningEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySmsListeningEnabled) ?? true;
  }

  Future<void> setSmsListeningEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySmsListeningEnabled, enabled);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secureStorage.deleteAll();
  }
}
