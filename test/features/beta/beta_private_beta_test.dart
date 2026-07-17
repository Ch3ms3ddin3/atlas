import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/performance/atlas_performance.dart';
import 'package:atlas/features/beta/domain/changelog_entry.dart';
import 'package:atlas/features/beta/domain/models/beta_feedback.dart';

void main() {
  group('ChangelogCatalog', () {
    test('sinceBuild renvoie les builds plus récents', () {
      final entries = ChangelogCatalog.sinceBuild(1);
      expect(entries, isNotEmpty);
      expect(entries.every((e) => e.buildNumber > 1), isTrue);
    });

    test('latestForBuild trouve le build 2', () {
      final entry = ChangelogCatalog.latestForBuild(2);
      expect(entry, isNotNull);
      expect(entry!.title, contains('Private Beta'));
    });
  });

  group('BetaFeedback', () {
    test('create trimme le message et génère un id', () {
      final feedback = BetaFeedback.create(
        screenName: 'home',
        message: '  bug carte  ',
        appVersion: '1.0.0',
        buildNumber: '2',
        platform: 'ios',
      );
      expect(feedback.message, 'bug carte');
      expect(feedback.id, isNotEmpty);
      expect(feedback.toJson()['screen_name'], 'home');
    });
  });

  group('AtlasPerformance', () {
    setUp(AtlasPerformance.resetForTest);

    test('enregistre les transitions et HTTP lents', () {
      AtlasPerformance.recordTabTransition(
        from: 'home',
        to: 'map',
        elapsed: const Duration(milliseconds: 80),
      );
      AtlasPerformance.recordHttp(
        url: 'https://api.example.com/x',
        elapsed: const Duration(milliseconds: 2500),
      );
      final snap = AtlasPerformance.snapshot();
      expect(snap['tab_transitions'], isA<List>());
      expect((snap['slow_http'] as List), isNotEmpty);
    });
  });
}
