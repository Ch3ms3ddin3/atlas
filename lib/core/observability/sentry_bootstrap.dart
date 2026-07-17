import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/atlas_env.dart';

/// Bootstrap Sentry (DSN optionnel via `--dart-define=SENTRY_DSN=…`).
///
/// Sans DSN, les handlers d'erreur Flutter restent actifs en local (debugPrint).
abstract final class SentryBootstrap {
  static const _dsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  static bool get isConfigured => _dsn.trim().isNotEmpty;

  /// Initialise Sentry si configuré, puis exécute [appRunner].
  static Future<void> run(FutureOr<void> Function() appRunner) async {
    if (!isConfigured) {
      _installLocalHandlers();
      await appRunner();
      return;
    }

    final env = AtlasEnv.fromCompileTime().environment.label;
    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;
        options.environment = env;
        options.tracesSampleRate = 0.0;
        options.sendDefaultPii = false;
        options.debug = kDebugMode;
      },
      appRunner: appRunner,
    );
  }

  static void _installLocalHandlers() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint('[Atlas] FlutterError: ${details.exceptionAsString()}');
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        debugPrint('[Atlas] PlatformError: $error');
      }
      return true;
    };
  }
}
