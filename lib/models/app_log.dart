enum LogType {
  info,
  sms,
  api,
  verification,
  error,
  warning,
}

class AppLog {
  final String id;
  final LogType type;
  final String title;
  final String message;
  final String? details;
  final DateTime timestamp;

  AppLog({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.details,
    required this.timestamp,
  });

  factory AppLog.fromJson(Map<String, dynamic> json) {
    return AppLog(
      id: json['id']?.toString() ?? '',
      type: _parseType(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      details: json['details']?.toString(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static LogType _parseType(String? typeStr) {
    if (typeStr == null) return LogType.info;
    switch (typeStr.toLowerCase()) {
      case 'sms':
        return LogType.sms;
      case 'api':
        return LogType.api;
      case 'verification':
        return LogType.verification;
      case 'error':
        return LogType.error;
      case 'warning':
        return LogType.warning;
      case 'info':
      default:
        return LogType.info;
    }
  }
}
