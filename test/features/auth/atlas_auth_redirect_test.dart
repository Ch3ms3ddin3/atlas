import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/features/auth/data/atlas_auth_redirect.dart';

void main() {
  test('AtlasAuthRedirect URL matches iOS / Android scheme contract', () {
    expect(AtlasAuthRedirect.scheme, 'io.supabase.atlas');
    expect(AtlasAuthRedirect.host, 'login-callback');
    expect(AtlasAuthRedirect.url, 'io.supabase.atlas://login-callback');
    expect(
      AtlasAuthRedirect.url.endsWith('/'),
      isFalse,
      reason: 'Canonical redirect must match Supabase Flutter docs (no trailing slash)',
    );
    expect(
      AtlasAuthRedirect.allowedRedirectUrls,
      containsAll([
        'io.supabase.atlas://login-callback',
        'io.supabase.atlas://login-callback/',
      ]),
    );
  });
}
