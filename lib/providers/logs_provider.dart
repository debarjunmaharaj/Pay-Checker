import 'package:flutter/foundation.dart';
import '../models/app_log.dart';
import '../services/offline_queue_service.dart';

class LogsProvider extends ChangeNotifier {
  final OfflineQueueService _queueService = OfflineQueueService();

  List<AppLog> _logs = [];
  bool _isLoading = false;

  List<AppLog> get logs => _logs;
  bool get isLoading => _isLoading;

  Future<void> loadLogs() async {
    _isLoading = true;
    notifyListeners();

    _logs = await _queueService.getLogs();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLog(AppLog log) async {
    _logs.insert(0, log);
    await _queueService.saveLog(log);
    notifyListeners();
  }

  Future<void> clearLogs() async {
    _logs.clear();
    await _queueService.clearLogs();
    notifyListeners();
  }
}
