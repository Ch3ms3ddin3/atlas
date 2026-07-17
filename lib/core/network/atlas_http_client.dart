import 'atlas_http_client_io.dart'
    if (dart.library.html) 'atlas_http_client_web.dart';
import 'atlas_http_timeouts.dart';

export 'atlas_http_timeouts.dart';

/// Client HTTP minimal, compatible web / Android / iOS.
abstract final class AtlasHttpClient {
  /// Effectue un GET et renvoie le corps de la réponse.
  /// Lance une exception si la requête échoue.
  static Future<String> get(
    String url, {
    Duration timeout = AtlasHttpTimeouts.defaultTimeout,
  }) =>
      platformGet(url, timeout: timeout);

  /// POST JSON et expose le corps en flux de chunks UTF-8 (streaming SSE/NDJSON).
  static Stream<String> postJsonStream({
    required String url,
    required Map<String, String> headers,
    required String body,
    Duration timeout = AtlasHttpTimeouts.streamConnectTimeout,
  }) =>
      platformPostJsonStream(
        url: url,
        headers: headers,
        body: body,
        timeout: timeout,
      );
}
