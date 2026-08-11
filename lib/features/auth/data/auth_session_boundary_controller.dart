import '../domain/auth_session.dart';
import 'local_user_data_isolator.dart';

/// Serializes auth identity transitions and always applies the latest session.
///
/// Concurrent session notifications are coalesced into a replay of the current
/// session instead of being dropped (previous `_authBoundaryInProgress` return).
class AuthSessionBoundaryController {
  AuthSessionBoundaryController({
    required this._sessionProvider,
    required this._reloadUserScopedData,
    Future<BoundLocalIdentity> Function()? loadBoundIdentity,
    Future<void> Function({
      required AuthSessionKind kind,
      required String? userId,
    })? saveBoundIdentity,
    Future<void> Function()? clearPersistedUserData,
    bool Function({
      required AuthSessionKind? previousKind,
      required String? previousUserId,
      required AuthSessionKind nextKind,
      required String? nextUserId,
    })? shouldClearLocal,
  })  : _loadBoundIdentity =
            loadBoundIdentity ?? LocalUserDataIsolator.loadBoundIdentity,
        _saveBoundIdentity =
            saveBoundIdentity ?? LocalUserDataIsolator.saveBoundIdentity,
        _clearPersistedUserData =
            clearPersistedUserData ?? LocalUserDataIsolator.clearPersistedUserData,
        _shouldClearLocal =
            shouldClearLocal ?? LocalUserDataIsolator.shouldClearLocal;

  final AuthSession Function() _sessionProvider;
  final Future<void> Function() _reloadUserScopedData;
  final Future<BoundLocalIdentity> Function() _loadBoundIdentity;
  final Future<void> Function({
    required AuthSessionKind kind,
    required String? userId,
  }) _saveBoundIdentity;
  final Future<void> Function() _clearPersistedUserData;
  final bool Function({
    required AuthSessionKind? previousKind,
    required String? previousUserId,
    required AuthSessionKind nextKind,
    required String? nextUserId,
  }) _shouldClearLocal;

  AuthSessionKind? _boundAuthKind;
  String? _boundUserId;
  bool _inProgress = false;
  bool _replayPending = false;

  /// Last identity applied by this controller (in-memory).
  AuthSessionKind? get boundAuthKind => _boundAuthKind;
  String? get boundUserId => _boundUserId;

  /// True while a clear/reload cycle is running.
  bool get isInProgress => _inProgress;

  /// True when at least one session change arrived during the current cycle.
  bool get isReplayPending => _replayPending;

  /// Entry point for [AuthRepository] listeners — never drops the latest session.
  Future<void> handleSessionChanged() async {
    _replayPending = true;
    if (_inProgress) return;
    _inProgress = true;
    try {
      while (_replayPending) {
        _replayPending = false;
        await _applyBoundary(_sessionProvider());
      }
    } finally {
      _inProgress = false;
      if (_replayPending) {
        // A notify landed between the while-exit and finally — drain again.
        await handleSessionChanged();
      }
    }
  }

  Future<void> _applyBoundary(AuthSession session) async {
    final persisted = await _loadBoundIdentity();
    final previousKind = _boundAuthKind ?? persisted.kind;
    final previousUserId = _boundUserId ?? persisted.userId;

    final shouldClear = _shouldClearLocal(
      previousKind: previousKind,
      previousUserId: previousUserId,
      nextKind: session.kind,
      nextUserId: session.userId,
    );

    if (shouldClear) {
      await _clearPersistedUserData();
    }

    _boundAuthKind = session.kind;
    _boundUserId = session.userId;
    await _saveBoundIdentity(
      kind: session.kind,
      userId: session.userId,
    );

    await _reloadUserScopedData();
  }
}
