import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Implémentation native (Android, iOS, desktop) via dart:io.
Future<String> platformGet(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
    }
    final body = await response.transform(utf8.decoder).join();
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
}) async* {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(url));
    headers.forEach(request.headers.set);
    request.add(utf8.encode(body));
    final response = await request.close();
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
