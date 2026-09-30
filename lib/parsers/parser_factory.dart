import 'sms_parser_interface.dart';
import 'bkash_parser.dart';
import 'nagad_parser.dart';
import 'rocket_parser.dart';
import 'upay_parser.dart';
import 'generic_parser.dart';
import '../models/sms_message_data.dart';

class ParserFactory {
  static final List<SmsParserInterface> _parsers = [
    BkashParser(),
    NagadParser(),
    RocketParser(),
    UpayParser(),
  ];

  static final GenericParser _fallbackParser = GenericParser();

  static ParsedPaymentSms parseSms(String sender, String body) {
    for (final parser in _parsers) {
      if (parser.canParse(sender, body)) {
        return parser.parse(sender, body);
      }
    }
    return _fallbackParser.parse(sender, body);
  }
}
