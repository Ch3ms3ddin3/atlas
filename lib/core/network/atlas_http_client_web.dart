// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
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

/// POST JSON streaming — lit la réponse progressivement quand possible.
Stream<String> platformPostJsonStream({
  required String url,
  required Map<String, String> headers,
  required String body,
}) {
  final controller = StreamController<String>();
  final request = html.HttpRequest();
  var lastLength = 0;

  request.open('POST', url);
  headers.forEach(request.setRequestHeader);
  request.onProgress.listen((_) {
    final text = request.responseText ?? '';
    if (text.length > lastLength) {
      controller.add(text.substring(lastLength));
      lastLength = text.length;
    }
  });
  request.onLoad.listen((_) {
    final text = request.responseText ?? '';
    if (text.length > lastLength) {
      controller.add(text.substring(lastLength));
    }
    if (request.status != null &&
        (request.status! < 200 || request.status! >= 300)) {
      controller.addError(Exception('HTTP ${request.status}: $text'));
    }
    unawaited(controller.close());
  });
  request.onError.listen((_) {
    controller.addError(Exception('HTTP request failed'));
    unawaited(controller.close());
  });
  request.send(body);
  return controller.stream;
}
