import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Retours haptiques Atlas — discrets, jamais agressifs.
///
/// No-op sur le web et en cas d'échec plateforme (pas d'exception UI).
abstract final class AtlasHaptics {
  static Future<void> selection() => _safe(HapticFeedback.selectionClick);

  static Future<void> light() => _safe(HapticFeedback.lightImpact);

  static Future<void> primaryAction() => _safe(HapticFeedback.lightImpact);

  static Future<void> _safe(Future<void> Function() feedback) async {
    if (kIsWeb) return;
    try {
      await feedback();
    } catch (_) {
      // Plateforme sans moteur haptique — ignorer.
    }
  }
}
