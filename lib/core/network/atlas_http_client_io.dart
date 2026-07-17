import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'atlas_http_timeouts.dart';

/// Implémentation native (Android, iOS, desktop) via dart:io.
Future<String> platformGet(
  String url, {
  Duration timeout = AtlasHttpTimeouts.defaultTimeout,
}) async {
  final client = HttpClient();
  client.connectionTimeout = timeout;
  try {
    final request = await client.getUrl(Uri.parse(url)).timeout(timeout);
    final response = await request.close().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
    }
    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    return body;
  } finally {
    client.close();
  }
}

/// POST JSON streaming — le client reste ouvert jusqu'à la fin du stream.
Stream<String> platformPostJsonStream({
  required String url,
  required Map<String, String> headers,
  required String body,
  Duration timeout = AtlasHttpTimeouts.streamConnectTimeout,
}) async* {
  final client = HttpClient();
  client.connectionTimeout = timeout;
  try {
    final request = await client.postUrl(Uri.parse(url)).timeout(timeout);
    headers.forEach(request.headers.set);
    request.add(utf8.encode(body));
    final response = await request.close().timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorBody = await response.transform(utf8.decoder).join();
      throw HttpException(
        'HTTP ${response.statusCode}: $errorBody',
        uri: Uri.parse(url),
      );
    }
    yield* response.transform(utf8.decoder);
  } finally {
    client.close(force: true);
  }
}
