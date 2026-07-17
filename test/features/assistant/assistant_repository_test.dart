import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/features/admission_temporaire/data/local_at_repository.dart';
import 'package:atlas/features/assistant/data/assistant_suggestions_catalog.dart';
import 'package:atlas/features/assistant/data/assistant_system_prompt.dart';
import 'package:atlas/features/assistant/data/local_assistant_repository.dart';
import 'package:atlas/features/assistant/data/providers/mock_assistant_provider.dart';
import 'package:atlas/features/assistant/domain/assistant_knowledge_source.dart';
import 'package:atlas/features/assistant/domain/assistant_llm_provider.dart';
import 'package:atlas/features/assistant/domain/models/assistant_context_snapshot.dart';
import 'package:atlas/features/assistant/domain/models/assistant_message.dart';
import 'package:atlas/features/assistant/domain/models/assistant_stream_event.dart';
import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/domain/models/user_profile.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AssistantSuggestionsCatalog', () {
    test('adapte les suggestions au profil et au contexte', () {
      final tourist = AssistantSuggestionsCatalog.forProfile(
        profile: UserProfile.defaults.copyWith(
          preferredCity: 'Casablanca',
          userType: AtlasUserType.tourist,
        ),
      );
      expect(tourist, isNotEmpty);
      expect(tourist.any((s) => s.label.contains('Casablanca')), isTrue);
      expect(tourist.any((s) => s.id == 'tourist-tips'), isTrue);

      final withAt = AssistantSuggestionsCatalog.forProfile(
        profile: UserProfile.defaults,
        vehicleCount: 2,
        favoriteCount: 1,
      );
      expect(withAt.any((s) => s.id == 'at-vehicles'), isTrue);
      expect(withAt.any((s) => s.id == 'favorites'), isTrue);
      expect(withAt.length, lessThanOrEqualTo(6));
    });
  });

  group('InMemoryAtlasContextSource', () {
    test('expose le snapshot comme snippet RAG-ready', () async {
      const source = InMemoryAtlasContextSource();
      const context = AssistantContextSnapshot(
        city: 'Rabat',
        userType: 'mre',
        language: 'french',
        authKind: 'signedIn',
        isSignedIn: true,
        weatherSummary: '22°C, clair',
      );
      final snippets = await source.retrieve(
        query: 'météo',
        context: context,
      );
      expect(snippets, hasLength(1));
      expect(snippets.first.content, contains('Rabat'));
      expect(snippets.first.source, 'atlas_context_snapshot');
    });
  });

  group('MockAssistantProvider', () {
    test('stream des deltas puis usage', () async {
      final provider = MockAssistantProvider(
        chunkDelay: Duration.zero,
        replyBuilder: (messages, context) => 'Bonjour Atlas',
      );
      final events = await provider
          .streamChat(
            messages: [
              AssistantMessage(
                id: 'u1',
                role: AssistantMessageRole.user,
                content: 'Salut',
                createdAt: DateTime.utc(2026, 7, 17),
              ),
            ],
            context: const AssistantContextSnapshot(
              city: 'Marrakech',
              userType: 'resident',
              language: 'french',
              authKind: 'anonymous',
              isSignedIn: false,
            ),
          )
          .toList();

      final deltas = events.whereType<AssistantStreamDelta>();
      expect(deltas.map((e) => e.text).join(), 'Bonjour Atlas');
      expect(events.whereType<AssistantStreamUsage>(), isNotEmpty);
      expect(events.whereType<AssistantStreamDone>(), isNotEmpty);
    });
  });

  group('LocalAssistantRepository', () {
    Future<LocalAssistantRepository> buildRepo({
      AuthSessionKind kind = AuthSessionKind.anonymous,
      AssistantLlmProvider? provider,
    }) async {
      final profile = LocalProfileRepository();
      await profile.load();
      await profile.save(
        UserProfile.defaults.copyWith(preferredCity: 'Fès'),
      );
      final auth = _TestAuthRepository(
        session: AuthSession(
          kind: kind,
          userId: kind == AuthSessionKind.signedIn ? 'user-1' : 'anon-1',
        ),
      );
      final favorites = LocalFavoritesRepository();
      await favorites.load();
      final at = LocalAtRepository();
      await at.load();

      final repository = LocalAssistantRepository(
        profileRepository: profile,
        authRepository: auth,
        favoritesRepository: favorites,
        atRepository: at,
        provider: provider ??
            MockAssistantProvider(
              chunkDelay: Duration.zero,
              replyBuilder: (messages, context) => 'Réponse mock contextualisée.',
            ),
        knowledgeSource: const EmptyKnowledgeSource(),
        contextProvider: () async => AssistantContextSnapshot(
          city: profile.profile.preferredCity,
          userType: profile.profile.userType.name,
          language: 'french',
          authKind: auth.session.kind.name,
          isSignedIn: auth.session.kind == AuthSessionKind.signedIn,
          firstName: profile.profile.firstName,
          weatherSummary: '24°C, ensoleillé',
        ),
      );
      await repository.load();
      return repository;
    }

    test('historique local + streaming + tokens', () async {
      final repository = await buildRepo();
      expect(repository.activeConversation.messages, isEmpty);
      expect(repository.suggestions, isNotEmpty);

      await repository.sendUserMessage('Quel temps à Fès ?');
      expect(repository.isStreaming, isFalse);
      expect(repository.activeConversation.messages, hasLength(2));
      expect(
        repository.activeConversation.messages.first.role,
        AssistantMessageRole.user,
      );
      expect(
        repository.activeConversation.messages.last.content,
        contains('Réponse mock'),
      );
      expect(repository.dailyUsage.messageCount, 1);
      expect(repository.dailyUsage.usage.totalTokens, greaterThan(0));

      await repository.startNewConversation();
      expect(repository.conversations.length, greaterThanOrEqualTo(2));
      expect(repository.activeConversation.messages, isEmpty);
    });

    test('soft cap anonyme vs authentifié', () async {
      final anon = await buildRepo();
      expect(anon.dailyMessageLimit, AssistantRateLimits.anonymousDaily);

      final signed = await buildRepo(kind: AuthSessionKind.signedIn);
      expect(signed.dailyMessageLimit, AssistantRateLimits.signedInDaily);
    });

    test('fallback offline quand le provider est indisponible', () async {
      final repository = await buildRepo(
        provider: _UnavailableProvider(),
      );
      await repository.sendUserMessage('Hello');
      expect(repository.isOfflineFallback, isTrue);
      expect(
        repository.activeConversation.messages.last.content,
        AssistantSystemPrompt.offlineFallbackFr,
      );
      expect(
        repository.activeConversation.messages.last.status,
        AssistantMessageStatus.offline,
      );
    });
  });
}

