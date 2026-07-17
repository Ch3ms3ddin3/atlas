import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'app/atlas_app.dart';
import 'core/editorial/editorial_repository_bootstrap.dart';
import 'core/errors/atlas_error_ui.dart';
import 'core/notifications/prayer_notification_bootstrap.dart';
import 'core/observability/sentry_bootstrap.dart';
import 'core/performance/atlas_performance.dart';
import 'core/supabase/supabase_bootstrap.dart';
import 'core/supabase/supabase_health_repository.dart';
import 'features/admission_temporaire/data/at_bootstrap.dart';

Future<void> main() async {
  await SentryBootstrap.run(() async {
    AtlasPerformance.markStartupBegin();
    WidgetsFlutterBinding.ensureInitialized();
    ErrorWidget.builder = (details) {
      return AtlasErrorFallback(details: details.exceptionAsString());
    };
    EditorialRepositoryBootstrap.registerDefaults();

    final bootstrapResult = await SupabaseBootstrap.initialize();
    if (bootstrapResult.isReady) {
      unawaited(EditorialRepositoryBootstrap.warmUp());
      if (kDebugMode) {
        unawaited(_logBackendHealth());
      }
    }

    runApp(const AtlasApp());

    SchedulerBinding.instance.addPostFrameCallback((_) {
      AtlasPerformance.markFirstFrame();
      unawaited(_bootstrapDeferredNotifications());
    });
  });
}

Future<void> _bootstrapDeferredNotifications() async {
  try {
    await bootstrapPrayerNotifications();
  } catch (error, stack) {
    if (kDebugMode) {
      debugPrint('[Atlas] Prayer bootstrap failed: $error\n$stack');
    }
  }
  try {
    await ensureAtNotificationCoordinator();
  } catch (error, stack) {
    if (kDebugMode) {
      debugPrint('[Atlas] AT bootstrap failed: $error\n$stack');
    }
  }
}

Future<void> _logBackendHealth() async {
  final health = await SupabaseHealthRepository().checkHealth();
  debugPrint(
    '[Atlas] Backend health — ok: ${health.ok}, '
    'latency: ${health.latency?.inMilliseconds}ms, '
    'error: ${health.errorMessage}',
  );
}
