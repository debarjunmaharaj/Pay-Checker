import 'package:flutter/foundation.dart';
import '../models/payment_transaction.dart';
import '../services/offline_queue_service.dart';
import '../services/api_service.dart';

class PaymentsProvider extends ChangeNotifier {
  final OfflineQueueService _queueService = OfflineQueueService();
  final ApiService _apiService = ApiService();

  List<PaymentTransaction> _payments = [];
  bool _isLoading = false;
  String _activeFilter = 'All'; // All, Verified, Pending, Unmatched

  List<PaymentTransaction> get payments {
    if (_activeFilter == 'Verified') {
      return _payments.where((p) => p.status == PaymentStatus.verified || p.status == PaymentStatus.completed).toList();
    } else if (_activeFilter == 'Pending') {
      return _payments.where((p) => p.status == PaymentStatus.waiting || p.status == PaymentStatus.matching || p.status == PaymentStatus.received).toList();
    } else if (_activeFilter == 'Unmatched') {
      return _payments.where((p) => p.status == PaymentStatus.unmatched || p.status == PaymentStatus.rejected || p.status == PaymentStatus.failed).toList();
    }
    return _payments;
  }

  List<PaymentTransaction> get allPayments => _payments;
  bool get isLoading => _isLoading;
  String get activeFilter => _activeFilter;

  int get totalCount => _payments.length;
  int get verifiedCount => _payments.where((p) => p.status == PaymentStatus.verified || p.status == PaymentStatus.completed).length;
  int get pendingCount => _payments.where((p) => p.status == PaymentStatus.waiting || p.status == PaymentStatus.matching || p.status == PaymentStatus.received).length;
  int get unmatchedCount => _payments.where((p) => p.status == PaymentStatus.unmatched || p.status == PaymentStatus.rejected || p.status == PaymentStatus.failed).length;

  Future<void> loadLocalPayments() async {
    _isLoading = true;
    notifyListeners();

    _payments = await _queueService.getAllTransactions();

    _isLoading = false;
    notifyListeners();
  }

  void addOrUpdateTransaction(PaymentTransaction txn) {
    final index = _payments.indexWhere((p) => p.trxId == txn.trxId || p.id == txn.id);
    if (index >= 0) {
      _payments[index] = txn;
    } else {
      _payments.insert(0, txn);
    }
    notifyListeners();
  }

  void setFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  Future<void> syncWithServer({required String apiEndpoint, required String deviceId, required String deviceToken}) async {
    _isLoading = true;
    notifyListeners();

    final res = await _apiService.fetchPayments(
      apiEndpoint: apiEndpoint,
      deviceId: deviceId,
      deviceToken: deviceToken,
    );

    if (res.success && res.data != null) {
      for (final p in res.data!) {
        addOrUpdateTransaction(p);
        await _queueService.saveTransaction(p);
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}
