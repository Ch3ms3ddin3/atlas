import 'models/assistant_context_snapshot.dart';
import 'models/assistant_message.dart';
import 'models/assistant_stream_event.dart';
import 'assistant_knowledge_source.dart';

/// Fournisseur LLM — OpenAI d'abord, extensible ensuite.
enum AssistantProviderKind { openAi, mock }

class AssistantProviderCapabilities {
  const AssistantProviderCapabilities({
    this.supportsStreaming = true,
    this.supportsTools = false,
    this.supportsRagSnippets = true,
  });

  final bool supportsStreaming;
  final bool supportsTools;
  final bool supportsRagSnippets;
}

/// Abstraction provider — l'UI ne dépend jamais d'un SDK LLM.
abstract class AssistantLlmProvider {
  AssistantProviderKind get kind;
  String get displayName;
  AssistantProviderCapabilities get capabilities;

  /// Indique si le provider peut tenter un appel réseau.
  bool get isAvailable;

  Stream<AssistantStreamEvent> streamChat({
    required List<AssistantMessage> messages,
    required AssistantContextSnapshot context,
    List<AssistantKnowledgeSnippet> knowledgeSnippets = const [],
  });
}
