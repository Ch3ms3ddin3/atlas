import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/core/uuid/atlas_uuid.dart';

void main() {
  test('AtlasUuid.v4 génère un identifiant au format UUID v4', () {
    final id = AtlasUuid.v4();
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    expect(pattern.hasMatch(id), isTrue);
    expect(AtlasUuid.v4(), isNot(equals(id)));
  });
}
