import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../auth/domain/auth_repository.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/models/beta_feedback.dart';
import 'beta_preferences_store.dart';
import 'supabase_beta_feedback_repository.dart';

/// Envoi local-first des retours beta (file d'attente hors ligne).
class BetaFeedbackRepository extends ChangeNotifier {
  BetaFeedbackRepository({
    required this._authRepository,
    BetaPreferencesStore? store,
    SupabaseBetaFeedbackRepository? remote,
  })  : _store = store ?? const BetaPreferencesStore(),
        _remote = remote ?? const SupabaseBetaFeedbackRepository();

  final AuthRepository _authRepository;
  final BetaPreferencesStore _store;
  final SupabaseBetaFeedbackRepository _remote;

  List<BetaFeedback> _pending = const [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<BetaFeedback> get pending => List.unmodifiable(_pending);

  Future<void> load() async {
    final raw = await _store.loadPendingFeedbackJson();
    if (raw == null || raw.isEmpty) {
      _pending = const [];
    } else {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _pending = [
          for (final item in list)
            if (item is Map<String, dynamic>) BetaFeedback.fromJson(item),
        ];
      } catch (_) {
        _pending = const [];
      }
    }
    _loaded = true;
    notifyListeners();
    await flushPending();
  }

  Future<bool> submit(BetaFeedback feedback) async {
    final session = _authRepository.session;
    final userId = session.userId;
    if (userId == null || session.kind == AuthSessionKind.unavailable) {
      await _enqueue(feedback);
      return false;
    }

    try {
      await _remote.insert(userId: userId, feedback: feedback);
      return true;
    } catch (_) {
      await _enqueue(feedback);
      return false;
    }
  }

  Future<void> flushPending() async {
    if (_pending.isEmpty) return;
    final session = _authRepository.session;
    final userId = session.userId;
    if (userId == null) return;

    final remaining = <BetaFeedback>[];
    for (final item in _pending) {
      try {
        await _remote.insert(userId: userId, feedback: item);
      } catch (_) {
        remaining.add(item);
      }
    }
    _pending = remaining;
    await _persistPending();
    notifyListeners();
  }

  Future<void> _enqueue(BetaFeedback feedback) async {
    _pending = [..._pending, feedback];
    await _persistPending();
    notifyListeners();
  }

  Future<void> _persistPending() async {
    if (_pending.isEmpty) {
      await _store.savePendingFeedbackJson(null);
      return;
    }
    await _store.savePendingFeedbackJson(
      jsonEncode([for (final item in _pending) item.toJson()]),
    );
  }
}
