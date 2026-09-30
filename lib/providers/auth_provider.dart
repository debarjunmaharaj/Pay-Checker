import 'package:flutter/foundation.dart';
import '../models/website_config.dart';
import '../models/device_details.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/domain_normalizer.dart';

class AuthProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();

  WebsiteConfig? _websiteConfig;
  DeviceDetails? _deviceDetails;

  bool _isLoading = false;
  bool _isConnected = false;
  String? _errorMessage;

  WebsiteConfig? get websiteConfig => _websiteConfig;
  DeviceDetails? get deviceDetails => _deviceDetails;
  bool get isLoading => _isLoading;
  bool get isConnected => _isConnected;
  String? get errorMessage => _errorMessage;

  Future<void> loadSavedState() async {
    _isLoading = true;
    notifyListeners();

    _websiteConfig = await _storageService.getWebsiteConfig();
    _deviceDetails = await _storageService.getDeviceDetails();

    _isConnected = _websiteConfig != null &&
        _websiteConfig!.isConnected &&
        _deviceDetails != null &&
        _deviceDetails!.token.isNotEmpty;

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> connectAndRegister({
    required String rawDomain,
    required String deviceName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final String apiEndpoint = DomainNormalizer.normalizeUrl(rawDomain);

    // Step 1: Connect & Verify Website API Endpoint
    final connectRes = await _apiService.connectWebsite(apiEndpoint);
    if (!connectRes.success || connectRes.data == null) {
      _errorMessage = connectRes.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _websiteConfig = connectRes.data;

    // Step 2: Register Device
    final String deviceId = 'NF-ANDROID-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final registerRes = await _apiService.registerDevice(
      apiEndpoint: apiEndpoint,
      deviceId: deviceId,
      deviceName: deviceName.isEmpty ? 'Android-Device' : deviceName,
      deviceModel: 'Android Phone',
      osVersion: 'Android 14',
    );

    if (!registerRes.success || registerRes.data == null) {
      _errorMessage = registerRes.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _deviceDetails = registerRes.data;

    await _storageService.saveWebsiteConfig(_websiteConfig!);
    await _storageService.saveDeviceDetails(_deviceDetails!);
    await _storageService.setOnboardingComplete(true);

    _isConnected = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> testConnection() async {
    if (_websiteConfig == null || _deviceDetails == null) return false;

    _isLoading = true;
    notifyListeners();

    final res = await _apiService.sendHeartbeat(
      apiEndpoint: _websiteConfig!.apiEndpoint,
      deviceId: _deviceDetails!.deviceId,
      deviceToken: _deviceDetails!.token,
    );

    _isLoading = false;
    _isConnected = res.success;
    notifyListeners();
    return res.success;
  }

  Future<void> disconnect() async {
    _isLoading = true;
    notifyListeners();

    if (_websiteConfig != null && _deviceDetails != null) {
      await _apiService.disconnectDevice(
        apiEndpoint: _websiteConfig!.apiEndpoint,
        deviceId: _deviceDetails!.deviceId,
        deviceToken: _deviceDetails!.token,
      );
    }

    await _storageService.clearAll();
    _websiteConfig = null;
    _deviceDetails = null;
    _isConnected = false;
    _isLoading = false;
    notifyListeners();
  }
}
