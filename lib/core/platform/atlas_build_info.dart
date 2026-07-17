import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Métadonnées de build / appareil pour bannière beta et diagnostics.
class AtlasBuildInfo {
  const AtlasBuildInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.platformLabel,
    required this.deviceLabel,
  });

  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  final String platformLabel;
  final String deviceLabel;

  String get versionLabel => 'v$version ($buildNumber)';

  static AtlasBuildInfo? _cached;

  /// Charge une fois (cache process).
  static Future<AtlasBuildInfo> load({bool forceReload = false}) async {
    if (!forceReload && _cached != null) return _cached!;

    try {
      final package = await PackageInfo.fromPlatform();
      final platformLabel = _resolvePlatform();
      final deviceLabel = await _resolveDevice(platformLabel);

      _cached = AtlasBuildInfo(
        appName: package.appName.isEmpty ? 'Atlas' : package.appName,
        packageName:
            package.packageName.isEmpty ? 'app.atlas.maroc' : package.packageName,
        version: package.version.isEmpty ? '1.0.0' : package.version,
        buildNumber: package.buildNumber.isEmpty ? '0' : package.buildNumber,
        platformLabel: platformLabel,
        deviceLabel: deviceLabel,
      );
    } catch (_) {
      _cached = AtlasBuildInfo(
        appName: 'Atlas',
        packageName: 'app.atlas.maroc',
        version: '1.0.0',
        buildNumber: '0',
        platformLabel: _resolvePlatform(),
        deviceLabel: _resolvePlatform(),
      );
    }
    return _cached!;
  }

  /// Pour les tests — injecte une valeur fixe.
  @visibleForTesting
  static void debugOverride(AtlasBuildInfo? info) {
    _cached = info;
  }

  static String _resolvePlatform() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  static Future<String> _resolveDevice(String platformLabel) async {
    try {
      final plugin = DeviceInfoPlugin();
      if (kIsWeb) {
        final web = await plugin.webBrowserInfo;
        return '${web.browserName.name} / ${web.platform ?? 'web'}';
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final android = await plugin.androidInfo;
          return '${android.manufacturer} ${android.model} '
              '(SDK ${android.version.sdkInt})';
        case TargetPlatform.iOS:
          final ios = await plugin.iosInfo;
          return '${ios.name} ${ios.systemVersion} (${ios.utsname.machine})';
        case TargetPlatform.macOS:
          final mac = await plugin.macOsInfo;
          return '${mac.model} ${mac.osRelease}';
        case TargetPlatform.windows:
          final windows = await plugin.windowsInfo;
          return windows.productName;
        case TargetPlatform.linux:
          final linux = await plugin.linuxInfo;
          return linux.prettyName;
        case TargetPlatform.fuchsia:
          return platformLabel;
      }
    } catch (_) {
      // ignore — diagnostics restent utilisables
    }
    return platformLabel;
  }
}
