import 'package:workmanager/workmanager.dart';
import 'storage_service.dart';
import 'offline_queue_service.dart';
import 'api_service.dart';
import '../parsers/parser_factory.dart';

const String syncTaskName = 'com.netfie.pay_checker.background_sync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final storageService = StorageService();
      final queueService = OfflineQueueService();
      final apiService = ApiService();

      final website = await storageService.getWebsiteConfig();
      final device = await storageService.getDeviceDetails();

      if (website != null && device != null) {
        // 1. Send Heartbeat
        await apiService.sendHeartbeat(
          apiEndpoint: website.apiEndpoint,
          deviceId: device.deviceId,
          deviceToken: device.token,
        );

        // 2. Process Unsynced Queue
        final unsynced = await queueService.getUnsyncedTransactions();
        for (final txn in unsynced) {
          final parsed = ParserFactory.parseSms(txn.sender, txn.rawSms);
          if (parsed.isValid) {
            final res = await apiService.sendSmsTransaction(
              apiEndpoint: website.apiEndpoint,
              deviceId: device.deviceId,
              deviceToken: device.token,
              parsedSms: parsed,
            );
            if (res.success && res.data != null) {
              await queueService.saveTransaction(res.data!.copyWith(isSynced: true));
              await queueService.markAsSynced(txn.trxId);
            }
          }
        }
      }
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      'pay_checker_periodic_sync',
      syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
  }
}
