import '../models/sms_message_data.dart';

abstract class SmsParserInterface {
  String get providerName;
  bool canParse(String sender, String body);
  ParsedPaymentSms parse(String sender, String body);
}
