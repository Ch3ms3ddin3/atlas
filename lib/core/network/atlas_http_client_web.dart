// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

/// Implémentation web via dart:html.
Future<String> platformGet(String url) async {
  final request = await html.HttpRequest.request(
    url,
    method: 'GET',
  );
  if (request.status != 200) {
    throw Exception('HTTP ${request.status}');
  }
  return request.responseText ?? '';
}
