class DomainNormalizer {
  static const String defaultApiPath = '/netfie-pay/json/api';

  static String normalizeUrl(String input) {
    if (input.trim().isEmpty) return '';

    String cleaned = input.trim();

    // Ensure scheme
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'https://$cleaned';
    }

    Uri? uri = Uri.tryParse(cleaned);
    if (uri == null || uri.host.isEmpty) {
      return input.trim();
    }

    String scheme = uri.scheme;
    String host = uri.host;
    int port = uri.port;
    String portStr = (port != 80 && port != 443 && port > 0) ? ':$port' : '';

    String baseUrl = '$scheme://$host$portStr';

    String path = uri.path.replaceAll(RegExp(r'/+$'), '');

    if (path.isEmpty || path == '/') {
      return '$baseUrl$defaultApiPath';
    }

    if (path.contains('/netfie-pay/json/api')) {
      return '$baseUrl$defaultApiPath';
    }

    return '$baseUrl$path$defaultApiPath';
  }

  static String extractDomainOnly(String input) {
    String normalized = normalizeUrl(input);
    Uri? uri = Uri.tryParse(normalized);
    if (uri != null && uri.host.isNotEmpty) {
      return uri.host;
    }
    return input;
  }
}
