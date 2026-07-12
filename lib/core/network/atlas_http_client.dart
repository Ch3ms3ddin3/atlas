import 'atlas_http_client_io.dart'
    if (dart.library.html) 'atlas_http_client_web.dart';

/// Client HTTP minimal, compatible web / Android / iOS.
abstract final class AtlasHttpClient {
  /// Effectue un GET et renvoie le corps de la réponse.
  /// Lance une exception si la requête échoue.
  static Future<String> get(String url) => platformGet(url);
}
