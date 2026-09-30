import 'sms_parser_interface.dart';
import '../models/sms_message_data.dart';

class GenericParser implements SmsParserInterface {
  @override
  String get providerName => 'generic';

  @override
  bool canParse(String sender, String body) => true;

  @override
  ParsedPaymentSms parse(String sender, String body) {
    try {
      final amountRegex = RegExp(r'(?:Tk|BDT|Amount[:\s]*Tk\.?)\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
      final amountMatch = amountRegex.firstMatch(body);
      double amount = 0.0;
      if (amountMatch != null) {
        final amountStr = amountMatch.group(1)!.replaceAll(',', '');
        amount = double.tryParse(amountStr) ?? 0.0;
      }

      final trxRegex = RegExp(r'(?:TrxID|TxnID|TxnId|Ref|Transaction ID)[:\s]+([A-Z0-9]+)', caseSensitive: false);
      final trxMatch = trxRegex.firstMatch(body);
      String trxId = '';
      if (trxMatch != null) {
        trxId = trxMatch.group(1)!.trim();
      }

      final senderRegex = RegExp(r'(\+?880[0-9]{8,10}|01[3-9][0-9]{8})');
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
        parseError: isValid ? null : 'Generic parser could not detect valid TrxID or Amount',
      );
    } catch (e) {
      return ParsedPaymentSms(
        provider: providerName,
        trxId: '',
        amount: 0.0,
        senderNumber: '',
        rawBody: body,
        isValid: false,
        parseError: 'Exception during Generic parsing: $e',
      );
    }
  }
}
