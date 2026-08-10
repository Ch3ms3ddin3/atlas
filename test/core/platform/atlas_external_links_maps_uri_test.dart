import 'package:atlas/core/platform/atlas_external_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AtlasExternalLinks.mapsUri', () {
    test('uses exact lat/lng only (reliable Google Maps iOS destination)', () {
      const lat = 31.617286;
      const lng = -7.990510;
      final uri = AtlasExternalLinks.mapsUri(
        latitude: lat,
        longitude: lng,
      )!;

      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/search/');
      expect(uri.queryParameters['api'], '1');
      expect(uri.queryParameters['query'], '$lat,$lng');
      expect(uri.queryParameters['query'], isNot(contains('(')));
      expect(uri.toString(), contains(Uri.encodeComponent('$lat,$lng')));
    });

    test('does not embed place name in query (avoids text-search miss)', () {
      final uri = AtlasExternalLinks.mapsUri(
        latitude: 31.628455,
        longitude: -7.987441,
      )!;
      final query = uri.queryParameters['query']!;
      expect(query, '31.628455,-7.987441');
      expect(query, isNot(contains('Épices')));
      expect(query, isNot(contains('Hammam')));
    });
  });
}
