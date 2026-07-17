import 'dart:async';

import '../../../core/uuid/atlas_uuid.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/domain/auth_session.dart';
import '../../favorites/domain/favorites_repository.dart';
import '../../admission_temporaire/domain/at_repository.dart';
import '../../profile/domain/profile_repository.dart';
import '../domain/assistant_knowledge_source.dart';
import '../domain/assistant_llm_provider.dart';
import '../domain/assistant_repository.dart';
import '../domain/models/assistant_context_snapshot.dart';
import '../domain/models/assistant_conversation.dart';
import '../domain/models/assistant_message.dart';
import '../domain/models/assistant_stream_event.dart';
import '../domain/models/assistant_suggestion.dart';
import '../domain/models/assistant_token_usage.dart';
import 'assistant_context_builder.dart';
import 'assistant_history_store.dart';
import 'assistant_suggestions_catalog.dart';
import 'assistant_system_prompt.dart';
import 'assistant_token_usage_store.dart';
import 'providers/openai_edge_assistant_provider.dart';

/// Soft caps journaliers (messages utilisateur).
abstract final class AssistantRateLimits {
  static const anonymousDaily = 15;
  static const signedInDaily = 40;
}

/// Implémentation locale-first de l'assistant Atlas.
class LocalAssistantRepository extends AssistantRepository {
  LocalAssistantRepository({
    required ProfileRepository profileRepository,
    required AuthRepository authRepository,
    required FavoritesRepository favoritesRepository,
    required AtRepository atRepository,
    AssistantHistoryStore? historyStore,
    AssistantTokenUsageStore? usageStore,
    AssistantLlmProvider? provider,
    AssistantKnowledgeSource? knowledgeSource,
    AssistantContextBuilder? contextBuilder,
    this._contextProvider,
  })  : _profileRepository = profileRepository,
        _authRepository = authRepository,
        _favoritesRepository = favoritesRepository,
        _atRepository = atRepository,
        _historyStore = historyStore ?? const AssistantHistoryStore(),
        _usageStore = usageStore ?? const AssistantTokenUsageStore(),
        _knowledgeSource =
            knowledgeSource ?? const InMemoryAtlasContextSource(),
        _provider = provider ?? OpenAiEdgeAssistantProvider(),
        _contextBuilder = contextBuilder ??
            AssistantContextBuilder(
              profileRepository: profileRepository,
              authRepository: authRepository,
              favoritesRepository: favoritesRepository,
              atRepository: atRepository,
            );

  final ProfileRepository _profileRepository;
  final AuthRepository _authRepository;
  final FavoritesRepository _favoritesRepository;
  final AtRepository _atRepository;
  final AssistantHistoryStore _historyStore;
  final AssistantTokenUsageStore _usageStore;
  final AssistantLlmProvider _provider;
  final AssistantKnowledgeSource _knowledgeSource;
  final AssistantContextBuilder _contextBuilder;
  final Future<AssistantContextSnapshot> Function()? _contextProvider;

  bool _loaded = false;
  bool _streaming = false;
  bool _offlineFallback = false;
  String? _statusMessage;
  String? _activeId;
  List<AssistantConversation> _conversations = [];
  List<AssistantSuggestion> _suggestions = const [];
  AssistantDailyUsage _dailyUsage = AssistantDailyUsage(
    dayKey: AssistantTokenUsageStore.dayKeyFor(DateTime.now()),
    messageCount: 0,
    usage: const AssistantTokenUsage.zero(),
  );
  StreamSubscription<AssistantStreamEvent>? _streamSub;
  AssistantContextSnapshot? _lastContext;

  @override
  bool get isLoaded => _loaded;

  @override
  bool get isStreaming => _streaming;

  @override
  bool get isOfflineFallback => _offlineFallback;

  @override
  String? get statusMessage => _statusMessage;

  @override
  List<AssistantConversation> get conversations =>
      List.unmodifiable(_conversations);

  @override
  List<AssistantSuggestion> get suggestions => List.unmodifiable(_suggestions);

  @override
  AssistantDailyUsage get dailyUsage => _dailyUsage;

