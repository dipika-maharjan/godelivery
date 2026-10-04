enum DevicePlatform { ios, android, web }

String devicePlatformToJson(DevicePlatform platform) {
  switch (platform) {
    case DevicePlatform.ios:
      return 'IOS';
    case DevicePlatform.android:
      return 'ANDROID';
    case DevicePlatform.web:
      return 'WEB';
  }
}

class AppDevice {
  const AppDevice({
    required this.id,
    this.userId,
    required this.platform,
    required this.deviceIdentifier,
    this.pushToken,
  });

  factory AppDevice.fromJson(Map<String, dynamic> json) {
    return AppDevice(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      platform: json['platform'] as String,
      deviceIdentifier: json['deviceIdentifier'] as String,
      pushToken: json['pushToken'] as String?,
    );
  }

  final String id;
  final String? userId;
  final String platform;
  final String deviceIdentifier;
  final String? pushToken;
}
