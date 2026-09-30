import 'sms_parser_interface.dart';
import '../models/sms_message_data.dart';

class UpayParser implements SmsParserInterface {
  @override
  String get providerName => 'upay';

  @override
  bool canParse(String sender, String body) {
    final senderUpper = sender.toUpperCase();
    final bodyUpper = body.toUpperCase();
    return senderUpper.contains('UPAY') ||
        (bodyUpper.contains('UPAY') && (bodyUpper.contains('TXNID') || bodyUpper.contains('TRXID')));
  }

  @override
  ParsedPaymentSms parse(String sender, String body) {
    try {
      final amountRegex = RegExp(r'(?:Tk|BDT)\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
      final amountMatch = amountRegex.firstMatch(body);
      double amount = 0.0;
      if (amountMatch != null) {
        final amountStr = amountMatch.group(1)!.replaceAll(',', '');
        amount = double.tryParse(amountStr) ?? 0.0;
      }

      final trxRegex = RegExp(r'(?:TxnID|TrxID|TxnId)[:\s]+([A-Z0-9]+)', caseSensitive: false);
      final trxMatch = trxRegex.firstMatch(body);
      String trxId = '';
      if (trxMatch != null) {
        trxId = trxMatch.group(1)!.trim();
      }

      final senderRegex = RegExp(r'(?:from|by)\s+(\+?880[0-9]{8,10}|01[3-9][0-9]{8})', caseSensitive: false);
      final senderMatch = senderRegex.firstMatch(body);
      String senderNum = '';
      if (senderMatch != null) {
        senderNum = senderMatch.group(1)!.trim();
      }

      bool isValid = trxId.isNotEmpty && amount > 0;

      return ParsedPaymentSms(
        provider: providerName,
        trxId: trxId,
        amount: amount,
        senderNumber: senderNum,
        rawBody: body,
        isValid: isValid,
        parseError: isValid ? null : 'Could not extract valid Upay TxnID or Amount',
      );
    } catch (e) {
      return ParsedPaymentSms(
        provider: providerName,
        trxId: '',
        amount: 0.0,
        senderNumber: '',
        rawBody: body,
        isValid: false,
        parseError: 'Exception during Upay parsing: $e',
      );
    }
  }
}
