import 'package:flutter/foundation.dart';

import 'editorial_catalog_load_state.dart';
import 'editorial_local_catalog.dart';
import 'editorial_remote_catalog.dart';

/// Cache résilient distant-d'abord avec repli local permanent.
///
/// Motif partagé pour les catalogues places / procédures / prix :
/// 1. avant `warmUp`, [items] sert le local (`idle`) ;
/// 2. `warmUp` passe en `loading` puis tente le distant (timeout) ;
/// 3. succès non vide → cache distant (`success`) ;
/// 4. distant vide → local inchangé (`stale`) ;
/// 5. échec / timeout → local inchangé (`error`).
class ResilientEditorialCatalog<T> extends ChangeNotifier {
  ResilientEditorialCatalog({
    required List<T> localItems,
    required this._fetchRemote,
    Duration? fetchTimeout,
  })  : _localItems = List<T>.unmodifiable(localItems),
        _fetchTimeout = fetchTimeout ?? const Duration(seconds: 5);

  /// Construit depuis les contrats locaux / distants partagés.
  factory ResilientEditorialCatalog.fromSources({
    required EditorialLocalCatalog<T> local,
    required EditorialRemoteCatalog<T> remote,
    Duration? fetchTimeout,
  }) {
    return ResilientEditorialCatalog<T>(
      localItems: local.items,
      fetchRemote: remote.fetchAll,
      fetchTimeout: fetchTimeout,
    );
  }

  final List<T> _localItems;
  final Future<List<T>> Function() _fetchRemote;
  final Duration _fetchTimeout;

  List<T>? _remoteCache;
  EditorialCatalogLoadState _loadState = EditorialCatalogLoadState.idle;
  Object? _lastError;
  bool _warmUpStarted = false;

  /// État courant du préchargement.
  EditorialCatalogLoadState get loadState => _loadState;

  /// Dernière erreur de fetch distant, si [loadState] est [EditorialCatalogLoadState.error].
  Object? get lastError => _lastError;

  /// `true` lorsque le cache distant est actif.
  bool get isUsingRemote => _remoteCache != null;

  /// Source effective : distant si disponible, sinon local.
  List<T> get items => _remoteCache ?? _localItems;

  /// Précharge le distant une seule fois. Les écouteurs sont notifiés
  /// à chaque changement d'état (et donc au passage local → distant).
  Future<void> warmUp() async {
    if (_warmUpStarted) return;
    _warmUpStarted = true;
    _lastError = null;
    _setLoadState(EditorialCatalogLoadState.loading);

    try {
      final remoteItems = await _fetchRemote().timeout(_fetchTimeout);
      if (remoteItems.isNotEmpty) {
        _remoteCache = List<T>.unmodifiable(remoteItems);
        _setLoadState(EditorialCatalogLoadState.success);
        return;
      }
      _setLoadState(EditorialCatalogLoadState.stale);
    } catch (error) {
      _lastError = error;
      // Repli silencieux sur le catalogue local.
      _setLoadState(EditorialCatalogLoadState.error);
    }
  }

  void _setLoadState(EditorialCatalogLoadState next) {
    if (_loadState == next) return;
    _loadState = next;
    notifyListeners();
  }
}
