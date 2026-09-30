enum PaymentStatus {
  waiting,
  received,
  matching,
  verified,
  completed,
  unmatched,
  rejected,
  expired,
  duplicate,
  failed,
}

enum PaymentProvider {
  bkash,
  nagad,
  rocket,
  upay,
  generic,
}

class PaymentTransaction {
  final String id;
  final String trxId;
  final String provider;
  final double amount;
  final String sender;
  final String rawSms;
  final PaymentStatus status;
  final String? orderId;
  final String? customerName;
  final DateTime receivedAt;
  final DateTime? processedAt;
  final String? failureReason;
  final bool isSynced;

  PaymentTransaction({
    required this.id,
    required this.trxId,
    required this.provider,
    required this.amount,
    required this.sender,
    required this.rawSms,
    required this.status,
    this.orderId,
    this.customerName,
    required this.receivedAt,
    this.processedAt,
    this.failureReason,
    this.isSynced = false,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id']?.toString() ?? '',
      trxId: json['trx_id']?.toString() ?? json['trxId']?.toString() ?? '',
      provider: json['provider']?.toString() ?? 'generic',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      sender: json['sender']?.toString() ?? '',
      rawSms: json['raw_sms']?.toString() ?? json['rawSms']?.toString() ?? '',
      status: _parseStatus(json['status']?.toString()),
      orderId: json['order_id']?.toString() ?? json['orderId']?.toString(),
      customerName: json['customer_name']?.toString() ?? json['customerName']?.toString(),
      receivedAt: json['received_at'] != null
          ? DateTime.tryParse(json['received_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      processedAt: json['processed_at'] != null
          ? DateTime.tryParse(json['processed_at'].toString())
          : null,
      failureReason: json['failure_reason']?.toString(),
      isSynced: json['is_synced'] == 1 || json['is_synced'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trx_id': trxId,
      'provider': provider,
      'amount': amount,
      'sender': sender,
      'raw_sms': rawSms,
      'status': status.name,
      'order_id': orderId,
      'customer_name': customerName,
      'received_at': receivedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'failure_reason': failureReason,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  PaymentTransaction copyWith({
    String? id,
    String? trxId,
    String? provider,
    double? amount,
    String? sender,
    String? rawSms,
    PaymentStatus? status,
    String? orderId,
    String? customerName,
    DateTime? receivedAt,
    DateTime? processedAt,
    String? failureReason,
    bool? isSynced,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      trxId: trxId ?? this.trxId,
      provider: provider ?? this.provider,
      amount: amount ?? this.amount,
      sender: sender ?? this.sender,
      rawSms: rawSms ?? this.rawSms,
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      receivedAt: receivedAt ?? this.receivedAt,
      processedAt: processedAt ?? this.processedAt,
      failureReason: failureReason ?? this.failureReason,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  static PaymentStatus _parseStatus(String? statusStr) {
    if (statusStr == null) return PaymentStatus.received;
    switch (statusStr.toLowerCase()) {
      case 'waiting':
        return PaymentStatus.waiting;
      case 'received':
        return PaymentStatus.received;
      case 'matching':
        return PaymentStatus.matching;
      case 'verified':
        return PaymentStatus.verified;
      case 'completed':
      case 'processing':
        return PaymentStatus.completed;
      case 'unmatched':
        return PaymentStatus.unmatched;
      case 'rejected':
        return PaymentStatus.rejected;
      case 'expired':
        return PaymentStatus.expired;
      case 'duplicate':
        return PaymentStatus.duplicate;
      case 'failed':
      default:
        return PaymentStatus.failed;
    }
  }
}
