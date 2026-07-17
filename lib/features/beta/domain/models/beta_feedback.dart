import '../../../../core/uuid/atlas_uuid.dart';

/// Signalement beta in-app.
class BetaFeedback {
  const BetaFeedback({
    required this.id,
    required this.screenName,
    required this.message,
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.includeScreenshot,
    this.screenshotBase64,
    this.createdAt,
  });

  final String id;
  final String screenName;
  final String message;
  final String appVersion;
  final String buildNumber;
  final String platform;
  final bool includeScreenshot;
  final String? screenshotBase64;
  final DateTime? createdAt;

  factory BetaFeedback.create({
    required String screenName,
    required String message,
    required String appVersion,
    required String buildNumber,
    required String platform,
    bool includeScreenshot = false,
    String? screenshotBase64,
  }) {
    return BetaFeedback(
      id: AtlasUuid.v4(),
      screenName: screenName,
      message: message.trim(),
      appVersion: appVersion,
      buildNumber: buildNumber,
      platform: platform,
      includeScreenshot: includeScreenshot,
      screenshotBase64: screenshotBase64,
      createdAt: DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'screen_name': screenName,
        'message': message,
        'app_version': appVersion,
        'build_number': buildNumber,
        'platform': platform,
        'include_screenshot': includeScreenshot,
        if (screenshotBase64 != null) 'screenshot_base64': screenshotBase64,
        if (createdAt != null)
          'created_at': createdAt!.toUtc().toIso8601String(),
      };

  factory BetaFeedback.fromJson(Map<String, dynamic> json) {
    return BetaFeedback(
      id: json['id'] as String? ?? AtlasUuid.v4(),
      screenName: json['screen_name'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      appVersion: json['app_version'] as String? ?? '',
      buildNumber: json['build_number'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      includeScreenshot: json['include_screenshot'] as bool? ?? false,
      screenshotBase64: json['screenshot_base64'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toUtc(),
    );
  }
}
