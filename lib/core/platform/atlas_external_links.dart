import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouverture de liens externes (téléphone, e-mail, web, cartes).
///
/// Injectable pour les tests — [openForTest] remplace l'implémentation réelle.
abstract final class AtlasExternalLinks {
  static Future<bool> Function(Uri uri) _open = _launch;

  /// Ouvre [uri] via le gestionnaire système.
  static Future<bool> open(Uri uri) => _open(uri);

  @visibleForTesting
  static void openForTest(Future<bool> Function(Uri uri) opener) {
    _open = opener;
  }

  @visibleForTesting
  static void resetForTest() {
    _open = _launch;
  }

  static Future<bool> _launch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  static Uri? mapsUri({required double latitude, required double longitude}) {
    return Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${Uri.encodeComponent('$latitude,$longitude')}',
    );
  }

  static Uri? phoneUri(String phone) {
    final cleaned = phone.trim();
    if (cleaned.isEmpty) return null;
    return Uri(scheme: 'tel', path: cleaned);
  }

  static Uri? emailUri(String email) {
    final cleaned = email.trim();
    if (cleaned.isEmpty) return null;
    return Uri(scheme: 'mailto', path: cleaned);
  }

  static Uri? websiteUri(String website) {
    final cleaned = website.trim();
    if (cleaned.isEmpty) return null;
    final withScheme = cleaned.contains('://') ? cleaned : 'https://$cleaned';
    return Uri.tryParse(withScheme);
  }
}
