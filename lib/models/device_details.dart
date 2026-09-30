class DeviceDetails {
  final String deviceId;
  final String deviceName;
  final String deviceModel;
  final String osVersion;
  final String token;
  final String status;
  final DateTime? lastSync;

  DeviceDetails({
    required this.deviceId,
    required this.deviceName,
    required this.deviceModel,
    required this.osVersion,
    required this.token,
    this.status = 'active',
    this.lastSync,
  });

  factory DeviceDetails.fromJson(Map<String, dynamic> json) {
    return DeviceDetails(
      deviceId: json['device_id']?.toString() ?? json['deviceId']?.toString() ?? '',
      deviceName: json['device_name']?.toString() ?? json['deviceName']?.toString() ?? 'Android Device',
      deviceModel: json['device_model']?.toString() ?? json['deviceModel']?.toString() ?? 'Android',
      osVersion: json['os_version']?.toString() ?? json['osVersion']?.toString() ?? 'Android',
      token: json['device_token']?.toString() ?? json['token']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      lastSync: json['last_sync'] != null
          ? DateTime.tryParse(json['last_sync'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'device_model': deviceModel,
      'os_version': osVersion,
      'device_token': token,
      'status': status,
      'last_sync': lastSync?.toIso8601String(),
    };
  }
}