class _TestAuthRepository extends AuthRepository {
  _TestAuthRepository({required this.session}) : super.base();

  @override
  final AuthSession session;

  @override
  bool get isLoaded => true;

  @override
  Future<void> load() async {}

  @override
  Future<AuthActionResult> signUp({
    required String email,
    required String password,
  }) async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> signIn({
    required String email,
    required String password,
  }) async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> signInWithApple() async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> signInWithGoogle() async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> resetPassword({required String email}) async =>
      AuthActionResult.success();

  @override
  Future<AuthActionResult> signOut() async => AuthActionResult.success();

  @override
  Future<AuthActionResult> deleteAccount() async =>
      AuthActionResult.success();
}

class _UnavailableProvider implements AssistantLlmProvider {
  @override
  AssistantProviderKind get kind => AssistantProviderKind.openAi;

  @override
  String get displayName => 'Unavailable';

  @override
  AssistantProviderCapabilities get capabilities =>
      const AssistantProviderCapabilities();

  @override
  bool get isAvailable => false;

  @override
  Stream<AssistantStreamEvent> streamChat({
    required List<AssistantMessage> messages,
    required AssistantContextSnapshot context,
    List<AssistantKnowledgeSnippet> knowledgeSnippets = const [],
  }) async* {
    yield const AssistantStreamError('should not be called', isOffline: true);
  }
}
