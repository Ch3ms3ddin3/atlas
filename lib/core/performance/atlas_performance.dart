import 'package:flutter/foundation.dart';

/// Instrumentation légère pour la private beta (startup, onglets, HTTP lent).
abstract final class AtlasPerformance {
  static final Stopwatch _startup = Stopwatch();
  static Duration? _startupToFirstFrame;
  static final List<_PerfSample> _tabTransitions = [];
  static final List<_PerfSample> _slowHttp = [];

  static const Duration slowHttpThreshold = Duration(milliseconds: 2000);
  static const int maxSamples = 40;

  static void markStartupBegin() {
    _startup
      ..reset()
      ..start();
  }

  static void markFirstFrame() {
    if (!_startup.isRunning) return;
    _startup.stop();
    _startupToFirstFrame = _startup.elapsed;
    if (kDebugMode) {
      debugPrint(
        '[AtlasPerf] startup→firstFrame: '
        '${_startupToFirstFrame!.inMilliseconds}ms',
      );
    }
  }

  static Duration? get startupToFirstFrame => _startupToFirstFrame;

  static void recordTabTransition({
    required String from,
    required String to,
    required Duration elapsed,
  }) {
    _push(
      _tabTransitions,
      _PerfSample(label: '$from→$to', elapsed: elapsed),
    );
    if (kDebugMode && elapsed.inMilliseconds > 120) {
      debugPrint(
        '[AtlasPerf] slow tab $from→$to: ${elapsed.inMilliseconds}ms',
      );
    }
  }

  static void recordHttp({
    required String url,
    required Duration elapsed,
  }) {
    if (elapsed < slowHttpThreshold) return;
    final host = Uri.tryParse(url)?.host ?? url;
    _push(
      _slowHttp,
      _PerfSample(label: host, elapsed: elapsed),
    );
    if (kDebugMode) {
      debugPrint(
        '[AtlasPerf] slow HTTP $host: ${elapsed.inMilliseconds}ms',
      );
    }
  }

  static List<Map<String, Object?>> tabTransitionSamples() => [
        for (final s in _tabTransitions)
          {'label': s.label, 'ms': s.elapsed.inMilliseconds},
      ];

  static List<Map<String, Object?>> slowHttpSamples() => [
        for (final s in _slowHttp)
          {'label': s.label, 'ms': s.elapsed.inMilliseconds},
      ];

  static Map<String, Object?> snapshot() => {
        'startup_to_first_frame_ms': _startupToFirstFrame?.inMilliseconds,
        'tab_transitions': tabTransitionSamples(),
        'slow_http': slowHttpSamples(),
      };

  @visibleForTesting
  static void resetForTest() {
    _startup.reset();
    _startupToFirstFrame = null;
    _tabTransitions.clear();
    _slowHttp.clear();
  }

  static void _push(List<_PerfSample> list, _PerfSample sample) {
    list.add(sample);
    if (list.length > maxSamples) {
      list.removeRange(0, list.length - maxSamples);
    }
  }
}

class _PerfSample {
  const _PerfSample({required this.label, required this.elapsed});

  final String label;
  final Duration elapsed;
}
