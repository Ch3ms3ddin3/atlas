import 'package:flutter/foundation.dart';

import 'models/assistant_conversation.dart';
import 'models/assistant_suggestion.dart';
import 'models/assistant_token_usage.dart';

/// Contrat du dépôt Assistant — historique local + streaming.
abstract class AssistantRepository extends ChangeNotifier {
  bool get isLoaded;
  bool get isStreaming;
  bool get isOfflineFallback;
  String? get statusMessage;

  AssistantConversation get activeConversation;
  List<AssistantConversation> get conversations;
  List<AssistantSuggestion> get suggestions;
  AssistantDailyUsage get dailyUsage;

  /// Soft cap journalier selon le mode auth.
  int get dailyMessageLimit;
  int get remainingMessagesToday;
  bool get canSendMessage;

  Future<void> load();

  Future<void> startNewConversation();

  Future<void> openConversation(String id);

  /// Envoie un message utilisateur et stream la réponse.
  Future<void> sendUserMessage(String text);

  Future<void> cancelStreaming();

  Future<void> refreshSuggestions();

  Future<void> refreshContextHints();
}
