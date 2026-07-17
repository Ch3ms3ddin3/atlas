// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'atlas_http_timeouts.dart';

/// Implémentation web via dart:html.
Future<String> platformGet(
  String url, {
  Duration timeout = AtlasHttpTimeouts.defaultTimeout,
}) async {
  final request = await html.HttpRequest.request(
    url,
    method: 'GET',
  ).timeout(timeout);
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
  Duration timeout = AtlasHttpTimeouts.streamConnectTimeout,
}) {
  final controller = StreamController<String>();
  final request = html.HttpRequest();
  var lastLength = 0;
  Timer? connectTimer;

  void fail(Object error) {
    if (!controller.isClosed) {
      controller.addError(error);
      unawaited(controller.close());
    }
  }

  connectTimer = Timer(timeout, () {
    if (request.readyState < 3) {
      request.abort();
      fail(TimeoutException('HTTP connect timeout', timeout));
    }
  });

  request.open('POST', url);
  headers.forEach(request.setRequestHeader);
  request.onProgress.listen((_) {
    connectTimer?.cancel();
    final text = request.responseText ?? '';
    if (text.length > lastLength) {
      controller.add(text.substring(lastLength));
      lastLength = text.length;
    }
  });
  request.onLoad.listen((_) {
    connectTimer?.cancel();
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
    connectTimer?.cancel();
    fail(Exception('HTTP request failed'));
  });
  request.send(body);
  return controller.stream;
}
