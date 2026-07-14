import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/atlas_app.dart';
import 'core/editorial/editorial_repository_bootstrap.dart';
import 'core/notifications/prayer_notification_bootstrap.dart';
import 'core/supabase/supabase_bootstrap.dart';
import 'core/supabase/supabase_health_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EditorialRepositoryBootstrap.registerDefaults();
  await bootstrapPrayerNotifications();

  final bootstrapResult = await SupabaseBootstrap.initialize();
  if (bootstrapResult.isReady) {
    unawaited(EditorialRepositoryBootstrap.warmUp());
    if (kDebugMode) {
      final health = await SupabaseHealthRepository().checkHealth();
      debugPrint(
        '[Atlas] Backend health — ok: ${health.ok}, '
        'latency: ${health.latency?.inMilliseconds}ms, '
        'error: ${health.errorMessage}',
      );
    }
  }

  runApp(const AtlasApp());
}
