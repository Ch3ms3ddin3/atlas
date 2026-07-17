import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atlas/design_system/theme/atlas_theme.dart';
import 'package:atlas/features/admission_temporaire/data/local_at_repository.dart';
import 'package:atlas/features/assistant/data/local_assistant_repository.dart';
import 'package:atlas/features/assistant/data/providers/mock_assistant_provider.dart';
import 'package:atlas/features/assistant/domain/models/assistant_context_snapshot.dart';
import 'package:atlas/features/assistant/presentation/assistant_scope.dart';
import 'package:atlas/features/assistant/presentation/pages/assistant_page.dart';
import 'package:atlas/features/auth/domain/auth_action_result.dart';
import 'package:atlas/features/auth/domain/auth_repository.dart';
import 'package:atlas/features/auth/domain/auth_session.dart';
import 'package:atlas/features/favorites/data/local_favorites_repository.dart';
import 'package:atlas/features/profile/data/local_profile_repository.dart';
import 'package:atlas/features/profile/presentation/profile_scope.dart';
import 'package:atlas/features/shell/presentation/shell_navigation_scope.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AssistantPage affiche suggestions, actions et stream une réponse',
      (tester) async {
    final profile = LocalProfileRepository();
    await profile.load();
    final favorites = LocalFavoritesRepository();
    await favorites.load();
    final at = LocalAtRepository();
    await at.load();
    final auth = _UiAuthRepository();
    final assistant = LocalAssistantRepository(
      profileRepository: profile,
      authRepository: auth,
      favoritesRepository: favorites,
      atRepository: at,
      provider: MockAssistantProvider(
        chunkDelay: Duration.zero,
        replyBuilder: (messages, context) => 'Conseil Atlas prêt.',
      ),
      contextProvider: () async => const AssistantContextSnapshot(
        city: 'Marrakech',
        userType: 'resident',
        language: 'french',
        authKind: 'anonymous',
        isSignedIn: false,
      ),
    );
    await assistant.load();

    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light,
        home: ProfileScope(
          repository: profile,
          child: AssistantScope(
            repository: assistant,
            child: ShellNavigationScope(
              navigateToTab: (_) {},
              child: const AssistantPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assistant Atlas'), findsWidgets);
    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.text('Actions Atlas'), findsOneWidget);
    expect(find.text('Explorer'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Que faire aujourd\'hui ?');
    await tester.tap(find.byTooltip('Envoyer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Conseil Atlas prêt.'), findsOneWidget);
    expect(find.textContaining('tokens aujourd'), findsOneWidget);
  });
}

class _UiAuthRepository extends AuthRepository {
  _UiAuthRepository() : super.base();

  @override
  AuthSession get session => const AuthSession(
        kind: AuthSessionKind.anonymous,
        userId: 'anon-ui',
      );

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
