import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/models/beta_feedback.dart';

/// Insertion Supabase des retours beta.
class SupabaseBetaFeedbackRepository {
  const SupabaseBetaFeedbackRepository({
    SupabaseClient? Function()? clientProvider,
  }) : _clientProvider = clientProvider ?? SupabaseBootstrap.clientOrNull;

  final SupabaseClient? Function()? _clientProvider;

  Future<void> insert({
    required String userId,
    required BetaFeedback feedback,
  }) async {
    final client = _clientProvider?.call();
    if (client == null) {
      throw StateError('Client Supabase non initialisé.');
    }

    await client.from('beta_feedback').insert({
      'id': feedback.id,
      'user_id': userId,
      'screen_name': feedback.screenName,
      'message': feedback.message,
      'app_version': feedback.appVersion,
      'build_number': feedback.buildNumber,
      'platform': feedback.platform,
      'include_screenshot': feedback.includeScreenshot,
      if (feedback.screenshotBase64 != null)
        'screenshot_base64': feedback.screenshotBase64,
      'status': 'pending',
    });
  }
}
