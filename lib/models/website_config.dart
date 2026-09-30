class WebsiteConfig {
  final String siteName;
  final String domain;
  final String apiEndpoint;
  final bool isConnected;
  final DateTime? connectedAt;
  final List<String> supportedProviders;

  WebsiteConfig({
    required this.siteName,
    required this.domain,
    required this.apiEndpoint,
    this.isConnected = false,
    this.connectedAt,
    this.supportedProviders = const ['bkash', 'nagad', 'rocket', 'upay'],
  });

  factory WebsiteConfig.fromJson(Map<String, dynamic> json) {
    List<String> providers = ['bkash', 'nagad', 'rocket', 'upay'];
    if (json['supported_providers'] is List) {
      providers = (json['supported_providers'] as List).map((e) => e.toString()).toList();
    }
    return WebsiteConfig(
      siteName: json['site_name']?.toString() ?? json['domain']?.toString() ?? 'Connected Site',
      domain: json['domain']?.toString() ?? '',
      apiEndpoint: json['api_endpoint']?.toString() ?? json['apiEndpoint']?.toString() ?? '',
      isConnected: json['is_connected'] == true || json['status'] == 'online',
      connectedAt: json['connected_at'] != null
          ? DateTime.tryParse(json['connected_at'].toString())
          : null,
      supportedProviders: providers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'site_name': siteName,
      'domain': domain,
      'api_endpoint': apiEndpoint,
      'is_connected': isConnected,
      'connected_at': connectedAt?.toIso8601String(),
      'supported_providers': supportedProviders,
    };
  }
}
