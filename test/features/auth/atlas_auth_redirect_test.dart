import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/auth/data/atlas_auth_redirect.dart';

void main() {
  test('AtlasAuthRedirect URL matches iOS / Android scheme contract', () {
    expect(AtlasAuthRedirect.scheme, 'io.supabase.atlas');
    expect(AtlasAuthRedirect.host, 'login-callback');
    expect(AtlasAuthRedirect.url, 'io.supabase.atlas://login-callback/');
  });
}