  @override
  AssistantConversation get activeConversation {
    final id = _activeId;
    if (id != null) {
      for (final conversation in _conversations) {
        if (conversation.id == id) return conversation;
      }
    }
    if (_conversations.isNotEmpty) return _conversations.first;
    return AssistantConversation(
      id: 'empty',
      messages: const [],
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  int get dailyMessageLimit {
    final signedIn =
        _authRepository.session.kind == AuthSessionKind.signedIn;
    return signedIn
        ? AssistantRateLimits.signedInDaily
        : AssistantRateLimits.anonymousDaily;
  }

  @override
  int get remainingMessagesToday =>
      (dailyMessageLimit - _dailyUsage.messageCount).clamp(0, dailyMessageLimit);

  @override
  bool get canSendMessage => !_streaming && remainingMessagesToday > 0;

  @override
  Future<void> load() async {
    final loaded = await _historyStore.loadConversations();
    final activeId = await _historyStore.loadActiveId();
    _dailyUsage = await _usageStore.loadToday();
    _conversations = List.of(loaded)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _activeId = activeId;
    if (_activeId == null && _conversations.isNotEmpty) {
      _activeId = _conversations.first.id;
    }
    if (_conversations.isEmpty) {
      await startNewConversation();
    }
    await refreshSuggestions();
    _loaded = true;
    _statusMessage = _provider.isAvailable
        ? null
        : 'Assistant cloud non configuré — suggestions et actions restent disponibles.';
    notifyListeners();
  }

  @override
  Future<void> startNewConversation() async {
    await cancelStreaming();
    final conversation = AssistantConversation(
      id: AtlasUuid.v4(),
      messages: const [],
      updatedAt: DateTime.now().toUtc(),
      title: 'Nouvelle conversation',
    );
    _conversations = [conversation, ..._conversations];
    _activeId = conversation.id;
    _offlineFallback = false;
    await _persist();
    await refreshSuggestions();
    notifyListeners();
  }

  @override
  Future<void> openConversation(String id) async {
    await cancelStreaming();
    if (!_conversations.any((c) => c.id == id)) return;
    _activeId = id;
    _offlineFallback = false;
    await _persist();
    notifyListeners();
  }

  @override
  Future<void> refreshSuggestions() async {
    final profile = _profileRepository.profile;
    _suggestions = AssistantSuggestionsCatalog.forProfile(
      profile: profile,
      vehicleCount: _atRepository.activeVehicles.length,
      favoriteCount: _favoritesRepository.activeFavorites.length,
    );
    notifyListeners();
  }

  @override
  Future<void> refreshContextHints() async {
    try {
      _lastContext = await _resolveContext();
    } catch (_) {
      _lastContext = null;
    }
    await refreshSuggestions();
  }

  @override
  Future<void> cancelStreaming() async {
    await _streamSub?.cancel();
    _streamSub = null;
    if (_streaming) {
      _streaming = false;
      final active = activeConversation;
      final messages = [...active.messages];
      if (messages.isNotEmpty &&
          messages.last.status == AssistantMessageStatus.streaming) {
        messages[messages.length - 1] = messages.last.copyWith(
          status: messages.last.content.trim().isEmpty
              ? AssistantMessageStatus.failed
              : AssistantMessageStatus.complete,
        );
        _replaceActive(active.copyWith(
          messages: messages,
          updatedAt: DateTime.now().toUtc(),
        ));
        await _persist();
      }
      notifyListeners();
    }
  }

  @override
  Future<void> sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _streaming) return;

    if (!canSendMessage) {
      _statusMessage = AssistantSystemPrompt.rateLimitFr;
      notifyListeners();
      return;
    }

    final userMessage = AssistantMessage(
      id: AtlasUuid.v4(),
      role: AssistantMessageRole.user,
      content: trimmed,
      createdAt: DateTime.now().toUtc(),
    );
    final assistantId = AtlasUuid.v4();
    final assistantPlaceholder = AssistantMessage(
      id: assistantId,
      role: AssistantMessageRole.assistant,
      content: '',
      createdAt: DateTime.now().toUtc(),
      status: AssistantMessageStatus.streaming,
    );

    final active = activeConversation;
    final title = active.messages.isEmpty
        ? (trimmed.length > 42 ? '${trimmed.substring(0, 42)}…' : trimmed)
        : active.title;
    _replaceActive(
      active.copyWith(
        title: title,
        messages: [...active.messages, userMessage, assistantPlaceholder],
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    _dailyUsage = _dailyUsage.copyWith(
      messageCount: _dailyUsage.messageCount + 1,
    );
    await _usageStore.save(_dailyUsage);
    await _persist();

    _streaming = true;
    _offlineFallback = false;
    _statusMessage = null;
    notifyListeners();

    AssistantContextSnapshot context;
    try {
      context = _lastContext ?? await _resolveContext();
      _lastContext = context;
    } catch (_) {
      context = AssistantContextSnapshot(
        city: _profileRepository.profile.preferredCity,
        userType: _profileRepository.profile.userType.name,
        language: 'french',
        authKind: _authRepository.session.kind.name,
        isSignedIn:
            _authRepository.session.kind == AuthSessionKind.signedIn,
        firstName: _profileRepository.profile.firstName,
      );
    }

    final historyForProvider = activeConversation.messages
        .where((m) => m.id != assistantId)
        .where((m) =>
            m.role == AssistantMessageRole.user ||
            m.role == AssistantMessageRole.assistant)
        .where((m) => m.status != AssistantMessageStatus.failed)
        .toList();

    if (!_provider.isAvailable) {
      _offlineFallback = true;
      _statusMessage = AssistantSystemPrompt.offlineFallbackFr;
      _streaming = false;
      _patchAssistant(
        assistantId,
        content: AssistantSystemPrompt.offlineFallbackFr,
        status: AssistantMessageStatus.offline,
      );
      await _persist();
      notifyListeners();
      return;
    }

    final snippets = await _knowledgeSource.retrieve(
      query: trimmed,
      context: context,
    );

    final buffer = StringBuffer();
    AssistantTokenUsage? turnUsage;
    var completed = false;

    final completer = Completer<void>();
    _streamSub = _provider
        .streamChat(
          messages: historyForProvider,
          context: context,
          knowledgeSnippets: snippets,
        )
        .listen(
      (event) {
        switch (event) {
          case AssistantStreamDelta(:final text):
            buffer.write(text);
            _patchAssistant(
              assistantId,
              content: buffer.toString(),
              status: AssistantMessageStatus.streaming,
            );
          case AssistantStreamUsage(:final usage):
            turnUsage = usage;
          case AssistantStreamDone():
            completed = true;
          case AssistantStreamError(:final message, :final isOffline):
            _offlineFallback = isOffline;
            _statusMessage = message;
            if (buffer.isEmpty) {
              buffer.write(message);
            }
            completed = true;
        }
      },
      onError: (Object error, StackTrace stack) {
        _offlineFallback = true;
        _statusMessage = AssistantSystemPrompt.offlineFallbackFr;
        if (buffer.isEmpty) {
          buffer.write(AssistantSystemPrompt.offlineFallbackFr);
        }
        completed = true;
        if (!completer.isCompleted) completer.complete();
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );

    await completer.future;
    _streamSub = null;
    _streaming = false;

    final finalContent = buffer.toString().trim().isEmpty
        ? AssistantSystemPrompt.offlineFallbackFr
        : buffer.toString();
    final failed = !completed && finalContent == AssistantSystemPrompt.offlineFallbackFr;
    _patchAssistant(
      assistantId,
      content: finalContent,
      status: (_offlineFallback || failed)
          ? (_offlineFallback
              ? AssistantMessageStatus.offline
              : AssistantMessageStatus.failed)
          : AssistantMessageStatus.complete,
      promptTokens: turnUsage?.promptTokens,
      completionTokens: turnUsage?.completionTokens,
    );

    if (turnUsage != null) {
      _dailyUsage = _dailyUsage.copyWith(
        usage: _dailyUsage.usage + turnUsage!,
      );
      await _usageStore.save(_dailyUsage);
    }
    await _persist();
    notifyListeners();
  }

  Future<AssistantContextSnapshot> _resolveContext() {
    final override = _contextProvider;
    if (override != null) return override();
    return _contextBuilder.build();
  }

  void _patchAssistant(
    String id, {
    required String content,
    required AssistantMessageStatus status,
    int? promptTokens,
    int? completionTokens,
  }) {
    final active = activeConversation;
    final messages = [...active.messages];
    final index = messages.indexWhere((m) => m.id == id);
    if (index < 0) return;
    messages[index] = messages[index].copyWith(
      content: content,
      status: status,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
    );
    _replaceActive(
      active.copyWith(
        messages: messages,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    notifyListeners();
  }

  void _replaceActive(AssistantConversation conversation) {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index < 0) {
      _conversations = [conversation, ..._conversations];
      _activeId = conversation.id;
      return;
    }
    final next = [..._conversations];
    next[index] = conversation;
    next.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _conversations = next;
    _activeId = conversation.id;
  }

  Future<void> _persist() async {
    // Cap history size to keep SharedPreferences light.
    if (_conversations.length > 30) {
      _conversations = _conversations.take(30).toList();
    }
    await _historyStore.save(
      conversations: _conversations,
      activeId: _activeId,
    );
  }

  @override
  void dispose() {
    unawaited(cancelStreaming());
    super.dispose();
  }
}
