import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Observateur de connectivité appareil — pour le bandeau hors-ligne shell.
///
/// Distinct de [CloudSyncPhase.offline] (mode local / sync réservée au compte).
class AtlasConnectivity extends ChangeNotifier {
  AtlasConnectivity({
    Connectivity? connectivity,
    @visibleForTesting bool Function(List<ConnectivityResult> results)?
        interpretResults,
  })  : _connectivity = connectivity ?? Connectivity(),
        _interpretResults = interpretResults ?? isOfflineResults;

  final Connectivity _connectivity;
  final bool Function(List<ConnectivityResult> results) _interpretResults;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOffline = false;
  bool _started = false;

  bool get isOffline => _isOffline;
  bool get isStarted => _started;

  /// `true` quand aucune interface réseau n'est disponible (ex. Airplane Mode).
  static bool isOfflineResults(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return results.every((result) => result == ConnectivityResult.none);
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      final initial = await _connectivity.checkConnectivity();
      _setOffline(_interpretResults(initial));
    } catch (_) {
      // En cas d'échec de lecture, ne pas afficher le bandeau à tort.
      _setOffline(false);
    }

    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) => _setOffline(_interpretResults(results)),
      onError: (_) => _setOffline(false),
    );
  }

  void _setOffline(bool value) {
    if (_isOffline == value) return;
    _isOffline = value;
    notifyListeners();
  }

  /// Force l'état (tests / diagnostics).
  @visibleForTesting
  void debugSetOffline(bool value) => _setOffline(value);

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}
