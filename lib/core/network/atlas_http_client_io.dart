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
