class SmsMessageData {
  final String sender;
  final String body;
  final DateTime timestamp;

  SmsMessageData({
    required this.sender,
    required this.body,
    required this.timestamp,
  });

  factory SmsMessageData.fromMap(Map<dynamic, dynamic> map) {
    int timeMs = map['timestamp'] is int
        ? map['timestamp']
        : int.tryParse(map['timestamp']?.toString() ?? '0') ?? DateTime.now().millisecondsSinceEpoch;
    return SmsMessageData(
      sender: map['sender']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(timeMs),
    );
  }
}

class ParsedPaymentSms {
  final String provider;
  final String trxId;
  final double amount;
  final String senderNumber;
  final String rawBody;
  final bool isValid;
  final String? parseError;

  ParsedPaymentSms({
    required this.provider,
    required this.trxId,
    required this.amount,
    required this.senderNumber,
    required this.rawBody,
    this.isValid = true,
    this.parseError,
  });
}
